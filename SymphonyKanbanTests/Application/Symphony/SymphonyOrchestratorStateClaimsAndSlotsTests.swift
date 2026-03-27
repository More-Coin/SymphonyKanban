import Foundation
import Testing
@testable import SymphonyKanban

struct SymphonyOrchestratorStateClaimsAndSlotsTests {
    private let selectDispatchIssuesUseCase = SelectSymphonyDispatchIssuesUseCase()
    private let runtimeStateTransition = SymphonyRuntimeStateTransition()

    @Test
    func claimAndReleaseUpdateClaimedAndBookkeepingState() {
        let initialState = SymphonyOrchestratorStateTestSupport.makeState(
            running: [
                "issue-1": SymphonyOrchestratorStateTestSupport.makeRunningEntry(
                    issue: SymphonyOrchestratorStateTestSupport.makeIssue(
                        id: "issue-1",
                        identifier: "ABC-1",
                        priority: 1,
                        state: "Todo",
                        stateType: "unstarted"
                    )
                )
            ],
            claimed: ["issue-1"],
            retryAttempts: [
                "issue-1": SymphonyOrchestratorStateTestSupport.makeRetryEntry(
                    issueID: "issue-1",
                    identifier: "ABC-1",
                    attempt: 2,
                    dueAtMs: 500,
                    timerHandle: "timer-1",
                    error: "stalled"
                )
            ]
        )

        let claimedState = runtimeStateTransition.claim(issueID: "issue-2", in: initialState)
        let releasedState = runtimeStateTransition.release(issueID: "issue-1", in: claimedState)

        #expect(claimedState.claimed == ["issue-1", "issue-2"])
        #expect(releasedState.claimed == ["issue-2"])
        #expect(releasedState.running["issue-1"] == nil)
        #expect(releasedState.retryAttempts["issue-1"] == nil)
    }

    @Test
    func eligibleIssuesForDispatchFiltersClaimedBlockedAndFullStatesBeforeSorting() {
        let serviceConfig = SymphonyOrchestratorStateTestSupport.makeServiceConfig(
            maxConcurrentAgents: 4,
            maxConcurrentAgentsByState: ["todo": 1],
            terminalStateTypes: ["completed", "canceled"]
        )
        let runningTodo = SymphonyOrchestratorStateTestSupport.makeIssue(
            id: "issue-running",
            identifier: "ABC-0",
            priority: 1,
            state: "Todo",
            stateType: "unstarted"
        )
        let blockedTodo = SymphonyOrchestratorStateTestSupport.makeIssue(
            id: "issue-blocked",
            identifier: "ABC-1",
            priority: 1,
            state: "Todo",
            stateType: "unstarted",
            blockedBy: [.init(id: "blocker-1", identifier: "ABC-B1", state: "In Progress", stateType: "started")]
        )
        let claimedInProgress = SymphonyOrchestratorStateTestSupport.makeIssue(
            id: "issue-claimed",
            identifier: "ABC-2",
            priority: 1,
            state: "In Progress",
            stateType: "started"
        )
        let readyInProgressOldest = SymphonyOrchestratorStateTestSupport.makeIssue(
            id: "issue-ready-1",
            identifier: "ABC-3",
            priority: 2,
            state: "In Progress",
            stateType: "started",
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let readyInProgressNewest = SymphonyOrchestratorStateTestSupport.makeIssue(
            id: "issue-ready-2",
            identifier: "ABC-4",
            priority: 2,
            state: "In Progress",
            stateType: "started",
            createdAt: Date(timeIntervalSince1970: 200)
        )
        let nullPriority = SymphonyOrchestratorStateTestSupport.makeIssue(
            id: "issue-ready-3",
            identifier: "ABC-5",
            priority: nil,
            state: "In Progress",
            stateType: "started",
            createdAt: Date(timeIntervalSince1970: 50)
        )
        let state = SymphonyOrchestratorStateTestSupport.makeState(
            running: ["issue-running": SymphonyOrchestratorStateTestSupport.makeRunningEntry(issue: runningTodo)],
            claimed: ["issue-claimed"]
        )

        let eligible = selectDispatchIssuesUseCase.selectEligibleIssues(
            from: [nullPriority, readyInProgressNewest, blockedTodo, claimedInProgress, readyInProgressOldest],
            in: state,
            using: serviceConfig
        ).issues

        #expect(eligible.map(\.id) == ["issue-ready-1", "issue-ready-2", "issue-ready-3"])
    }

    @Test
    func availableSlotsUsesLowercaseStateOverridesAndGlobalFallback() {
        let serviceConfig = SymphonyOrchestratorStateTestSupport.makeServiceConfig(
            maxConcurrentAgents: 5,
            maxConcurrentAgentsByState: ["todo": 2]
        )
        let state = SymphonyOrchestratorStateTestSupport.makeState(
            running: [
                "issue-1": SymphonyOrchestratorStateTestSupport.makeRunningEntry(
                    issue: SymphonyOrchestratorStateTestSupport.makeIssue(
                        id: "issue-1",
                        identifier: "ABC-1",
                        priority: 1,
                        state: "Todo",
                        stateType: "unstarted"
                    )
                ),
                "issue-2": SymphonyOrchestratorStateTestSupport.makeRunningEntry(
                    issue: SymphonyOrchestratorStateTestSupport.makeIssue(
                        id: "issue-2",
                        identifier: "ABC-2",
                        priority: 1,
                        state: "In Progress",
                        stateType: "started"
                    )
                )
            ],
            claimed: ["issue-claimed"]
        )

        #expect(state.availableSlots(forState: "TODO", using: serviceConfig) == 1)
        #expect(state.availableSlots(forState: "In Progress", using: serviceConfig) == 4)
        #expect(state.availableSlots(forState: " TODO ", using: serviceConfig) == 1)
        #expect(state.canClaim(issueID: "issue-claimed") == false)
        #expect(state.canClaim(issueID: "issue-3"))
        #expect(state.hasAvailableSlot(
            for: SymphonyOrchestratorStateTestSupport.makeIssue(
                id: "issue-3",
                identifier: "ABC-3",
                priority: 1,
                state: "In Progress",
                stateType: "started"
            ),
            using: serviceConfig
        ))
    }
}
