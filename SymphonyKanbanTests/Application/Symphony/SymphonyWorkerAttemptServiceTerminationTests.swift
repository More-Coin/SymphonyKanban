import Foundation
import Testing
@testable import SymphonyKanban

@Suite(.serialized)
struct SymphonyWorkerAttemptServiceTerminationTests {
    @Test
    func workerAttemptMapsTurnTimeoutToTimedOutAndAlwaysRunsAfterRun() async {
        let workspacePort = WorkerAttemptWorkspaceLifecycleSpy()
        let trackerPort = WorkerAttemptIssueTrackerReadSpy()
        let promptRenderer = WorkerAttemptPromptRendererSpy(renderedPrompt: "Rendered full prompt")
        let runner = WorkerAttemptRunnerSpy(startSteps: [
            .throwing(
                error: SymphonyAgentRuntimeApplicationError.turnTimeout(timeoutMs: 3_600_000)
            )
        ])
        let logSink = WorkerAttemptLogSinkSpy()
        let service = SymphonyWorkerAttemptTestSupport.makeService(
            workspacePort: workspacePort,
            trackerPort: trackerPort,
            promptRenderer: promptRenderer,
            runner: runner,
            logSink: logSink
        )

        let result = await service.execute(SymphonyWorkerAttemptTestSupport.makeRequest())

        #expect(result.terminalReason == .timedOut)
        #expect(workspacePort.completeRunAttemptCalls() == 1)
        #expect(logSink.events().contains { $0.kind == .timeout && $0.terminalReason == .timedOut })
    }

    @Test
    func workerAttemptProducesCanceledByReconciliationAndFinalizesAfterRun() async {
        let workspacePort = WorkerAttemptWorkspaceLifecycleSpy()
        let trackerPort = WorkerAttemptIssueTrackerReadSpy()
        let promptRenderer = WorkerAttemptPromptRendererSpy(renderedPrompt: "Rendered full prompt")
        let runner = WorkerAttemptRunnerSpy(startSteps: [
            .waitForCancellation(result: SymphonyWorkerAttemptTestSupport.makeCancelledTurnResult(threadID: "thread-1", turnID: "turn-1"))
        ])
        let logSink = WorkerAttemptLogSinkSpy()
        let service = SymphonyWorkerAttemptTestSupport.makeService(
            workspacePort: workspacePort,
            trackerPort: trackerPort,
            promptRenderer: promptRenderer,
            runner: runner,
            logSink: logSink
        )

        let task = Task {
            await service.execute(SymphonyWorkerAttemptTestSupport.makeRequest())
        }

        while runner.startRequests().isEmpty {
            await Task.yield()
        }

        let cancellation = service.cancelActiveAttempt()
        let result = await task.value

        #expect(cancellation.disposition == .requestAccepted)
        #expect(result.terminalReason == .canceledByReconciliation)
        #expect(runner.cancelCallCount() == 1)
        #expect(workspacePort.completeRunAttemptCalls() == 1)
        #expect(logSink.events().contains { $0.kind == .cancellation && $0.terminalReason == .canceledByReconciliation })
    }

    @Test
    func workerAttemptEmitsUnsupportedToolAndUserInputRequiredLogs() async {
        let workspacePort = WorkerAttemptWorkspaceLifecycleSpy()
        let trackerPort = WorkerAttemptIssueTrackerReadSpy()
        let promptRenderer = WorkerAttemptPromptRendererSpy(renderedPrompt: "Rendered full prompt")
        let runner = WorkerAttemptRunnerSpy(startSteps: [
            .throwing(
                events: [
                    SymphonyCodexRuntimeEventContract(
                        kind: .unsupportedToolCall,
                        timestamp: Date(timeIntervalSince1970: 150),
                        session: .init(threadID: "thread-1", turnID: "turn-1"),
                        codexAppServerPID: "12345",
                        requestKind: .dynamicToolCall,
                        message: "Rejected unsupported dynamic tool call."
                    ),
                    SymphonyCodexRuntimeEventContract(
                        kind: .turnInputRequired,
                        timestamp: Date(timeIntervalSince1970: 151),
                        session: .init(threadID: "thread-1", turnID: "turn-1"),
                        codexAppServerPID: "12345",
                        requestKind: .toolRequestUserInput,
                        message: "The Codex app-server requested user input."
                    )
                ],
                error: SymphonyAgentRuntimeApplicationError.inputRequired(
                    details: "The agent runtime requested user input."
                )
            )
        ])
        let logSink = WorkerAttemptLogSinkSpy()
        let service = SymphonyWorkerAttemptTestSupport.makeService(
            workspacePort: workspacePort,
            trackerPort: trackerPort,
            promptRenderer: promptRenderer,
            runner: runner,
            logSink: logSink
        )

        let result = await service.execute(SymphonyWorkerAttemptTestSupport.makeRequest())

        #expect(result.terminalReason == .failed)
        #expect(logSink.events().contains { $0.kind == .unsupportedToolEvent })
        #expect(logSink.events().contains { $0.kind == .userInputRequired })
    }
}
