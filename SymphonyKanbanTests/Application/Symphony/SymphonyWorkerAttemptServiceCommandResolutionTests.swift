import Testing
@testable import SymphonyKanban

@Suite(.serialized)
struct SymphonyWorkerAttemptServiceCommandResolutionTests {
    @Test
    func workerAttemptResolvesCodexCommandOnceAndPassesResolvedStartupCommand() async {
        let runner = WorkerAttemptRunnerSpy(startSteps: [
            .immediate(result: SymphonyWorkerAttemptTestSupport.makeCompletedTurnResult(
                threadID: "thread-1",
                turnID: "turn-1"
            ))
        ])
        let codexCommandResolver = WorkerAttemptCodexCommandResolverSpy(
            resolution: SymphonyCodexCommandResolutionContract(
                configuredCommand: "codex app-server",
                effectiveCommand: "/opt/homebrew/bin/codex app-server --listen stdio://",
                executableName: "codex",
                executablePath: "/opt/homebrew/bin/codex",
                detailMessage: nil
            )
        )
        let service = SymphonyWorkerAttemptTestSupport.makeService(
            runner: runner,
            codexCommandResolverPort: codexCommandResolver
        )

        _ = await service.execute(SymphonyWorkerAttemptTestSupport.makeRequest(maxTurns: 1))

        #expect(codexCommandResolver.calls() == 1)
        #expect(codexCommandResolver.recordedCurrentWorkingDirectoryPaths == ["/tmp/symphony_workspaces/ABC-123"])
        #expect(codexCommandResolver.recordedExplicitWorkflowPaths == ["/tmp/WORKFLOW.md"])
        #expect(runner.startRequests().count == 1)
        #expect(runner.startRequests().first?.command == "/opt/homebrew/bin/codex app-server --listen stdio://")
    }
}
