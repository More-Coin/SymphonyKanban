import Foundation
import Testing
@testable import SymphonyKanban

@Suite(.serialized)
struct SymphonyOrchestratorRuntimeStartupTests {
    @Test
    func startupCleanupRemovesTerminalWorkspacesThenImmediateTickDispatchesCandidates() async {
        let recorder = OrchestratorEventRecorder()
        let tracker = RuntimeIssueTrackerReadSpy(
            recorder: recorder,
            fetchIssuesResponses: [
                .success([
                    SymphonyOrchestratorRuntimeTestSupport.makeIssue(
                        id: "terminal-1",
                        identifier: "TERM-1",
                        priority: 1,
                        state: "Done",
                        stateType: "completed"
                    )
                ])
            ],
            candidateResponses: [
                .success([
                    SymphonyOrchestratorRuntimeTestSupport.makeIssue(
                        id: "issue-1",
                        identifier: "ABC-1",
                        priority: 1,
                        state: "Todo",
                        stateType: "unstarted"
                    )
                ])
            ]
        )
        let workspacePort = RuntimeWorkspaceLifecycleSpy(recorder: recorder)
        let scheduler = RuntimeSchedulerSpy(recorder: recorder)
        let workerExecution = RuntimeWorkerExecutionSpy(recorder: recorder)
        let logSink = OrchestratorLogSinkSpy()
        let runtimeStatusSink = RuntimeStatusSinkSpy()
        let service = SymphonyOrchestratorRuntimeTestSupport.makeService(
            tracker: tracker,
            workspacePort: workspacePort,
            scheduler: scheduler,
            workerExecution: workerExecution,
            logSink: logSink,
            runtimeStatusSink: runtimeStatusSink
        )

        await service.start(
            workspaceLocator: SymphonyOrchestratorRuntimeTestSupport.makeWorkspaceLocator(),
            initialConfiguration: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration()
        )

        #expect(workspacePort.cleanedIssueIdentifiers() == ["TERM-1"])
        #expect(scheduler.activeDelays() == [0])
        #expect(runtimeStatusSink.snapshots().map(\.outcome) == ["startup_ready"])

        await scheduler.runNext()

        let state = await service.snapshotState()
        let events = recorder.events()
        let snapshots = runtimeStatusSink.snapshots()

        #expect(workerExecution.startedIssueIdentifiers() == ["ABC-1"])
        #expect(Array(state.running.keys) == ["issue-1"])
        #expect(state.claimed == ["issue-1"])
        #expect(snapshots.count == 2)
        #expect(snapshots.last?.outcome == "completed")
        #expect(snapshots.last?.running.map(\.issueIdentifier) == ["ABC-1"])
        #expect(logSink.events().contains { $0.kind == .startupCleanup && $0.outcome == "removed" })
        #expect(logSink.events().contains { $0.kind == .tick && $0.outcome == "completed" })
        #expect(SymphonyOrchestratorRuntimeTestSupport.index(of: "tracker.fetchIssues", in: events) ?? -1 < SymphonyOrchestratorRuntimeTestSupport.index(of: "workspace.cleanup.TERM-1", in: events) ?? .max)
        #expect(SymphonyOrchestratorRuntimeTestSupport.index(of: "workspace.cleanup.TERM-1", in: events) ?? -1 < SymphonyOrchestratorRuntimeTestSupport.index(of: "scheduler.schedule.0", in: events) ?? .max)
        #expect(SymphonyOrchestratorRuntimeTestSupport.index(of: "scheduler.schedule.0", in: events) ?? -1 < SymphonyOrchestratorRuntimeTestSupport.index(of: "preflight.load", in: events) ?? .max)
        #expect(SymphonyOrchestratorRuntimeTestSupport.index(of: "preflight.validate", in: events) ?? -1 < SymphonyOrchestratorRuntimeTestSupport.index(of: "tracker.fetchCandidates", in: events) ?? .max)
        #expect(SymphonyOrchestratorRuntimeTestSupport.index(of: "tracker.fetchCandidates", in: events) ?? -1 < SymphonyOrchestratorRuntimeTestSupport.index(of: "worker.start.ABC-1", in: events) ?? .max)
    }

    @Test
    func startupCleanupFetchFailureStillSchedulesImmediateTickAndLogsWarning() async {
        let tracker = RuntimeIssueTrackerReadSpy(
            fetchIssuesResponses: [
                .failure(SymphonyIssueTrackerInfrastructureError.linearAPIRequest(details: "offline"))
            ],
            candidateResponses: [
                .success([
                    SymphonyOrchestratorRuntimeTestSupport.makeIssue(
                        id: "issue-1",
                        identifier: "ABC-1",
                        priority: 1,
                        state: "Todo",
                        stateType: "unstarted"
                    )
                ])
            ]
        )
        let scheduler = RuntimeSchedulerSpy()
        let workerExecution = RuntimeWorkerExecutionSpy()
        let logSink = OrchestratorLogSinkSpy()
        let service = SymphonyOrchestratorRuntimeTestSupport.makeService(
            tracker: tracker,
            scheduler: scheduler,
            workerExecution: workerExecution,
            logSink: logSink
        )

        await service.start(
            workspaceLocator: SymphonyOrchestratorRuntimeTestSupport.makeWorkspaceLocator(),
            initialConfiguration: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration()
        )

        #expect(scheduler.activeDelays() == [0])
        #expect(logSink.events().contains { $0.kind == .warning && $0.outcome == "startup_cleanup_fetch_failed" })

        await scheduler.runNext()

        #expect(workerExecution.startedIssueIdentifiers() == ["ABC-1"])
    }
}
