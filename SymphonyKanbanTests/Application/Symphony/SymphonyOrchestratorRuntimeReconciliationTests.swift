import Foundation
import Testing
@testable import SymphonyKanban

@Suite(.serialized)
struct SymphonyOrchestratorRuntimeReconciliationTests {
    @Test
    func reconciliationCancelsTerminalIssuesAndCleansWorkspace() async throws {
        let activeIssue = SymphonyOrchestratorRuntimeTestSupport.makeIssue(id: "issue-1", identifier: "ABC-1", priority: 1, state: "Todo")
        let tracker = RuntimeIssueTrackerReadSpy(
            candidateResponses: [
                .success([activeIssue]),
                .success([])
            ],
            issueStateResponses: [
                .success([SymphonyOrchestratorRuntimeTestSupport.makeIssue(id: "issue-1", identifier: "ABC-1", priority: 1, state: "Done")])
            ]
        )
        let workspacePort = RuntimeWorkspaceLifecycleSpy()
        let scheduler = RuntimeSchedulerSpy()
        let workerExecution = RuntimeWorkerExecutionSpy()
        let logSink = OrchestratorLogSinkSpy()
        let service = SymphonyOrchestratorRuntimeTestSupport.makeService(
            tracker: tracker,
            workspacePort: workspacePort,
            scheduler: scheduler,
            workerExecution: workerExecution,
            logSink: logSink
        )

        await service.start(
            command: SymphonyOrchestratorRuntimeTestSupport.makeStartupCommand(),
            initialConfiguration: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration()
        )
        await scheduler.runNext()

        let pollHandle = try #require(scheduler.handle(forDelay: 30_000))
        await scheduler.run(handle: pollHandle)

        let state = await service.snapshotState()

        #expect(state.running.isEmpty)
        #expect(state.claimed.isEmpty)
        #expect(workerExecution.cancelledWorkerHandles().count == 1)
        #expect(workspacePort.cleanedIssueIdentifiers().contains("ABC-1"))
        #expect(logSink.events().contains {
            $0.kind == .reconciliation && $0.outcome == "terminal_released" && $0.issueID == "issue-1"
        })
    }

    @Test
    func stallDetectionUsesLastCodexTimestampAndHonorsDisablement() async throws {
        let issue = SymphonyOrchestratorRuntimeTestSupport.makeIssue(id: "issue-1", identifier: "ABC-1", priority: 1, state: "Todo")

        let enabledTracker = RuntimeIssueTrackerReadSpy(
            candidateResponses: [
                .success([issue]),
                .success([])
            ]
        )
        let enabledScheduler = RuntimeSchedulerSpy()
        let enabledWorkerExecution = RuntimeWorkerExecutionSpy()
        let enabledClock = RuntimeClockSpy(now: Date(timeIntervalSince1970: 50))
        let enabledLogSink = OrchestratorLogSinkSpy()
        let enabledService = SymphonyOrchestratorRuntimeTestSupport.makeService(
            tracker: enabledTracker,
            scheduler: enabledScheduler,
            clock: enabledClock,
            workerExecution: enabledWorkerExecution,
            logSink: enabledLogSink,
            workflowConfiguration: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration(stallTimeoutMs: 1_000)
        )

        await enabledService.start(
            command: SymphonyOrchestratorRuntimeTestSupport.makeStartupCommand(),
            initialConfiguration: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration(stallTimeoutMs: 1_000)
        )
        await enabledScheduler.runNext()

        let enabledHandle = try #require(enabledWorkerExecution.handle(forIssueIdentifier: "ABC-1"))
        await enabledWorkerExecution.reportProgress(
            handle: enabledHandle.workerHandle,
            liveSession: SymphonyOrchestratorRuntimeTestSupport.makeLiveSession(timestamp: Date(timeIntervalSince1970: 49))
        )
        enabledClock.setNow(Date(timeIntervalSince1970: 50.5))

        let enabledPollHandle = try #require(enabledScheduler.handle(forDelay: 30_000))
        await enabledScheduler.run(handle: enabledPollHandle)

        let enabledState = await enabledService.snapshotState()

        #expect(enabledWorkerExecution.cancelledWorkerHandles().contains(enabledHandle.workerHandle))
        #expect(enabledState.retryAttempts["issue-1"]?.error == "worker stalled")
        #expect(enabledLogSink.events().contains {
            $0.kind == .reconciliation && $0.outcome == "stalled" && $0.issueID == "issue-1"
        })

        let disabledTracker = RuntimeIssueTrackerReadSpy(
            candidateResponses: [
                .success([issue]),
                .success([])
            ],
            issueStateResponses: [
                .success([issue])
            ]
        )
        let disabledScheduler = RuntimeSchedulerSpy()
        let disabledWorkerExecution = RuntimeWorkerExecutionSpy()
        let disabledClock = RuntimeClockSpy(now: Date(timeIntervalSince1970: 70))
        let disabledService = SymphonyOrchestratorRuntimeTestSupport.makeService(
            tracker: disabledTracker,
            scheduler: disabledScheduler,
            clock: disabledClock,
            workerExecution: disabledWorkerExecution,
            workflowConfiguration: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration(stallTimeoutMs: 0)
        )

        await disabledService.start(
            command: SymphonyOrchestratorRuntimeTestSupport.makeStartupCommand(),
            initialConfiguration: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration(stallTimeoutMs: 0)
        )
        await disabledScheduler.runNext()

        let disabledHandle = try #require(disabledWorkerExecution.handle(forIssueIdentifier: "ABC-1"))
        await disabledWorkerExecution.reportProgress(
            handle: disabledHandle.workerHandle,
            liveSession: SymphonyOrchestratorRuntimeTestSupport.makeLiveSession(timestamp: Date(timeIntervalSince1970: 60))
        )
        disabledClock.setNow(Date(timeIntervalSince1970: 90))

        let disabledPollHandle = try #require(disabledScheduler.handle(forDelay: 30_000))
        await disabledScheduler.run(handle: disabledPollHandle)

        let disabledState = await disabledService.snapshotState()

        #expect(disabledWorkerExecution.cancelledWorkerHandles().isEmpty)
        #expect(Array(disabledState.running.keys) == ["issue-1"])
        #expect(disabledState.retryAttempts.isEmpty)
    }
}
