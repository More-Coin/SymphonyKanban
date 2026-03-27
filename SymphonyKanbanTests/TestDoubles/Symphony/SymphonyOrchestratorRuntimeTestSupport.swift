import Foundation
@testable import SymphonyKanban

enum SymphonyOrchestratorRuntimeTestSupport {
    static func makeService(
        tracker: RuntimeIssueTrackerReadSpy = RuntimeIssueTrackerReadSpy(),
        workspacePort: RuntimeWorkspaceLifecycleSpy = RuntimeWorkspaceLifecycleSpy(),
        scheduler: RuntimeSchedulerSpy = RuntimeSchedulerSpy(),
        clock: RuntimeClockSpy = RuntimeClockSpy(now: Date(timeIntervalSince1970: 10)),
        workerExecution: RuntimeWorkerExecutionSpy = RuntimeWorkerExecutionSpy(),
        logSink: OrchestratorLogSinkSpy = OrchestratorLogSinkSpy(),
        runtimeStatusSink: RuntimeStatusSinkSpy? = nil,
        workflowConfiguration: SymphonyWorkflowConfigurationResultContract? = nil,
        workflowLoader: WorkflowLoaderSpy? = nil,
        configResolver: ConfigResolverSpy? = nil,
        validator: StartupValidatorSpy = StartupValidatorSpy(),
        trackerAuthPort: TrackerAuthPortSpy = TrackerAuthPortSpy(),
        reloadMonitor: RuntimeWorkflowReloadMonitorSpy? = nil
    ) -> SymphonyOrchestratorRuntimeService {
        let workflowConfiguration = workflowConfiguration ?? makeWorkflowConfiguration()
        let workflowLoader = workflowLoader ?? WorkflowLoaderSpy(
            definition: workflowConfiguration.workflowDefinition
        )
        let configResolver = configResolver ?? ConfigResolverSpy(serviceConfig: workflowConfiguration.serviceConfig)
        let preflight = SymphonyDispatchPreflightValidationService(
            resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase(
                workflowLoaderPort: workflowLoader,
                configResolverPort: configResolver
            ),
            validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase(
                startupConfigurationValidatorPort: validator
            ),
            validateTrackerConnectionUseCase: ValidateSymphonyTrackerConnectionReadinessUseCase(
                trackerAuthPort: trackerAuthPort
            )
        )

        return SymphonyOrchestratorRuntimeService(
            dispatchPreflightValidationService: preflight,
            fetchIssuesUseCase: FetchSymphonyIssuesUseCase(issueTrackerReadPort: tracker),
            cleanupWorkspaceUseCase: CleanupSymphonyWorkspaceUseCase(workspaceLifecyclePort: workspacePort),
            projectRuntimeStatusSnapshotUseCase: runtimeStatusSink.map { _ in
                ProjectSymphonyRuntimeStatusSnapshotUseCase(
                    clockPort: clock,
                    runtimeStatusProjectorPort: SymphonyRuntimeStatusProjectorPortAdapter()
                )
            },
            workerExecutionPort: workerExecution,
            schedulerPort: scheduler,
            clockPort: clock,
            logSinkPort: logSink,
            runtimeStatusSinkPort: runtimeStatusSink,
            workflowReloadMonitorPort: reloadMonitor
        )
    }

    static func makeWorkflowConfiguration(
        maxConcurrentAgents: Int = 1,
        maxConcurrentAgentsByState: [String: Int] = [:],
        pollingIntervalMs: Int = 30_000,
        stallTimeoutMs: Int = 300_000,
        activeStateTypes: [String] = ["backlog", "unstarted", "started"],
        promptTemplate: String = "Issue: {{ issue.identifier }}"
    ) -> SymphonyWorkflowConfigurationResultContract {
        SymphonyWorkflowConfigurationResultContract(
            workflowDefinition: .init(
                resolvedPath: "/tmp/WORKFLOW.md",
                config: [:],
                promptTemplate: promptTemplate
            ),
            serviceConfig: .init(
                tracker: .init(
                    kind: "linear",
                    endpoint: "https://api.linear.app/graphql",
                    projectSlug: "proj",
                    activeStateTypes: activeStateTypes,
                    terminalStateTypes: ["completed", "canceled"]
                ),
                polling: .init(intervalMs: pollingIntervalMs),
                workspace: .init(rootPath: "/tmp/symphony_workspaces"),
                hooks: .init(
                    afterCreate: nil,
                    beforeRun: nil,
                    afterRun: nil,
                    beforeRemove: nil,
                    timeoutMs: 1_000
                ),
                agent: .init(
                    maxConcurrentAgents: maxConcurrentAgents,
                    maxTurns: 20,
                    maxRetryBackoffMs: 60_000,
                    maxConcurrentAgentsByState: maxConcurrentAgentsByState
                ),
                codex: .init(
                    command: "codex app-server",
                    approvalPolicy: nil,
                    threadSandbox: nil,
                    turnSandboxPolicy: nil,
                    turnTimeoutMs: 3_600_000,
                    readTimeoutMs: 5_000,
                    stallTimeoutMs: stallTimeoutMs
                )
            )
        )
    }

    static func makeStartupCommand() -> SymphonyStartupCommandContract {
        SymphonyStartupCommandContract(
            explicitWorkflowPath: "/tmp/WORKFLOW.md",
            currentWorkingDirectoryPath: "/tmp"
        )
    }

    static func makeIssue(
        id: String,
        identifier: String,
        priority: Int?,
        state: String,
        stateType: String
    ) -> SymphonyIssue {
        SymphonyIssue(
            id: id,
            identifier: identifier,
            title: "Issue \(identifier)",
            description: nil,
            priority: priority,
            state: state,
            stateType: stateType,
            branchName: nil,
            url: nil,
            labels: [],
            blockedBy: [],
            createdAt: Date(timeIntervalSince1970: 1),
            updatedAt: nil
        )
    }

    static func makeWorkerResult(
        issueID: String,
        issueIdentifier: String,
        terminalReason: SymphonyWorkerAttemptTerminalReasonContract,
        refreshedIssue: SymphonyIssue?,
        error: String? = nil
    ) -> SymphonyWorkerAttemptResultContract {
        SymphonyWorkerAttemptResultContract(
            issueID: issueID,
            issueIdentifier: issueIdentifier,
            attempt: 1,
            workspacePath: "/tmp/symphony_workspaces/\(issueIdentifier)",
            startedAt: Date(timeIntervalSince1970: 1),
            completedAt: Date(timeIntervalSince1970: 2),
            turnCount: 1,
            terminalReason: terminalReason,
            refreshedIssue: refreshedIssue,
            liveSession: makeLiveSession(timestamp: Date(timeIntervalSince1970: 2)),
            completion: .init(workspacePath: "/tmp/symphony_workspaces/\(issueIdentifier)"),
            error: error
        )
    }

    static func makeLiveSession(timestamp: Date) -> SymphonyLiveSessionContract {
        SymphonyLiveSessionContract(
            sessionID: "thread-1-turn-1",
            threadID: "thread-1",
            turnID: "turn-1",
            codexAppServerPID: "12345",
            lastCodexEvent: "turn_completed",
            lastCodexTimestamp: timestamp,
            lastCodexMessage: nil,
            codexInputTokens: 10,
            codexOutputTokens: 5,
            codexTotalTokens: 15,
            lastReportedInputTokens: 10,
            lastReportedOutputTokens: 5,
            lastReportedTotalTokens: 15,
            turnCount: 1
        )
    }

    static func index(of value: String, in values: [String]) -> Int? {
        values.firstIndex(of: value)
    }
}

enum RuntimeTrackerResponse {
    case success([SymphonyIssue])
    case failure(any Error)
}

final class OrchestratorEventRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String] = []

    func append(_ value: String) {
        lock.withLock {
            values.append(value)
        }
    }

    func events() -> [String] {
        lock.withLock { values }
    }
}

final class WorkflowLoaderSpy: @unchecked Sendable, SymphonyWorkflowLoaderPortProtocol {
    private let lock = NSLock()
    private var definition: SymphonyWorkflowDefinitionContract
    private let recorder: OrchestratorEventRecorder?

    init(
        definition: SymphonyWorkflowDefinitionContract,
        recorder: OrchestratorEventRecorder? = nil
    ) {
        self.definition = definition
        self.recorder = recorder
    }

    func loadWorkflow(
        using _: SymphonyWorkflowConfigurationRequestContract
    ) throws -> SymphonyWorkflowDefinitionContract {
        recorder?.append("preflight.load")
        return lock.withLock { definition }
    }

    func setDefinition(_ definition: SymphonyWorkflowDefinitionContract) {
        lock.withLock {
            self.definition = definition
        }
    }
}

final class ConfigResolverSpy: @unchecked Sendable, SymphonyConfigResolverPortProtocol {
    private let lock = NSLock()
    private var serviceConfig: SymphonyServiceConfigContract
    private let recorder: OrchestratorEventRecorder?

    init(
        serviceConfig: SymphonyServiceConfigContract,
        recorder: OrchestratorEventRecorder? = nil
    ) {
        self.serviceConfig = serviceConfig
        self.recorder = recorder
    }

    func resolveConfig(
        from _: SymphonyWorkflowDefinitionContract
    ) -> SymphonyServiceConfigContract {
        recorder?.append("preflight.resolve")
        return lock.withLock { serviceConfig }
    }

    func setServiceConfig(_ serviceConfig: SymphonyServiceConfigContract) {
        lock.withLock {
            self.serviceConfig = serviceConfig
        }
    }
}

final class StartupValidatorSpy: @unchecked Sendable, SymphonyStartupConfigurationValidatorPortProtocol {
    private let lock = NSLock()
    private let recorder: OrchestratorEventRecorder?
    private var error: (any Error)?

    init(
        recorder: OrchestratorEventRecorder? = nil,
        error: (any Error)? = nil
    ) {
        self.recorder = recorder
        self.error = error
    }

    func validate(
        _ configuration: SymphonyServiceConfigContract
    ) throws {
        recorder?.append("preflight.validate")
        _ = configuration
        if let error = lock.withLock({ self.error }) {
            throw error
        }
    }

    func setError(_ error: (any Error)?) {
        lock.withLock {
            self.error = error
        }
    }
}

final class RuntimeIssueTrackerReadSpy: @unchecked Sendable, SymphonyIssueTrackerReadPortProtocol {
    private let lock = NSLock()
    private let recorder: OrchestratorEventRecorder?
    private var candidateResponses: [RuntimeTrackerResponse]
    private var fetchIssuesResponses: [RuntimeTrackerResponse]
    private var issueStateResponses: [RuntimeTrackerResponse]

    init(
        recorder: OrchestratorEventRecorder? = nil,
        fetchIssuesResponses: [RuntimeTrackerResponse] = [],
        candidateResponses: [RuntimeTrackerResponse] = [],
        issueStateResponses: [RuntimeTrackerResponse] = []
    ) {
        self.recorder = recorder
        self.fetchIssuesResponses = fetchIssuesResponses
        self.candidateResponses = candidateResponses
        self.issueStateResponses = issueStateResponses
    }

    func fetchCandidateIssues(
        using _: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        recorder?.append("tracker.fetchCandidates")
        return try next(from: &candidateResponses)
    }

    func fetchIssues(
        byStateTypes _: [String],
        using _: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        recorder?.append("tracker.fetchIssues")
        return try next(from: &fetchIssuesResponses)
    }

    func fetchIssueStates(
        byIDs _: [String],
        using _: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        recorder?.append("tracker.fetchIssueStates")
        return try next(from: &issueStateResponses)
    }

    private func next(from responses: inout [RuntimeTrackerResponse]) throws -> [SymphonyIssue] {
        try lock.withLock {
            guard !responses.isEmpty else {
                return []
            }

            let response = responses.removeFirst()
            switch response {
            case .success(let issues):
                return issues
            case .failure(let error):
                throw error
            }
        }
    }
}

final class RuntimeWorkspaceLifecycleSpy: @unchecked Sendable, SymphonyWorkspaceLifecyclePortProtocol {
    private let lock = NSLock()
    private let recorder: OrchestratorEventRecorder?
    private var cleanedIdentifiers: [String] = []

    init(recorder: OrchestratorEventRecorder? = nil) {
        self.recorder = recorder
    }

    func prepareWorkspaceForAttempt(
        issueIdentifier _: String,
        using _: SymphonyServiceConfigContract
    ) throws -> SymphonyWorkspaceContract {
        SymphonyWorkspaceContract(
            path: "/tmp/symphony_workspaces/unused",
            workspaceKey: SymphonyWorkspaceKey(value: "unused"),
            createdNow: false
        )
    }

    func completeRunAttempt(
        in workspace: SymphonyWorkspaceContract,
        using _: SymphonyServiceConfigContract
    ) -> SymphonyRunAttemptCompletionContract {
        SymphonyRunAttemptCompletionContract(workspacePath: workspace.path)
    }

    func cleanupWorkspace(
        for issueIdentifier: String,
        using _: SymphonyServiceConfigContract
    ) throws -> SymphonyWorkspaceCleanupContract {
        lock.withLock {
            cleanedIdentifiers.append(issueIdentifier)
        }
        recorder?.append("workspace.cleanup.\(issueIdentifier)")
        return SymphonyWorkspaceCleanupContract(
            workspacePath: "/tmp/symphony_workspaces/\(issueIdentifier)",
            removed: true
        )
    }

    func validateCurrentWorkingDirectory(
        _ currentWorkingDirectoryPath: String,
        for workspace: SymphonyWorkspaceContract,
        using _: SymphonyServiceConfigContract
    ) throws -> String {
        _ = currentWorkingDirectoryPath
        return workspace.path
    }

    func cleanedIssueIdentifiers() -> [String] {
        lock.withLock { cleanedIdentifiers }
    }
}

final class RuntimeSchedulerSpy: @unchecked Sendable, SymphonyRuntimeSchedulerPortProtocol {
    struct ScheduledOperation {
        let handle: String
        let delayMs: Int
        let operation: @Sendable () async -> Void
    }

    private let lock = NSLock()
    private let recorder: OrchestratorEventRecorder?
    private var operations: [ScheduledOperation] = []
    private var cancelledHandles: Set<String> = []

    init(recorder: OrchestratorEventRecorder? = nil) {
        self.recorder = recorder
    }

    func schedule(
        after delayMs: Int,
        operation: @escaping @Sendable () async -> Void
    ) -> String {
        let handle = UUID().uuidString
        lock.withLock {
            operations.append(ScheduledOperation(handle: handle, delayMs: delayMs, operation: operation))
        }
        recorder?.append("scheduler.schedule.\(delayMs)")
        return handle
    }

    func cancel(handle: String) {
        lock.withLock {
            cancelledHandles.insert(handle)
            operations.removeAll { $0.handle == handle }
        }
    }

    func activeDelays() -> [Int] {
        lock.withLock { operations.map(\.delayMs) }
    }

    func handle(forDelay delayMs: Int) -> String? {
        lock.withLock {
            operations.first(where: { $0.delayMs == delayMs })?.handle
        }
    }

    func wasCancelled(handle: String) -> Bool {
        lock.withLock {
            cancelledHandles.contains(handle)
        }
    }

    func runNext() async {
        let scheduled = lock.withLock { () -> ScheduledOperation? in
            guard !operations.isEmpty else {
                return nil
            }
            return operations.removeFirst()
        }
        if let scheduled {
            await scheduled.operation()
        }
    }

    func run(handle: String) async {
        let scheduled = lock.withLock { () -> ScheduledOperation? in
            guard let index = operations.firstIndex(where: { $0.handle == handle }) else {
                return nil
            }
            return operations.remove(at: index)
        }
        if let scheduled {
            await scheduled.operation()
        }
    }
}

final class RuntimeClockSpy: @unchecked Sendable, SymphonyRuntimeClockPortProtocol {
    private let lock = NSLock()
    private var currentDate: Date

    init(now: Date) {
        currentDate = now
    }

    func now() -> Date {
        lock.withLock { currentDate }
    }

    func nowMs() -> Int64 {
        Int64(now().timeIntervalSince1970 * 1000)
    }

    func setNow(_ date: Date) {
        lock.withLock {
            currentDate = date
        }
    }
}

final class RuntimeWorkerExecutionSpy: @unchecked Sendable, SymphonyWorkerExecutionPortProtocol {
    struct CallbackBundle {
        let handle: SymphonyWorkerExecutionHandleContract
        let request: SymphonyWorkerAttemptRequestContract
        let onProgress: @Sendable (SymphonyLiveSessionContract?) async -> Void
        let onComplete: @Sendable (SymphonyWorkerAttemptResultContract) async -> Void
    }

    private let lock = NSLock()
    private let recorder: OrchestratorEventRecorder?
    private var callbacksByHandle: [String: CallbackBundle] = [:]
    private var handlesInOrder: [SymphonyWorkerExecutionHandleContract] = []
    private var issueIdentifiersByHandle: [String: String] = [:]
    private var cancelledHandles: [String] = []

    init(recorder: OrchestratorEventRecorder? = nil) {
        self.recorder = recorder
    }

    func start(
        request: SymphonyWorkerAttemptRequestContract,
        onProgress: @escaping @Sendable (SymphonyLiveSessionContract?) async -> Void,
        onComplete: @escaping @Sendable (SymphonyWorkerAttemptResultContract) async -> Void
    ) -> SymphonyWorkerExecutionHandleContract {
        let handle = SymphonyWorkerExecutionHandleContract(
            workerHandle: UUID().uuidString,
            monitorHandle: UUID().uuidString
        )
        lock.withLock {
            callbacksByHandle[handle.workerHandle] = CallbackBundle(
                handle: handle,
                request: request,
                onProgress: onProgress,
                onComplete: onComplete
            )
            handlesInOrder.append(handle)
            issueIdentifiersByHandle[handle.workerHandle] = request.issue.identifier
        }
        recorder?.append("worker.start.\(request.issue.identifier)")
        return handle
    }

    func cancel(workerHandle: String) {
        lock.withLock {
            cancelledHandles.append(workerHandle)
        }
    }

    func startedHandles() -> [SymphonyWorkerExecutionHandleContract] {
        lock.withLock { handlesInOrder }
    }

    func startedIssueIdentifiers() -> [String] {
        lock.withLock {
            handlesInOrder.compactMap { issueIdentifiersByHandle[$0.workerHandle] }
        }
    }

    func handle(forIssueIdentifier issueIdentifier: String) -> SymphonyWorkerExecutionHandleContract? {
        lock.withLock {
            handlesInOrder.first { issueIdentifiersByHandle[$0.workerHandle] == issueIdentifier }
        }
    }

    func request(forIssueIdentifier issueIdentifier: String) -> SymphonyWorkerAttemptRequestContract? {
        lock.withLock {
            guard let handle = handlesInOrder.first(where: {
                issueIdentifiersByHandle[$0.workerHandle] == issueIdentifier
            }) else {
                return nil
            }
            return callbacksByHandle[handle.workerHandle]?.request
        }
    }

    func reportProgress(
        handle: String,
        liveSession: SymphonyLiveSessionContract?
    ) async {
        let callback = lock.withLock { callbacksByHandle[handle]?.onProgress }
        await callback?(liveSession)
    }

    func complete(
        handle: String,
        result: SymphonyWorkerAttemptResultContract
    ) async {
        let callback = lock.withLock { callbacksByHandle[handle]?.onComplete }
        await callback?(result)
    }

    func cancelledWorkerHandles() -> [String] {
        lock.withLock { cancelledHandles }
    }
}

final class OrchestratorLogSinkSpy: @unchecked Sendable, SymphonyOrchestratorLogSinkPortProtocol {
    private let lock = NSLock()
    private var storedEvents: [SymphonyOrchestratorLogEventContract] = []

    func emit(_ event: SymphonyOrchestratorLogEventContract) {
        lock.withLock {
            storedEvents.append(event)
        }
    }

    func events() -> [SymphonyOrchestratorLogEventContract] {
        lock.withLock { storedEvents }
    }
}

final class RuntimeStatusSinkSpy: @unchecked Sendable, SymphonyRuntimeStatusSinkPortProtocol {
    private let lock = NSLock()
    private var storedSnapshots: [SymphonyRuntimeStatusSnapshotContract] = []

    func emit(_ snapshot: SymphonyRuntimeStatusSnapshotContract) {
        lock.withLock {
            storedSnapshots.append(snapshot)
        }
    }

    func snapshots() -> [SymphonyRuntimeStatusSnapshotContract] {
        lock.withLock { storedSnapshots }
    }
}

final class RuntimeWorkflowReloadMonitorSpy:
    @unchecked Sendable,
    SymphonyWorkflowReloadMonitorPortProtocol {
    private let lock = NSLock()
    private var callback: (@Sendable () async -> Void)?
    private var paths: [String] = []

    func startMonitoring(
        path: String,
        onChange: @escaping @Sendable () async -> Void
    ) throws -> SymphonyWorkflowReloadHandleContract {
        lock.withLock {
            paths.append(path)
            callback = onChange
        }
        return SymphonyWorkflowReloadHandleContract(value: UUID().uuidString)
    }

    func cancel(handle _: SymphonyWorkflowReloadHandleContract) {}

    func fireChange() async {
        let callback = lock.withLock { self.callback }
        await callback?()
    }

    func monitoredPaths() -> [String] {
        lock.withLock { paths }
    }
}
