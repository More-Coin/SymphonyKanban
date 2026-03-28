import Foundation

public final class SymphonyWorkerAttemptService: @unchecked Sendable {
    private struct TurnEvaluation {
        let issue: SymphonyIssue
        let refreshedIssue: SymphonyIssue?
        let terminalReason: SymphonyWorkerAttemptTerminalReasonContract
        let runtimeError: SymphonyAgentRuntimeApplicationError?
        let errorMessage: String?
        let continueFromActiveState: Bool

        init(
            issue: SymphonyIssue,
            refreshedIssue: SymphonyIssue?,
            terminalReason: SymphonyWorkerAttemptTerminalReasonContract,
            runtimeError: SymphonyAgentRuntimeApplicationError?,
            errorMessage: String?,
            continueFromActiveState: Bool = false
        ) {
            self.issue = issue
            self.refreshedIssue = refreshedIssue
            self.terminalReason = terminalReason
            self.runtimeError = runtimeError
            self.errorMessage = errorMessage
            self.continueFromActiveState = continueFromActiveState
        }

        func shouldContinue(
            activeIssue _: SymphonyIssue,
            turnCount: Int,
            maxTurns: Int
        ) -> Bool {
            continueFromActiveState && turnCount < maxTurns
        }
    }

    public typealias DateProvider = @Sendable () -> Date

    private enum Defaults {
        static let continuationLead = "Continue working in the existing live thread."
    }

    private let prepareWorkspaceUseCase: PrepareSymphonyWorkspaceUseCase
    private let validateWorkspaceLaunchContextUseCase: ValidateSymphonyWorkspaceLaunchContextUseCase
    private let completeRunAttemptUseCase: CompleteSymphonyRunAttemptUseCase
    private let cancelActiveTurnUseCase: CancelSymphonyActiveTurnUseCase
    private let renderPromptUseCase: RenderSymphonyPromptUseCase
    private let fetchIssuesUseCase: FetchSymphonyIssuesUseCase
    private let resolveCodexCommandUseCase: ResolveSymphonyCodexCommandUseCase
    private let requestFactoryPort: any SymphonyCodexRequestFactoryPortProtocol
    private let runnerPort: any SymphonyCodexRunnerPortProtocol
    private let telemetryPort: any SymphonyWorkerAttemptTelemetryPortProtocol
    private let dateProvider: DateProvider

    private let stateLock = NSLock()
    private var cancellationRequested = false

    public init(
        prepareWorkspaceUseCase: PrepareSymphonyWorkspaceUseCase,
        validateWorkspaceLaunchContextUseCase: ValidateSymphonyWorkspaceLaunchContextUseCase,
        completeRunAttemptUseCase: CompleteSymphonyRunAttemptUseCase,
        cancelActiveTurnUseCase: CancelSymphonyActiveTurnUseCase,
        renderPromptUseCase: RenderSymphonyPromptUseCase,
        fetchIssuesUseCase: FetchSymphonyIssuesUseCase,
        resolveCodexCommandUseCase: ResolveSymphonyCodexCommandUseCase,
        requestFactoryPort: any SymphonyCodexRequestFactoryPortProtocol,
        runnerPort: any SymphonyCodexRunnerPortProtocol,
        telemetryPort: any SymphonyWorkerAttemptTelemetryPortProtocol,
        dateProvider: @escaping DateProvider = Date.init
    ) {
        self.prepareWorkspaceUseCase = prepareWorkspaceUseCase
        self.validateWorkspaceLaunchContextUseCase = validateWorkspaceLaunchContextUseCase
        self.completeRunAttemptUseCase = completeRunAttemptUseCase
        self.cancelActiveTurnUseCase = cancelActiveTurnUseCase
        self.renderPromptUseCase = renderPromptUseCase
        self.fetchIssuesUseCase = fetchIssuesUseCase
        self.resolveCodexCommandUseCase = resolveCodexCommandUseCase
        self.requestFactoryPort = requestFactoryPort
        self.telemetryPort = telemetryPort
        self.dateProvider = dateProvider
        self.runnerPort = runnerPort
    }

    @discardableResult
    public func cancelActiveAttempt() -> SymphonyActiveTurnCancellationResultContract {
        markCancellationRequested()
        return cancelActiveTurnUseCase.cancelActiveTurn()
    }

    public func execute(
        _ request: SymphonyWorkerAttemptRequestContract,
        onProgress: (@Sendable (SymphonyLiveSessionContract?) async -> Void)? = nil
    ) async -> SymphonyWorkerAttemptResultContract {
        let configuration = request.workflowConfiguration
        let startedAt = dateProvider()
        let recorder = telemetryPort.makeRecorder(
            issueID: request.issue.id,
            issueIdentifier: request.issue.identifier,
            attempt: request.attempt
        )

        resetCancellation()
        recorder.emit(
            kind: .attemptStarted,
            timestamp: startedAt,
            turnCount: 0,
            workspacePath: nil,
            terminalReason: nil,
            message: nil
        )

        var workspace: SymphonyWorkspaceContract?
        var issue = request.issue
        var turnCount = 0
        var refreshedIssue: SymphonyIssue?
        var terminalReason = SymphonyWorkerAttemptTerminalReasonContract.failed
        var runtimeError: SymphonyAgentRuntimeApplicationError?
        var errorMessage: String?

        do {
            workspace = try prepareWorkspaceUseCase.prepareWorkspace(
                for: issue.identifier,
                using: configuration.serviceConfig
            )

            let workspacePath = workspace?.path
            if isCancellationRequested() {
                terminalReason = .canceledByReconciliation
                errorMessage = "Worker attempt canceled before the first turn started."
            } else {
                let launchContext = try validateWorkspaceLaunchContextUseCase.validate(
                    currentWorkingDirectoryPath: workspacePath ?? "",
                    for: try requireWorkspace(workspace),
                    using: configuration.serviceConfig
                )

                let firstPrompt = try renderPromptUseCase.renderPrompt(
                    using: SymphonyPromptRenderRequestContract(
                        workflowDefinition: configuration.workflowDefinition,
                        issue: issue,
                        attempt: request.attempt
                    )
                ).prompt
                let commandResolution = resolveCodexCommandUseCase.execute(
                    currentWorkingDirectoryPath: launchContext.workspacePath,
                    explicitWorkflowPath: configuration.workflowDefinition.resolvedPath
                )

                let firstTurnCount = 1
                let firstResult = try await runnerPort.startSession(
                    using: requestFactoryPort.makeSessionStartup(
                        issue: issue,
                        prompt: firstPrompt,
                        workspacePath: launchContext.workspacePath,
                        command: commandResolution.effectiveCommand,
                        using: configuration.serviceConfig
                    ),
                    onEvent: { [recorder] event in
                        recorder.recordRuntimeEvent(
                            event,
                            workspacePath: workspacePath,
                            turnCount: firstTurnCount
                        )
                        if let onProgress {
                            Task {
                                await onProgress(recorder.liveSessionSnapshot())
                            }
                        }
                    }
                )

                turnCount = firstTurnCount
                recorder.recordTurnResult(firstResult, turnCount: turnCount)

                let initialEvaluation = try await evaluateTurnResult(
                    firstResult,
                    issue: issue,
                    request: request
                )
                issue = initialEvaluation.issue
                refreshedIssue = initialEvaluation.refreshedIssue
                terminalReason = initialEvaluation.terminalReason
                runtimeError = initialEvaluation.runtimeError
                errorMessage = initialEvaluation.errorMessage

                var shouldContinue = initialEvaluation.shouldContinue(
                    activeIssue: issue,
                    turnCount: turnCount,
                    maxTurns: max(1, configuration.serviceConfig.agent.maxTurns)
                )

                while shouldContinue {
                    if isCancellationRequested() {
                        terminalReason = .canceledByReconciliation
                        errorMessage = "Worker attempt canceled before the continuation turn started."
                        break
                    }

                    turnCount += 1
                    let currentTurnCount = turnCount
                    let continuationResult = try await runnerPort.continueTurn(
                        using: requestFactoryPort.makeContinuationTurnRequest(
                            issue: issue,
                            threadID: try requireLiveSession(recorder.liveSessionSnapshot()).threadID,
                            inputText: makeContinuationGuidance(
                                issue: issue,
                                turnCount: currentTurnCount,
                                maxTurns: max(1, configuration.serviceConfig.agent.maxTurns)
                            ),
                            workspacePath: launchContext.workspacePath,
                            using: configuration.serviceConfig
                        ),
                        onEvent: { [recorder] event in
                            recorder.recordRuntimeEvent(
                                event,
                                workspacePath: workspacePath,
                                turnCount: currentTurnCount
                            )
                            if let onProgress {
                                Task {
                                    await onProgress(recorder.liveSessionSnapshot())
                                }
                            }
                        }
                    )

                    recorder.recordTurnResult(continuationResult, turnCount: currentTurnCount)

                    let continuationEvaluation = try await evaluateTurnResult(
                        continuationResult,
                        issue: issue,
                        request: request
                    )
                    issue = continuationEvaluation.issue
                    refreshedIssue = continuationEvaluation.refreshedIssue
                    terminalReason = continuationEvaluation.terminalReason
                    runtimeError = continuationEvaluation.runtimeError
                    errorMessage = continuationEvaluation.errorMessage

                    shouldContinue = continuationEvaluation.shouldContinue(
                        activeIssue: issue,
                        turnCount: currentTurnCount,
                        maxTurns: max(1, configuration.serviceConfig.agent.maxTurns)
                    )
                }
            }
        } catch {
            let normalized = normalize(error)
            terminalReason = normalized.terminalReason
            runtimeError = normalized.runtimeError
            errorMessage = normalized.message
        }

        let completion = workspace.map {
            completeRunAttemptUseCase.completeRunAttempt(
                in: $0,
                using: configuration.serviceConfig
            )
        }
        let completedAt = dateProvider()
        let liveSession = recorder.liveSessionSnapshot()
        let workspacePath = completion?.workspacePath ?? workspace?.path

        emitLifecycleFailureLogIfNeeded(
            recorder: recorder,
            turnCount: turnCount,
            workspacePath: workspacePath,
            runtimeError: runtimeError,
            terminalReason: terminalReason,
            message: errorMessage
        )

        recorder.emit(
            kind: .attemptCompleted,
            timestamp: completedAt,
            turnCount: turnCount,
            workspacePath: workspacePath,
            terminalReason: terminalReason,
            message: errorMessage
        )
        resetCancellation()

        return SymphonyWorkerAttemptResultContract(
            issueID: request.issue.id,
            issueIdentifier: request.issue.identifier,
            attempt: request.attempt,
            workspacePath: workspacePath,
            startedAt: startedAt,
            completedAt: completedAt,
            turnCount: turnCount,
            terminalReason: terminalReason,
            refreshedIssue: refreshedIssue,
            liveSession: liveSession,
            completion: completion,
            error: errorMessage
        )
    }

    private func evaluateTurnResult(
        _ result: SymphonyCodexTurnExecutionResultContract,
        issue: SymphonyIssue,
        request: SymphonyWorkerAttemptRequestContract
    ) async throws -> TurnEvaluation {
        if isCancellationRequested() || result.outcome == .cancelled {
            return TurnEvaluation(
                issue: issue,
                refreshedIssue: nil,
                terminalReason: .canceledByReconciliation,
                runtimeError: nil,
                errorMessage: "Worker attempt canceled by reconciliation."
            )
        }

        guard result.outcome == .completed else {
            return TurnEvaluation(
                issue: issue,
                refreshedIssue: nil,
                terminalReason: .failed,
                runtimeError: nil,
                errorMessage: result.lastEvent?.message ?? "The worker attempt failed."
            )
        }

        let refresh = try await fetchIssuesUseCase.fetchIssueStates(
            issueIDs: [issue.id],
            using: request.workflowConfiguration.serviceConfig.tracker
        )
        guard let refreshedIssue = refresh.issues.first(where: { $0.id == issue.id }) else {
            return TurnEvaluation(
                issue: issue,
                refreshedIssue: nil,
                terminalReason: .failed,
                runtimeError: nil,
                errorMessage: "Issue state refresh did not return the active issue."
            )
        }

        let activeStateTypes = normalizeStates(request.workflowConfiguration.serviceConfig.tracker.activeStateTypes)
        let terminalStateTypes = normalizeStates(request.workflowConfiguration.serviceConfig.tracker.terminalStateTypes)
        let normalizedStateType = normalizeState(refreshedIssue.stateType)

        if terminalStateTypes.contains(normalizedStateType) {
            return TurnEvaluation(
                issue: refreshedIssue,
                refreshedIssue: refreshedIssue,
                terminalReason: .succeeded,
                runtimeError: nil,
                errorMessage: nil
            )
        }

        if !activeStateTypes.contains(normalizedStateType) {
            return TurnEvaluation(
                issue: refreshedIssue,
                refreshedIssue: refreshedIssue,
                terminalReason: .succeeded,
                runtimeError: nil,
                errorMessage: nil
            )
        }

        return TurnEvaluation(
            issue: refreshedIssue,
            refreshedIssue: refreshedIssue,
            terminalReason: .succeeded,
            runtimeError: nil,
            errorMessage: nil,
            continueFromActiveState: true
        )
    }

    private func makeContinuationGuidance(
        issue: SymphonyIssue,
        turnCount: Int,
        maxTurns: Int
    ) -> String {
        [
            Defaults.continuationLead,
            "Issue: \(issue.identifier): \(issue.title)",
            "Keep using the same workspace and thread.",
            "Do not repeat the original full task prompt.",
            "This is continuation turn \(turnCount) of \(maxTurns)."
        ].joined(separator: "\n")
    }

    private func emitLifecycleFailureLogIfNeeded(
        recorder: any SymphonyWorkerAttemptTelemetryRecorderPortProtocol,
        turnCount: Int,
        workspacePath: String?,
        runtimeError: SymphonyAgentRuntimeApplicationError?,
        terminalReason: SymphonyWorkerAttemptTerminalReasonContract,
        message: String?
    ) {
        let kind: SymphonyWorkerAttemptLogEventContract.Kind? = switch terminalReason {
        case .canceledByReconciliation:
            .cancellation
        case .timedOut:
            .timeout
        case .stalled:
            nil
        case .succeeded:
            nil
        case .failed:
            switch runtimeError {
            case .requirementsMismatch:
                .policyFailure
            case .inputRequired:
                .userInputRequired
            case .processExit:
                .abnormalExit
            case .none where turnCount == 0:
                .startupFailure
            default:
                nil
            }
        }

        guard let kind else {
            return
        }

        recorder.emit(
            kind: kind,
            timestamp: dateProvider(),
            turnCount: turnCount,
            workspacePath: workspacePath,
            terminalReason: terminalReason,
            message: message
        )
    }

    private func mapTerminalReason(
        for runtimeError: SymphonyAgentRuntimeApplicationError?
    ) -> SymphonyWorkerAttemptTerminalReasonContract {
        switch runtimeError {
        case .turnTimeout:
            .timedOut
        default:
            .failed
        }
    }

    private func message(
        for runtimeError: SymphonyAgentRuntimeApplicationError?
    ) -> String {
        runtimeError?.details ?? runtimeError?.message ?? "The worker attempt failed."
    }

    private func normalize(
        _ error: any Error
    ) -> (
        terminalReason: SymphonyWorkerAttemptTerminalReasonContract,
        runtimeError: SymphonyAgentRuntimeApplicationError?,
        message: String
    ) {
        if isCancellationRequested() {
            return (
                .canceledByReconciliation,
                .turnCancelled(details: "Worker attempt canceled by reconciliation."),
                "Worker attempt canceled by reconciliation."
            )
        }

        if let runtimeError = error as? SymphonyAgentRuntimeApplicationError {
            return (
                mapTerminalReason(for: runtimeError),
                runtimeError,
                message(for: runtimeError)
            )
        }

        if let structuredError = error as? any StructuredErrorProtocol {
            return (
                .failed,
                nil,
                structuredError.details ?? structuredError.message
            )
        }

        return (
            .failed,
            nil,
            error.localizedDescription
        )
    }

    private func resetCancellation() {
        stateLock.lock()
        cancellationRequested = false
        stateLock.unlock()
    }

    private func markCancellationRequested() {
        stateLock.lock()
        cancellationRequested = true
        stateLock.unlock()
    }

    private func isCancellationRequested() -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return cancellationRequested
    }

    private func requireWorkspace(
        _ workspace: SymphonyWorkspaceContract?
    ) throws -> SymphonyWorkspaceContract {
        guard let workspace else {
            throw SymphonyDispatchPreflightBlockerError(
                code: "symphony.worker_attempt.workspace_missing",
                message: "The worker attempt did not produce a workspace.",
                retryable: false,
                details: nil
            )
        }

        return workspace
    }

    private func requireLiveSession(
        _ session: SymphonyLiveSessionContract?
    ) throws -> SymphonyLiveSessionContract {
        guard let session else {
            throw SymphonyDispatchPreflightBlockerError(
                code: "symphony.worker_attempt.live_session_missing",
                message: "The runner did not report a live session for the continuation turn.",
                retryable: true,
                details: nil
            )
        }

        return session
    }

    private func normalizeStates(_ states: [String]) -> Set<String> {
        Set(states.map(normalizeState))
    }

    private func normalizeState(_ state: String) -> String {
        state.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

}
