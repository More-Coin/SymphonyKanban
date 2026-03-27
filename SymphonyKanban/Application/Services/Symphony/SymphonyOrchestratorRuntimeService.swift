import Foundation

public actor SymphonyOrchestratorRuntimeService {
    public typealias RuntimeState = SymphonyRuntimeStateContract<String, String, String>

    private let dispatchPreflightValidationService: SymphonyDispatchPreflightValidationService
    private let fetchIssuesUseCase: FetchSymphonyIssuesUseCase
    private let cleanupWorkspaceUseCase: CleanupSymphonyWorkspaceUseCase
    private let selectDispatchIssuesUseCase: SelectSymphonyDispatchIssuesUseCase
    private let stopRuntimeUseCase: StopSymphonyOrchestratorRuntimeUseCase
    private let projectRuntimeStatusSnapshotUseCase: ProjectSymphonyRuntimeStatusSnapshotUseCase?
    private let runtimeStateTransition: SymphonyRuntimeStateTransition
    private let eligibilityPolicy: any SymphonyIssueDispatchEligibilityPolicyProtocol
    private let workerExecutionPort: any SymphonyWorkerExecutionPortProtocol
    private let retryBackoffPolicy: any SymphonyRetryBackoffPolicyProtocol
    private let schedulerPort: any SymphonyRuntimeSchedulerPortProtocol
    private let clockPort: any SymphonyRuntimeClockPortProtocol
    private let logSinkPort: any SymphonyOrchestratorLogSinkPortProtocol
    private let runtimeStatusSinkPort: (any SymphonyRuntimeStatusSinkPortProtocol)?
    private let workflowReloadMonitorPort: (any SymphonyWorkflowReloadMonitorPortProtocol)?

    private var startupCommand: SymphonyStartupCommandContract?
    private var workflowConfiguration: SymphonyWorkflowConfigurationResultContract?
    private var lastKnownGoodWorkflowConfiguration: SymphonyWorkflowConfigurationResultContract?
    private var state: RuntimeState = SymphonyRuntimeStateContract(
        pollIntervalMs: 0,
        maxConcurrentAgents: 0,
        running: [:],
        claimed: [],
        retryAttempts: [:],
        completed: [],
        codexTotals: .init(
            inputTokens: 0,
            outputTokens: 0,
            totalTokens: 0,
            secondsRunning: 0
        ),
        codexRateLimits: nil
    )
    private var pollHandle: String?
    private var workflowReloadHandle: SymphonyWorkflowReloadHandleContract?
    private var started = false
    private var tickInFlight = false

    public init(
        dispatchPreflightValidationService: SymphonyDispatchPreflightValidationService,
        fetchIssuesUseCase: FetchSymphonyIssuesUseCase,
        cleanupWorkspaceUseCase: CleanupSymphonyWorkspaceUseCase,
        selectDispatchIssuesUseCase: SelectSymphonyDispatchIssuesUseCase = .init(),
        stopRuntimeUseCase: StopSymphonyOrchestratorRuntimeUseCase? = nil,
        projectRuntimeStatusSnapshotUseCase: ProjectSymphonyRuntimeStatusSnapshotUseCase? = nil,
        runtimeStateTransition: SymphonyRuntimeStateTransition = .init(),
        eligibilityPolicy: any SymphonyIssueDispatchEligibilityPolicyProtocol = SymphonyIssueDispatchEligibilityPolicy(),
        workerExecutionPort: any SymphonyWorkerExecutionPortProtocol,
        retryBackoffPolicy: any SymphonyRetryBackoffPolicyProtocol = SymphonyRetryBackoffPolicy(),
        schedulerPort: any SymphonyRuntimeSchedulerPortProtocol,
        clockPort: any SymphonyRuntimeClockPortProtocol,
        logSinkPort: any SymphonyOrchestratorLogSinkPortProtocol,
        runtimeStatusSinkPort: (any SymphonyRuntimeStatusSinkPortProtocol)? = nil,
        runtimeStatusProjectorPort: (any SymphonyRuntimeStatusProjectorPortProtocol)? = nil,
        workflowReloadMonitorPort: (any SymphonyWorkflowReloadMonitorPortProtocol)? = nil
    ) {
        self.dispatchPreflightValidationService = dispatchPreflightValidationService
        self.fetchIssuesUseCase = fetchIssuesUseCase
        self.cleanupWorkspaceUseCase = cleanupWorkspaceUseCase
        self.selectDispatchIssuesUseCase = selectDispatchIssuesUseCase
        self.eligibilityPolicy = eligibilityPolicy
        self.workerExecutionPort = workerExecutionPort
        self.retryBackoffPolicy = retryBackoffPolicy
        self.schedulerPort = schedulerPort
        self.clockPort = clockPort
        self.logSinkPort = logSinkPort
        self.runtimeStatusSinkPort = runtimeStatusSinkPort
        self.workflowReloadMonitorPort = workflowReloadMonitorPort
        self.runtimeStateTransition = runtimeStateTransition
        self.stopRuntimeUseCase = stopRuntimeUseCase ?? StopSymphonyOrchestratorRuntimeUseCase(
            schedulerPort: schedulerPort,
            workerExecutionPort: workerExecutionPort,
            workflowReloadMonitorPort: workflowReloadMonitorPort
        )
        if let projectRuntimeStatusSnapshotUseCase {
            self.projectRuntimeStatusSnapshotUseCase = projectRuntimeStatusSnapshotUseCase
        } else {
            self.projectRuntimeStatusSnapshotUseCase = runtimeStatusProjectorPort.map {
                ProjectSymphonyRuntimeStatusSnapshotUseCase(
                    clockPort: clockPort,
                    runtimeStatusProjectorPort: $0
                )
            }
        }
    }

    public func start(
        command: SymphonyStartupCommandContract,
        initialConfiguration: SymphonyWorkflowConfigurationResultContract
    ) async {
        guard !started else {
            return
        }

        started = true
        startupCommand = command
        workflowConfiguration = initialConfiguration
        lastKnownGoodWorkflowConfiguration = initialConfiguration
        state = Self.emptyState(using: initialConfiguration.serviceConfig)
        startWorkflowReloadMonitoring(path: initialConfiguration.workflowDefinition.resolvedPath)

        await performStartupTerminalWorkspaceCleanup(using: initialConfiguration)
        emitRuntimeStatusSnapshot(outcome: "startup_ready")
        schedulePollTick(after: 0)
    }

    public func stop() async {
        let stopRequest = makeStopRequest()
        started = false
        _ = stopRuntimeUseCase.stopRuntime(using: stopRequest)
        pollHandle = nil
        workflowReloadHandle = nil
    }

    func snapshotState() -> RuntimeState {
        snapshotActiveRuntimeState()
    }

    func handleWorkflowChangeDetected() async {
        guard started else {
            return
        }

        _ = refreshWorkflowConfiguration(reason: "watch")
    }

    private func schedulePollTick(after delayMs: Int) {
        guard started else {
            return
        }

        if let pollHandle {
            schedulerPort.cancel(handle: pollHandle)
        }

        pollHandle = schedulerPort.schedule(after: max(delayMs, 0)) {
            await self.executeScheduledTick()
        }
    }

    private func executeScheduledTick() async {
        pollHandle = nil

        guard started, let workflowConfiguration else {
            return
        }

        if tickInFlight {
            schedulePollTick(after: state.pollIntervalMs)
            return
        }

        tickInFlight = true
        defer {
            tickInFlight = false
            if started {
                schedulePollTick(after: state.pollIntervalMs)
            }
        }

        let runningCountBeforeTick = state.running.count
        let retryCountBeforeTick = state.retryAttempts.count
        let reconciliationConfiguration = workflowConfiguration
        await reconcileRunningIssues(using: reconciliationConfiguration)

        let dispatchResult = await runDispatchPhase()
        emit(
            kind: .tick,
            outcome: dispatchResult.outcome,
            message: dispatchResult.message,
            details: [
                "running_before": String(runningCountBeforeTick),
                "running_after": String(state.running.count),
                "retries_before": String(retryCountBeforeTick),
                "retries_after": String(state.retryAttempts.count),
                "dispatched": String(dispatchResult.dispatchedCount)
            ]
        )
        emitRuntimeStatusSnapshot(outcome: dispatchResult.outcome)
    }

    private func runDispatchPhase() async -> (outcome: String, message: String?, dispatchedCount: Int) {
        guard startupCommand != nil else {
            return ("skipped", "Missing startup command context.", 0)
        }

        switch refreshWorkflowConfiguration(reason: "dispatch") {
        case .ready(let workflowConfiguration):
            let candidates: [SymphonyIssue]
            do {
                candidates = try await fetchIssuesUseCase.fetchCandidateIssues(
                    using: workflowConfiguration.serviceConfig.tracker
                ).issues
            } catch {
                emit(
                    kind: .warning,
                    outcome: "candidate_fetch_failed",
                    message: errorMessage(from: error),
                    details: structuredErrorDetails(from: error)
                )
                return ("candidate_fetch_failed", errorMessage(from: error), 0)
            }

            let eligibleIssues = selectDispatchIssuesUseCase.selectEligibleIssues(
                from: candidates,
                in: state,
                using: workflowConfiguration.serviceConfig
            ).issues

            var dispatchedCount = 0
            for issue in eligibleIssues {
                guard state.hasAvailableSlot(
                    for: issue,
                    using: workflowConfiguration.serviceConfig
                ) else {
                    continue
                }

                dispatchIssue(
                    issue,
                    attempt: nil,
                    alreadyClaimed: false,
                    using: workflowConfiguration
                )
                dispatchedCount += 1
            }

            return ("completed", nil, dispatchedCount)
        case .blocked(let blocker):
            emit(
                kind: .warning,
                outcome: "dispatch_preflight_blocked",
                message: blocker.message,
                details: [
                    "code": blocker.code,
                    "retryable": String(blocker.retryable)
                ]
            )
            return ("blocked", blocker.code, 0)
        }
    }

    private func dispatchIssue(
        _ issue: SymphonyIssue,
        attempt: Int?,
        alreadyClaimed: Bool,
        using workflowConfiguration: SymphonyWorkflowConfigurationResultContract
    ) {
        if !alreadyClaimed {
            state = runtimeStateTransition.claim(issueID: issue.id, in: state)
        }

        let request = SymphonyWorkerAttemptRequestContract(
            issue: issue,
            attempt: attempt,
            workflowConfiguration: workflowConfiguration
        )
        let handles = workerExecutionPort.start(
            request: request,
            onProgress: { liveSession in
                await self.handleWorkerProgress(issueID: issue.id, liveSession: liveSession)
            },
            onComplete: { result in
                await self.handleWorkerCompletion(result)
            }
        )
        let runningEntry = SymphonyRunningEntryContract(
            workerHandle: handles.workerHandle,
            monitorHandle: handles.monitorHandle,
            identifier: issue.identifier,
            issue: issue,
            liveSession: nil,
            retryAttempt: attempt,
            startedAt: clockPort.now()
        )
        state = runtimeStateTransition.registerRunning(
            issueID: issue.id,
            entry: runningEntry,
            in: state
        )

        emit(
            kind: .dispatch,
            outcome: "started",
            issue: issue,
            details: [
                "attempt": String(attempt ?? 0),
                "worker_handle": handles.workerHandle
            ]
        )
    }

    private func handleWorkerProgress(
        issueID: String,
        liveSession: SymphonyLiveSessionContract?
    ) {
        guard let entry = state.running[issueID] else {
            return
        }

        state = runtimeStateTransition.updateRunningEntry(
            issueID: issueID,
            issue: entry.issue,
            liveSession: liveSession,
            in: state
        )
    }

    private func handleWorkerCompletion(
        _ result: SymphonyWorkerAttemptResultContract
    ) async {
        guard let workflowConfiguration,
              state.running[result.issueID] != nil else {
            emit(
                kind: .warning,
                outcome: "worker_completion_ignored",
                issueID: result.issueID,
                issueIdentifier: result.issueIdentifier,
                message: result.error
            )
            return
        }

        let refreshedIssue = result.refreshedIssue
        let trackerConfiguration = workflowConfiguration.serviceConfig.tracker
        let normalizedRefreshedStateType = refreshedIssue.map { trackerConfiguration.normalizedStateType($0.stateType) }

        if result.terminalReason == .succeeded,
           let refreshedIssue,
           let normalizedRefreshedStateType,
           trackerConfiguration.normalizedActiveStateTypes.contains(normalizedRefreshedStateType) {
            let delayMs = retryBackoffPolicy.continuationDelayMs()
            let timerHandle = schedulerPort.schedule(after: delayMs) {
                await self.processRetry(issueID: result.issueID)
            }
            state = runtimeStateTransition.scheduleContinuationRetry(
                issueID: result.issueID,
                identifier: result.issueIdentifier,
                timerHandle: timerHandle,
                dueAtMs: clockPort.nowMs() + Int64(delayMs),
                in: state
            )
            emit(
                kind: .retry,
                outcome: "continuation_scheduled",
                issue: refreshedIssue,
                message: nil,
                details: [
                    "attempt": "1",
                    "delay_ms": String(delayMs)
                ]
            )
            return
        }

        if result.terminalReason == .succeeded,
           let refreshedIssue,
           let normalizedRefreshedStateType,
           trackerConfiguration.normalizedTerminalStateTypes.contains(normalizedRefreshedStateType) {
            do {
                _ = try cleanupWorkspaceUseCase.cleanupWorkspace(
                    for: refreshedIssue.identifier,
                    using: workflowConfiguration.serviceConfig
                )
            } catch {
                emit(
                    kind: .warning,
                    outcome: "terminal_cleanup_failed",
                    issue: refreshedIssue,
                    message: errorMessage(from: error),
                    details: structuredErrorDetails(from: error)
                )
            }
        }

        if result.terminalReason == .succeeded {
            state = runtimeStateTransition.completeAttempt(
                result,
                latestRateLimits: Optional<SymphonyCodexRateLimitSnapshotContract>.none,
                in: state
            )
            emit(
                kind: .dispatch,
                outcome: "completed",
                issueID: result.issueID,
                issueIdentifier: result.issueIdentifier,
                message: result.error
            )
            return
        }

        let nextAttempt = max((state.running[result.issueID]?.retryAttempt ?? 0) + 1, 1)
        let delayMs = retryBackoffPolicy.failureDelayMs(
            forAttempt: nextAttempt,
            maxRetryBackoffMs: workflowConfiguration.serviceConfig.agent.maxRetryBackoffMs
        )
        let timerHandle = schedulerPort.schedule(after: delayMs) {
            await self.processRetry(issueID: result.issueID)
        }
        state = runtimeStateTransition.scheduleFailureRetry(
            issueID: result.issueID,
            identifier: result.issueIdentifier,
            nextAttempt: nextAttempt,
            error: result.error ?? result.terminalReason.rawValue,
            timerHandle: timerHandle,
            dueAtMs: clockPort.nowMs() + Int64(delayMs),
            in: state
        )
        emit(
            kind: .retry,
            outcome: "failure_scheduled",
            issueID: result.issueID,
            issueIdentifier: result.issueIdentifier,
            message: result.error,
            details: [
                "delay_ms": String(delayMs)
            ]
        )
    }

    private func processRetry(issueID: String) async {
        guard let workflowConfiguration,
              let retryEntry = state.retryAttempts[issueID] else {
            return
        }

        let issues: [SymphonyIssue]
        do {
            issues = try await fetchIssuesUseCase.fetchIssueStates(
                issueIDs: [issueID],
                using: workflowConfiguration.serviceConfig.tracker
            ).issues
        } catch {
            let nextAttempt = max(retryEntry.attempt + 1, 1)
            let delayMs = retryBackoffPolicy.failureDelayMs(
                forAttempt: nextAttempt,
                maxRetryBackoffMs: workflowConfiguration.serviceConfig.agent.maxRetryBackoffMs
            )
            let timerHandle = schedulerPort.schedule(after: delayMs) {
                await self.processRetry(issueID: issueID)
            }
            state = runtimeStateTransition.scheduleFailureRetry(
                issueID: retryEntry.issueID,
                identifier: retryEntry.identifier,
                nextAttempt: nextAttempt,
                error: errorMessage(from: error),
                timerHandle: timerHandle,
                dueAtMs: clockPort.nowMs() + Int64(delayMs),
                in: state
            )
            emit(
                kind: .warning,
                outcome: "retry_refresh_failed",
                issueID: retryEntry.issueID,
                issueIdentifier: retryEntry.identifier,
                message: errorMessage(from: error),
                details: structuredErrorDetails(from: error)
            )
            return
        }

        guard let issue = issues.first(where: { $0.id == issueID }) else {
            state = runtimeStateTransition.release(issueID: issueID, in: state)
            emit(
                kind: .retry,
                outcome: "released_missing_issue",
                issueID: retryEntry.issueID,
                issueIdentifier: retryEntry.identifier,
                message: "Retry candidate is no longer available."
            )
            return
        }

        let trackerConfiguration = workflowConfiguration.serviceConfig.tracker
        guard trackerConfiguration.containsActiveStateType(issue.stateType) else {
            state = runtimeStateTransition.release(issueID: issueID, in: state)
            emit(
                kind: .retry,
                outcome: "released_inactive_issue",
                issue: issue,
                message: "Retry candidate is no longer active."
            )
            return
        }

        let evaluationState: RuntimeState = runtimeStateTransition.unclaim(issueID: issueID, in: state)
        guard evaluationState.canClaim(issueID: issue.id),
              eligibilityPolicy.passesBlockerRule(
                issue: issue,
                terminalStateTypes: workflowConfiguration.serviceConfig.tracker.terminalStateTypes
              ) else {
            state = runtimeStateTransition.release(issueID: issueID, in: state)
            emit(
                kind: .retry,
                outcome: "released_ineligible_issue",
                issue: issue,
                message: "Retry candidate is no longer eligible."
            )
            return
        }

        guard evaluationState.hasAvailableSlot(
            for: issue,
            using: workflowConfiguration.serviceConfig
        ) else {
            let error = "no available orchestrator slots"
            let nextAttempt = max(retryEntry.attempt + 1, 1)
            let delayMs = retryBackoffPolicy.failureDelayMs(
                forAttempt: nextAttempt,
                maxRetryBackoffMs: workflowConfiguration.serviceConfig.agent.maxRetryBackoffMs
            )
            let timerHandle = schedulerPort.schedule(after: delayMs) {
                await self.processRetry(issueID: issueID)
            }
            state = runtimeStateTransition.scheduleFailureRetry(
                issueID: retryEntry.issueID,
                identifier: retryEntry.identifier,
                nextAttempt: nextAttempt,
                error: error,
                timerHandle: timerHandle,
                dueAtMs: clockPort.nowMs() + Int64(delayMs),
                in: state
            )
            emit(
                kind: .retry,
                outcome: "requeued_slot_exhausted",
                issue: issue,
                message: error,
                details: [
                    "delay_ms": String(delayMs)
                ]
            )
            return
        }

        dispatchIssue(
            issue,
            attempt: retryEntry.attempt,
            alreadyClaimed: true,
            using: workflowConfiguration
        )
    }

    private func reconcileRunningIssues(
        using workflowConfiguration: SymphonyWorkflowConfigurationResultContract
    ) async {
        guard !state.running.isEmpty else {
            emit(
                kind: .reconciliation,
                outcome: "noop",
                message: "No running issues to reconcile."
            )
            return
        }

        await reconcileStalledIssues(using: workflowConfiguration)
        await refreshRunningIssues(using: workflowConfiguration)
    }

    private func reconcileStalledIssues(
        using workflowConfiguration: SymphonyWorkflowConfigurationResultContract
    ) async {
        let stallTimeoutMs = workflowConfiguration.serviceConfig.workerStallTimeoutMs
        guard stallTimeoutMs > 0 else {
            return
        }

        let now = clockPort.now()
        let runningEntries = Array(state.running.values)

        for entry in runningEntries {
            guard state.running[entry.issue.id] != nil else {
                continue
            }

            let referenceTimestamp = entry.liveSession?.lastActivityTimestamp ?? entry.startedAt
            let elapsedMs = Int(now.timeIntervalSince(referenceTimestamp) * 1000)
            guard elapsedMs >= stallTimeoutMs else {
                continue
            }

            workerExecutionPort.cancel(workerHandle: entry.workerHandle)

            let nextAttempt = max((entry.retryAttempt ?? 0) + 1, 1)
            let delayMs = retryBackoffPolicy.failureDelayMs(
                forAttempt: nextAttempt,
                maxRetryBackoffMs: workflowConfiguration.serviceConfig.agent.maxRetryBackoffMs
            )
            let timerHandle = schedulerPort.schedule(after: delayMs) {
                await self.processRetry(issueID: entry.issue.id)
            }
            state = runtimeStateTransition.scheduleFailureRetry(
                issueID: entry.issue.id,
                identifier: entry.identifier,
                nextAttempt: nextAttempt,
                error: "worker stalled",
                timerHandle: timerHandle,
                dueAtMs: clockPort.nowMs() + Int64(delayMs),
                in: state
            )
            emit(
                kind: .reconciliation,
                outcome: "stalled",
                issue: entry.issue,
                message: "Worker exceeded the configured stall timeout.",
                details: [
                    "elapsed_ms": String(elapsedMs),
                    "delay_ms": String(delayMs)
                ]
            )
        }
    }

    private func refreshRunningIssues(
        using workflowConfiguration: SymphonyWorkflowConfigurationResultContract
    ) async {
        let issueIDs = Array(state.running.keys)
        guard !issueIDs.isEmpty else {
            return
        }

        let refreshedIssues: [SymphonyIssue]
        do {
            refreshedIssues = try await fetchIssuesUseCase.fetchIssueStates(
                issueIDs: issueIDs,
                using: workflowConfiguration.serviceConfig.tracker
            ).issues
        } catch {
            emit(
                kind: .warning,
                outcome: "reconciliation_refresh_failed",
                message: errorMessage(from: error),
                details: structuredErrorDetails(from: error)
            )
            return
        }

        let refreshedByID = Dictionary(uniqueKeysWithValues: refreshedIssues.map { ($0.id, $0) })
        let trackerConfiguration = workflowConfiguration.serviceConfig.tracker

        for issueID in issueIDs {
            guard let runningEntry = state.running[issueID],
                  let refreshedIssue = refreshedByID[issueID] else {
                continue
            }

            let normalizedStateType = trackerConfiguration.normalizedStateType(refreshedIssue.stateType)
            if trackerConfiguration.normalizedTerminalStateTypes.contains(normalizedStateType) {
                workerExecutionPort.cancel(workerHandle: runningEntry.workerHandle)
                do {
                    _ = try cleanupWorkspaceUseCase.cleanupWorkspace(
                        for: refreshedIssue.identifier,
                        using: workflowConfiguration.serviceConfig
                    )
                } catch {
                    emit(
                        kind: .warning,
                        outcome: "terminal_cleanup_failed",
                        issue: refreshedIssue,
                        message: errorMessage(from: error),
                        details: structuredErrorDetails(from: error)
                    )
                }
                state = runtimeStateTransition.release(issueID: issueID, in: state)
                emit(
                    kind: .reconciliation,
                    outcome: "terminal_released",
                    issue: refreshedIssue
                )
                continue
            }

            if trackerConfiguration.normalizedActiveStateTypes.contains(normalizedStateType) {
                state = runtimeStateTransition.updateRunningEntry(
                    issueID: issueID,
                    issue: refreshedIssue,
                    liveSession: runningEntry.liveSession,
                    in: state
                )
                emit(
                    kind: .reconciliation,
                    outcome: "active_updated",
                    issue: refreshedIssue
                )
                continue
            }

            workerExecutionPort.cancel(workerHandle: runningEntry.workerHandle)
            state = runtimeStateTransition.release(issueID: issueID, in: state)
            emit(
                kind: .reconciliation,
                outcome: "inactive_released",
                issue: refreshedIssue
            )
        }
    }

    private func performStartupTerminalWorkspaceCleanup(
        using workflowConfiguration: SymphonyWorkflowConfigurationResultContract
    ) async {
        let terminalStateTypes = workflowConfiguration.serviceConfig.tracker.terminalStateTypes
        guard !terminalStateTypes.isEmpty else {
            return
        }

        let terminalIssues: [SymphonyIssue]
        do {
            terminalIssues = try await fetchIssuesUseCase.fetchIssues(
                stateTypes: terminalStateTypes,
                using: workflowConfiguration.serviceConfig.tracker
            ).issues
        } catch {
            emit(
                kind: .warning,
                outcome: "startup_cleanup_fetch_failed",
                message: errorMessage(from: error),
                details: structuredErrorDetails(from: error)
            )
            return
        }

        for issue in terminalIssues {
            do {
                let cleanup = try cleanupWorkspaceUseCase.cleanupWorkspace(
                    for: issue.identifier,
                    using: workflowConfiguration.serviceConfig
                )
                emit(
                    kind: .startupCleanup,
                    outcome: cleanup.removed ? "removed" : "missing",
                    issue: issue,
                    details: [
                        "workspace_path": cleanup.workspacePath
                    ]
                )
            } catch {
                emit(
                    kind: .warning,
                    outcome: "startup_cleanup_failed",
                    issue: issue,
                    message: errorMessage(from: error),
                    details: structuredErrorDetails(from: error)
                )
            }
        }
    }

    private func startWorkflowReloadMonitoring(path: String) {
        guard let workflowReloadMonitorPort else {
            return
        }

        do {
            workflowReloadHandle = try workflowReloadMonitorPort.startMonitoring(path: path) {
                await self.handleWorkflowChangeDetected()
            }
            emit(
                kind: .startup,
                outcome: "workflow_watch_started",
                details: [
                    "workflow_path": path
                ]
            )
        } catch {
            emit(
                kind: .warning,
                outcome: "workflow_watch_start_failed",
                message: errorMessage(from: error),
                details: structuredErrorDetails(from: error)
            )
        }
    }

    private func refreshWorkflowConfiguration(
        reason: String
    ) -> SymphonyDispatchPreflightOutcomeContract {
        guard let request = workflowConfigurationRequest() else {
            return .blocked(
                SymphonyDispatchPreflightBlockerError(
                    code: "symphony.dispatch_preflight.missing_startup_command",
                    message: "The runtime is missing startup command context.",
                    retryable: false,
                    details: nil
                )
            )
        }

        switch dispatchPreflightValidationService.validateForDispatch(request) {
        case .ready(let configuration):
            applyWorkflowConfiguration(
                configuration,
                reason: reason
            )
            return .ready(configuration)
        case .blocked(let blocker):
            workflowConfiguration = lastKnownGoodWorkflowConfiguration
            emit(
                kind: .warning,
                outcome: reason == "watch" ? "workflow_reload_blocked" : "workflow_revalidation_blocked",
                message: blocker.message,
                details: [
                    "code": blocker.code,
                    "retryable": String(blocker.retryable)
                ]
            )
            return .blocked(blocker)
        }
    }

    private func applyWorkflowConfiguration(
        _ configuration: SymphonyWorkflowConfigurationResultContract,
        reason: String
    ) {
        let previousConfiguration = workflowConfiguration
        let previousPollInterval = state.pollIntervalMs
        let changed = previousConfiguration != configuration
        let pollIntervalChanged = previousPollInterval != configuration.serviceConfig.polling.intervalMs

        workflowConfiguration = configuration
        lastKnownGoodWorkflowConfiguration = configuration
        state = runtimeStateTransition.apply(
            serviceConfig: configuration.serviceConfig,
            to: state
        )

        if pollIntervalChanged, started, !tickInFlight {
            if let pollHandle {
                schedulerPort.cancel(handle: pollHandle)
                self.pollHandle = nil
            }
            schedulePollTick(after: state.pollIntervalMs)
        }

        guard changed else {
            return
        }

        emit(
            kind: .tick,
            outcome: "workflow_reloaded",
            details: [
                "reason": reason,
                "poll_interval_ms": String(configuration.serviceConfig.polling.intervalMs),
                "pending_poll_replaced": String(pollIntervalChanged && started && !tickInFlight)
            ]
        )
    }

    private func workflowConfigurationRequest() -> SymphonyWorkflowConfigurationRequestContract? {
        guard let startupCommand else {
            return nil
        }

        return SymphonyWorkflowConfigurationRequestContract(
            explicitWorkflowPath: startupCommand.explicitWorkflowPath,
            currentWorkingDirectoryPath: startupCommand.currentWorkingDirectoryPath
        )
    }

    private func emit(
        kind: SymphonyOrchestratorLogEventContract.Kind,
        outcome: String,
        issue: SymphonyIssue? = nil,
        issueID: String? = nil,
        issueIdentifier: String? = nil,
        sessionID: String? = nil,
        message: String? = nil,
        details: [String: String] = [:]
    ) {
        logSinkPort.emit(
            SymphonyOrchestratorLogEventContract(
                kind: kind,
                timestamp: clockPort.now(),
                outcome: outcome,
                issueID: issue?.id ?? issueID,
                issueIdentifier: issue?.identifier ?? issueIdentifier,
                sessionID: sessionID,
                message: message,
                details: details
            )
        )
    }

    private func emitRuntimeStatusSnapshot(outcome: String) {
        guard let runtimeStatusSinkPort,
              let projectRuntimeStatusSnapshotUseCase else {
            return
        }

        let observableState = snapshotActiveRuntimeState()
        runtimeStatusSinkPort.emit(
            projectRuntimeStatusSnapshotUseCase.projectStatusSnapshot(
                from: observableState,
                outcome: outcome
            )
        )
    }

    private func makeStopRequest() -> SymphonyRuntimeStopRequestContract {
        SymphonyRuntimeStopRequestContract(
            pollHandle: pollHandle,
            workflowReloadHandle: workflowReloadHandle,
            retryTimerHandles: state.retryAttempts.values.map(\.timerHandle),
            workerHandles: state.running.values.map(\.workerHandle)
        )
    }

    private func stateForSnapshot() -> RuntimeState {
        state
    }

    private func snapshotActiveRuntimeState() -> RuntimeState {
        runtimeStateTransition.snapshotActiveRuntime(
            at: clockPort.now(),
            from: stateForSnapshot()
        )
    }

    private func makeDispatchPreflightBlocker(
        from error: any Error
    ) -> SymphonyDispatchPreflightBlockerError {
        if let structuredError = error as? any StructuredErrorProtocol {
            return SymphonyDispatchPreflightBlockerError(
                code: structuredError.code,
                message: structuredError.message,
                retryable: structuredError.retryable,
                details: structuredError.details
            )
        }

        return SymphonyDispatchPreflightBlockerError(
            code: "symphony.dispatch_preflight.unexpected_error",
            message: "An unexpected error blocked dispatch preflight validation.",
            retryable: false,
            details: error.localizedDescription
        )
    }

    private func errorMessage(from error: any Error) -> String {
        if let structuredError = error as? any StructuredErrorProtocol {
            return structuredError.message
        }

        return error.localizedDescription
    }

    private func structuredErrorDetails(
        from error: any Error
    ) -> [String: String] {
        guard let structuredError = error as? any StructuredErrorProtocol else {
            return [:]
        }

        var details = [
            "code": structuredError.code,
            "retryable": String(structuredError.retryable)
        ]
        if let structuredDetails = structuredError.details {
            details["details"] = structuredDetails
        }
        return details
    }

    private static func emptyState(
        using serviceConfig: SymphonyServiceConfigContract? = nil
    ) -> RuntimeState {
        RuntimeState(
            pollIntervalMs: serviceConfig?.polling.intervalMs ?? 0,
            maxConcurrentAgents: serviceConfig?.agent.maxConcurrentAgents ?? 0,
            running: [:],
            claimed: [],
            retryAttempts: [:],
            completed: [],
            codexTotals: .init(
                inputTokens: 0,
                outputTokens: 0,
                totalTokens: 0,
                secondsRunning: 0
            ),
            codexRateLimits: nil
        )
    }
}
