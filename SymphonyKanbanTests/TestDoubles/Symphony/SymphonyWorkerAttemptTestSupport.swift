import Foundation
@testable import SymphonyKanban

enum SymphonyWorkerAttemptTestSupport {
    static func makeService(
        workspacePort: WorkerAttemptWorkspaceLifecycleSpy = WorkerAttemptWorkspaceLifecycleSpy(),
        trackerPort: WorkerAttemptIssueTrackerReadSpy = WorkerAttemptIssueTrackerReadSpy(),
        promptRenderer: WorkerAttemptPromptRendererSpy = WorkerAttemptPromptRendererSpy(renderedPrompt: "Rendered full prompt"),
        runner: WorkerAttemptRunnerSpy = WorkerAttemptRunnerSpy(),
        logSink: WorkerAttemptLogSinkSpy = WorkerAttemptLogSinkSpy()
    ) -> SymphonyWorkerAttemptService {
        SymphonyWorkerAttemptService(
            prepareWorkspaceUseCase: PrepareSymphonyWorkspaceUseCase(workspaceLifecyclePort: workspacePort),
            validateWorkspaceLaunchContextUseCase: ValidateSymphonyWorkspaceLaunchContextUseCase(workspaceLifecyclePort: workspacePort),
            completeRunAttemptUseCase: CompleteSymphonyRunAttemptUseCase(workspaceLifecyclePort: workspacePort),
            cancelActiveTurnUseCase: CancelSymphonyActiveTurnUseCase(runnerPort: runner),
            renderPromptUseCase: RenderSymphonyPromptUseCase(promptRendererPort: promptRenderer),
            fetchIssuesUseCase: FetchSymphonyIssuesUseCase(issueTrackerReadPort: trackerPort),
            requestFactoryPort: SymphonyCodexRequestFactoryPortAdapter(),
            runnerPort: runner,
            telemetryPort: SymphonyWorkerAttemptTelemetryPortAdapter(logSink: logSink),
            dateProvider: { Date(timeIntervalSince1970: 100) }
        )
    }

    static func makeRequest(
        issue: SymphonyIssue = makeIssue(state: "Todo", stateType: "unstarted"),
        attempt: Int? = nil,
        maxTurns: Int = 2
    ) -> SymphonyWorkerAttemptRequestContract {
        SymphonyWorkerAttemptRequestContract(
            issue: issue,
            attempt: attempt,
            workflowConfiguration: .init(
                workflowDefinition: .init(
                    resolvedPath: "/tmp/WORKFLOW.md",
                    config: [:],
                    promptTemplate: "Issue: {{ issue.identifier }}"
                ),
                serviceConfig: .init(
                    tracker: .init(
                        kind: "linear",
                        endpoint: "https://linear.example",
                        projectSlug: "proj",
                        activeStateTypes: ["backlog", "unstarted", "started"],
                        terminalStateTypes: ["completed", "canceled"]
                    ),
                    polling: .init(intervalMs: 10_000),
                    workspace: .init(rootPath: "/tmp/symphony_workspaces"),
                    hooks: .init(
                        afterCreate: nil,
                        beforeRun: nil,
                        afterRun: "echo after run",
                        beforeRemove: nil,
                        timeoutMs: 1_000
                    ),
                    agent: .init(
                        maxConcurrentAgents: 1,
                        maxTurns: maxTurns,
                        maxRetryBackoffMs: 60_000,
                        maxConcurrentAgentsByState: [:]
                    ),
                    codex: .init(
                        command: "codex app-server",
                        approvalPolicy: nil,
                        threadSandbox: nil,
                        turnSandboxPolicy: nil,
                        turnTimeoutMs: 3_600_000,
                        readTimeoutMs: 5_000,
                        stallTimeoutMs: 300_000
                    )
                )
            )
        )
    }

    static func makeIssue(state: String, stateType: String) -> SymphonyIssue {
        SymphonyIssue(
            id: "issue-1",
            identifier: "ABC-123",
            title: "Fix build",
            description: nil,
            priority: 1,
            state: state,
            stateType: stateType,
            branchName: nil,
            url: nil,
            labels: [],
            blockedBy: [],
            createdAt: nil,
            updatedAt: nil
        )
    }

    static func makeCompletedTurnResult(
        threadID: String,
        turnID: String
    ) -> SymphonyCodexTurnExecutionResultContract {
        SymphonyCodexTurnExecutionResultContract(
            session: .init(threadID: threadID, turnID: turnID),
            outcome: .completed,
            completedAt: Date(timeIntervalSince1970: 200),
            codexAppServerPID: "12345",
            lastEvent: SymphonyCodexRuntimeEventContract(
                kind: .turnCompleted,
                timestamp: Date(timeIntervalSince1970: 200),
                session: .init(threadID: threadID, turnID: turnID),
                codexAppServerPID: "12345",
                message: "completed"
            ),
            usage: .init(inputTokens: 10, outputTokens: 5, totalTokens: 15)
        )
    }

    static func makeCancelledTurnResult(
        threadID: String,
        turnID: String
    ) -> SymphonyCodexTurnExecutionResultContract {
        SymphonyCodexTurnExecutionResultContract(
            session: .init(threadID: threadID, turnID: turnID),
            outcome: .cancelled,
            completedAt: Date(timeIntervalSince1970: 201),
            codexAppServerPID: "12345",
            lastEvent: SymphonyCodexRuntimeEventContract(
                kind: .turnCancelled,
                timestamp: Date(timeIntervalSince1970: 201),
                session: .init(threadID: threadID, turnID: turnID),
                codexAppServerPID: "12345",
                message: "The turn was cancelled."
            )
        )
    }
}

final class WorkerAttemptWorkspaceLifecycleSpy: @unchecked Sendable, SymphonyWorkspaceLifecyclePortProtocol {
    private let lock = NSLock()
    private var prepareCalls = 0
    private var completeCalls = 0

    func prepareWorkspaceForAttempt(
        issueIdentifier _: String,
        using _: SymphonyServiceConfigContract
    ) throws -> SymphonyWorkspaceContract {
        lock.lock()
        prepareCalls += 1
        lock.unlock()

        return SymphonyWorkspaceContract(
            path: "/tmp/symphony_workspaces/ABC-123",
            workspaceKey: SymphonyWorkspaceKey(value: "ABC-123"),
            createdNow: true
        )
    }

    func completeRunAttempt(
        in workspace: SymphonyWorkspaceContract,
        using _: SymphonyServiceConfigContract
    ) -> SymphonyRunAttemptCompletionContract {
        lock.lock()
        completeCalls += 1
        lock.unlock()
        return SymphonyRunAttemptCompletionContract(workspacePath: workspace.path)
    }

    func cleanupWorkspace(
        for _: String,
        using _: SymphonyServiceConfigContract
    ) throws -> SymphonyWorkspaceCleanupContract {
        SymphonyWorkspaceCleanupContract(
            workspacePath: "/tmp/symphony_workspaces/ABC-123",
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

    func completeRunAttemptCalls() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return completeCalls
    }
}

final class WorkerAttemptIssueTrackerReadSpy: @unchecked Sendable, SymphonyIssueTrackerReadPortProtocol {
    private let lock = NSLock()
    private var responses: [[SymphonyIssue]]

    init(responses: [[SymphonyIssue]] = []) {
        self.responses = responses
    }

    func fetchCandidateIssues(
        using _: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        []
    }

    func fetchIssues(
        byStateTypes _: [String],
        using _: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        []
    }

    func fetchIssueStates(
        byIDs _: [String],
        using _: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        lock.withLock {
            guard !responses.isEmpty else {
                return []
            }

            return responses.removeFirst()
        }
    }
}

final class WorkerAttemptPromptRendererSpy: @unchecked Sendable, SymphonyPromptRendererPortProtocol {
    private let renderedPrompt: String

    init(renderedPrompt: String) {
        self.renderedPrompt = renderedPrompt
    }

    func renderPromptTemplate(
        _: String,
        issue _: SymphonyIssue,
        attempt _: Int?
    ) throws -> String {
        renderedPrompt
    }
}

final class WorkerAttemptRunnerSpy: @unchecked Sendable, SymphonyCodexRunnerPortProtocol {
    enum Step {
        case immediate(events: [SymphonyCodexRuntimeEventContract] = [], result: SymphonyCodexTurnExecutionResultContract)
        case throwing(events: [SymphonyCodexRuntimeEventContract] = [], error: SymphonyAgentRuntimeApplicationError)
        case waitForCancellation(events: [SymphonyCodexRuntimeEventContract] = [], result: SymphonyCodexTurnExecutionResultContract)
    }

    private let lock = NSLock()
    private var startSteps: [Step]
    private var continuationSteps: [Step]
    private var recordedStartRequests: [SymphonyCodexSessionStartupContract] = []
    private var recordedContinuationRequests: [SymphonyCodexTurnStartContract] = []
    private var cancelCalls = 0
    private var awaitingCancellation = false
    private var cancellationRequested = false
    private var pendingContinuation: CheckedContinuation<SymphonyCodexTurnExecutionResultContract, Never>?
    private var pendingResult: SymphonyCodexTurnExecutionResultContract?

    init(
        startSteps: [Step] = [],
        continuationSteps: [Step] = []
    ) {
        self.startSteps = startSteps
        self.continuationSteps = continuationSteps
    }

    func startSession(
        using startup: SymphonyCodexSessionStartupContract,
        onEvent: @escaping @Sendable (SymphonyCodexRuntimeEventContract) -> Void
    ) async throws -> SymphonyCodexTurnExecutionResultContract {
        let step = lock.withLock { () -> Step in
            recordedStartRequests.append(startup)
            return startSteps.removeFirst()
        }
        return try await execute(step, onEvent: onEvent)
    }

    func continueTurn(
        using request: SymphonyCodexTurnStartContract,
        onEvent: @escaping @Sendable (SymphonyCodexRuntimeEventContract) -> Void
    ) async throws -> SymphonyCodexTurnExecutionResultContract {
        let step = lock.withLock { () -> Step in
            recordedContinuationRequests.append(request)
            return continuationSteps.removeFirst()
        }
        return try await execute(step, onEvent: onEvent)
    }

    func cancelActiveTurn() -> SymphonyActiveTurnCancellationResultContract {
        lock.lock()
        guard awaitingCancellation else {
            lock.unlock()
            return SymphonyActiveTurnCancellationResultContract(disposition: .noActiveTurn)
        }

        guard !cancellationRequested else {
            lock.unlock()
            return SymphonyActiveTurnCancellationResultContract(disposition: .alreadyRequested)
        }

        cancelCalls += 1
        cancellationRequested = true
        let continuation = pendingContinuation
        let result = pendingResult
        let shouldResume = continuation != nil
        if shouldResume {
            awaitingCancellation = false
        }
        pendingContinuation = nil
        pendingResult = nil
        lock.unlock()
        if shouldResume {
            continuation?.resume(returning: result ?? SymphonyCodexTurnExecutionResultContract(
                session: .init(threadID: "thread-cancel", turnID: "turn-cancel"),
                outcome: .cancelled,
                completedAt: Date(timeIntervalSince1970: 999)
            ))
        }
        return SymphonyActiveTurnCancellationResultContract(disposition: .requestAccepted)
    }

    func startRequests() -> [SymphonyCodexSessionStartupContract] {
        lock.lock()
        defer { lock.unlock() }
        return recordedStartRequests
    }

    func continueRequests() -> [SymphonyCodexTurnStartContract] {
        lock.lock()
        defer { lock.unlock() }
        return recordedContinuationRequests
    }

    func cancelCallCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return cancelCalls
    }

    private func execute(
        _ step: Step,
        onEvent: @escaping @Sendable (SymphonyCodexRuntimeEventContract) -> Void
    ) async throws -> SymphonyCodexTurnExecutionResultContract {
        switch step {
        case .immediate(let events, let result):
            events.forEach(onEvent)
            return result
        case .throwing(let events, let error):
            events.forEach(onEvent)
            throw error
        case .waitForCancellation(let events, let result):
            events.forEach(onEvent)
            return await withCheckedContinuation { continuation in
                lock.lock()
                awaitingCancellation = true
                pendingContinuation = continuation
                pendingResult = result
                let shouldResume = cancellationRequested
                if shouldResume {
                    awaitingCancellation = false
                    pendingContinuation = nil
                    pendingResult = nil
                }
                lock.unlock()

                if shouldResume {
                    continuation.resume(returning: result)
                }
            }
        }
    }
}

final class WorkerAttemptLogSinkSpy: @unchecked Sendable, SymphonyWorkerAttemptLogSinkPortProtocol {
    private let lock = NSLock()
    private var storedEvents: [SymphonyWorkerAttemptLogEventContract] = []

    func emit(_ event: SymphonyWorkerAttemptLogEventContract) {
        lock.lock()
        storedEvents.append(event)
        lock.unlock()
    }

    func events() -> [SymphonyWorkerAttemptLogEventContract] {
        lock.lock()
        defer { lock.unlock() }
        return storedEvents
    }
}
