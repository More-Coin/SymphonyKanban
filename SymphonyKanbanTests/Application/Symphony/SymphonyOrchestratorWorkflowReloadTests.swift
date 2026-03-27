import Foundation
import Testing
@testable import SymphonyKanban

@Suite(.serialized)
struct SymphonyOrchestratorWorkflowReloadTests {
    @Test
    func watchTriggeredReloadReplacesPendingPollHandlePromptly() async throws {
        let scheduler = RuntimeSchedulerSpy()
        let reloadMonitor = RuntimeWorkflowReloadMonitorSpy()
        let logSink = OrchestratorLogSinkSpy()
        let reloadedConfiguration = SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration(
            pollingIntervalMs: 5_000
        )
        let workflowLoader = WorkflowLoaderSpy(definition: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration().workflowDefinition)
        let configResolver = ConfigResolverSpy(serviceConfig: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration().serviceConfig)
        let service = SymphonyOrchestratorRuntimeTestSupport.makeService(
            scheduler: scheduler,
            logSink: logSink,
            workflowLoader: workflowLoader,
            configResolver: configResolver,
            reloadMonitor: reloadMonitor
        )

        await service.start(
            command: SymphonyOrchestratorRuntimeTestSupport.makeStartupCommand(),
            initialConfiguration: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration()
        )

        await scheduler.runNext()
        let stalePollHandle = try #require(scheduler.handle(forDelay: 30_000))

        workflowLoader.setDefinition(reloadedConfiguration.workflowDefinition)
        configResolver.setServiceConfig(reloadedConfiguration.serviceConfig)
        await reloadMonitor.fireChange()

        let state = await service.snapshotState()

        #expect(reloadMonitor.monitoredPaths() == ["/tmp/WORKFLOW.md"])
        #expect(scheduler.wasCancelled(handle: stalePollHandle))
        #expect(scheduler.activeDelays() == [5_000])
        #expect(state.pollIntervalMs == 5_000)
        #expect(logSink.events().contains {
            $0.kind == .tick && $0.outcome == "workflow_reloaded" && $0.details["pending_poll_replaced"] == "true"
        })
    }

    @Test
    func defensivePerTickRevalidationPicksUpChangedWorkflowWhenWatchEventIsMissed() async throws {
        let reviewIssue = SymphonyOrchestratorRuntimeTestSupport.makeIssue(id: "issue-2", identifier: "ABC-2", priority: 1, state: "Review")
        let tracker = RuntimeIssueTrackerReadSpy(
            candidateResponses: [
                .success([]),
                .success([reviewIssue])
            ]
        )
        let scheduler = RuntimeSchedulerSpy()
        let workerExecution = RuntimeWorkerExecutionSpy()
        let updatedConfiguration = SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration(
            activeStates: ["Todo", "Review"],
            promptTemplate: "Reloaded prompt"
        )
        let workflowLoader = WorkflowLoaderSpy(definition: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration().workflowDefinition)
        let configResolver = ConfigResolverSpy(serviceConfig: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration().serviceConfig)
        let service = SymphonyOrchestratorRuntimeTestSupport.makeService(
            tracker: tracker,
            scheduler: scheduler,
            workerExecution: workerExecution,
            workflowLoader: workflowLoader,
            configResolver: configResolver
        )

        await service.start(
            command: SymphonyOrchestratorRuntimeTestSupport.makeStartupCommand(),
            initialConfiguration: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration()
        )
        await scheduler.runNext()

        workflowLoader.setDefinition(updatedConfiguration.workflowDefinition)
        configResolver.setServiceConfig(updatedConfiguration.serviceConfig)

        let nextPollHandle = try #require(scheduler.handle(forDelay: 30_000))
        await scheduler.run(handle: nextPollHandle)

        let dispatchedRequest = try #require(workerExecution.request(forIssueIdentifier: "ABC-2"))
        let state = await service.snapshotState()

        #expect(workerExecution.startedIssueIdentifiers() == ["ABC-2"])
        #expect(dispatchedRequest.workflowConfiguration.workflowDefinition.promptTemplate == "Reloaded prompt")
        #expect(Array(state.running.keys) == ["issue-2"])
    }

    @Test
    func invalidReloadKeepsLastKnownGoodConfigAndSkipsDispatchWhileReconciliationContinues() async throws {
        let activeIssue = SymphonyOrchestratorRuntimeTestSupport.makeIssue(id: "issue-1", identifier: "ABC-1", priority: 1, state: "Todo")
        let tracker = RuntimeIssueTrackerReadSpy(
            candidateResponses: [
                .success([activeIssue]),
                .success([SymphonyOrchestratorRuntimeTestSupport.makeIssue(id: "issue-2", identifier: "ABC-2", priority: 1, state: "Todo")])
            ],
            issueStateResponses: [
                .success([SymphonyOrchestratorRuntimeTestSupport.makeIssue(id: "issue-1", identifier: "ABC-1", priority: 1, state: "Todo")])
            ]
        )
        let scheduler = RuntimeSchedulerSpy()
        let workerExecution = RuntimeWorkerExecutionSpy()
        let reloadMonitor = RuntimeWorkflowReloadMonitorSpy()
        let logSink = OrchestratorLogSinkSpy()
        let validator = StartupValidatorSpy()
        let reloadedConfiguration = SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration(pollingIntervalMs: 5_000)
        let workflowLoader = WorkflowLoaderSpy(definition: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration().workflowDefinition)
        let configResolver = ConfigResolverSpy(serviceConfig: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration().serviceConfig)
        let service = SymphonyOrchestratorRuntimeTestSupport.makeService(
            tracker: tracker,
            scheduler: scheduler,
            workerExecution: workerExecution,
            logSink: logSink,
            workflowLoader: workflowLoader,
            configResolver: configResolver,
            validator: validator,
            reloadMonitor: reloadMonitor
        )

        await service.start(
            command: SymphonyOrchestratorRuntimeTestSupport.makeStartupCommand(),
            initialConfiguration: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration()
        )
        await scheduler.runNext()
        let originalPollHandle = try #require(scheduler.handle(forDelay: 30_000))

        workflowLoader.setDefinition(reloadedConfiguration.workflowDefinition)
        configResolver.setServiceConfig(reloadedConfiguration.serviceConfig)
        validator.setError(
            SymphonyStartupApplicationError.trackerAuthNotConnected(trackerKind: "linear")
        )
        await reloadMonitor.fireChange()

        let retainedState = await service.snapshotState()
        #expect(retainedState.pollIntervalMs == 30_000)
        #expect(!scheduler.wasCancelled(handle: originalPollHandle))
        #expect(scheduler.activeDelays() == [30_000])

        await scheduler.run(handle: originalPollHandle)

        let finalState = await service.snapshotState()

        #expect(Array(finalState.running.keys) == ["issue-1"])
        #expect(workerExecution.startedIssueIdentifiers() == ["ABC-1"])
        #expect(logSink.events().contains {
            $0.kind == .warning && $0.outcome == "workflow_reload_blocked"
        })
        #expect(logSink.events().contains {
            $0.kind == .reconciliation && $0.outcome == "active_updated" && $0.issueID == "issue-1"
        })
        #expect(logSink.events().contains {
            $0.kind == .warning && $0.outcome == "dispatch_preflight_blocked"
        })
    }

    @Test
    func reloadAppliesToFutureWorkerLaunchesOnly() async throws {
        let firstIssue = SymphonyOrchestratorRuntimeTestSupport.makeIssue(id: "issue-1", identifier: "ABC-1", priority: 1, state: "Todo")
        let secondIssue = SymphonyOrchestratorRuntimeTestSupport.makeIssue(id: "issue-2", identifier: "ABC-2", priority: 1, state: "Todo")
        let tracker = RuntimeIssueTrackerReadSpy(
            candidateResponses: [
                .success([firstIssue]),
                .success([secondIssue])
            ]
        )
        let scheduler = RuntimeSchedulerSpy()
        let workerExecution = RuntimeWorkerExecutionSpy()
        let reloadMonitor = RuntimeWorkflowReloadMonitorSpy()
        let updatedConfiguration = SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration(promptTemplate: "Reloaded prompt")
        let workflowLoader = WorkflowLoaderSpy(definition: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration().workflowDefinition)
        let configResolver = ConfigResolverSpy(serviceConfig: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration().serviceConfig)
        let service = SymphonyOrchestratorRuntimeTestSupport.makeService(
            tracker: tracker,
            scheduler: scheduler,
            workerExecution: workerExecution,
            workflowLoader: workflowLoader,
            configResolver: configResolver,
            reloadMonitor: reloadMonitor
        )

        await service.start(
            command: SymphonyOrchestratorRuntimeTestSupport.makeStartupCommand(),
            initialConfiguration: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration()
        )
        await scheduler.runNext()

        workflowLoader.setDefinition(updatedConfiguration.workflowDefinition)
        configResolver.setServiceConfig(updatedConfiguration.serviceConfig)
        await reloadMonitor.fireChange()

        let firstHandle = try #require(workerExecution.handle(forIssueIdentifier: "ABC-1"))
        await workerExecution.complete(
            handle: firstHandle.workerHandle,
            result: SymphonyOrchestratorRuntimeTestSupport.makeWorkerResult(
                issueID: "issue-1",
                issueIdentifier: "ABC-1",
                terminalReason: .succeeded,
                refreshedIssue: SymphonyOrchestratorRuntimeTestSupport.makeIssue(id: "issue-1", identifier: "ABC-1", priority: 1, state: "Done")
            )
        )

        let nextPollHandle = try #require(scheduler.handle(forDelay: 30_000))
        await scheduler.run(handle: nextPollHandle)

        let firstRequest = try #require(workerExecution.request(forIssueIdentifier: "ABC-1"))
        let secondRequest = try #require(workerExecution.request(forIssueIdentifier: "ABC-2"))

        #expect(firstRequest.workflowConfiguration.workflowDefinition.promptTemplate == "Issue: {{ issue.identifier }}")
        #expect(secondRequest.workflowConfiguration.workflowDefinition.promptTemplate == "Reloaded prompt")
    }
}
