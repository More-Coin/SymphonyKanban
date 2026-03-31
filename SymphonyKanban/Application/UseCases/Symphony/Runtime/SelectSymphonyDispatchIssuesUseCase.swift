
public struct SelectSymphonyDispatchIssuesUseCase {
    private let eligibilityPolicy: any SymphonyIssueDispatchEligibilityPolicyProtocol
    private let orderingPolicy: any SymphonyIssueDispatchOrderingPolicyProtocol

    public init(
        eligibilityPolicy: any SymphonyIssueDispatchEligibilityPolicyProtocol = SymphonyIssueDispatchEligibilityPolicy(),
        orderingPolicy: any SymphonyIssueDispatchOrderingPolicyProtocol = SymphonyIssueDispatchOrderingPolicy()
    ) {
        self.eligibilityPolicy = eligibilityPolicy
        self.orderingPolicy = orderingPolicy
    }

    public func selectEligibleIssues<
        WorkerHandle: Equatable & Sendable,
        MonitorHandle: Equatable & Sendable,
        TimerHandle: Equatable & Sendable
    >(
        from issues: [SymphonyIssue],
        in state: SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle>,
        using serviceConfig: SymphonyServiceConfigContract
    ) -> SymphonyIssueCollectionContract {
        let eligibleIssues = issues.filter { issue in
            state.canClaim(issueID: issue.id)
                && eligibilityPolicy.passesBlockerRule(
                    issue: issue,
                    terminalStateTypes: serviceConfig.tracker.terminalStateTypes
                )
                && state.hasAvailableSlot(for: issue, using: serviceConfig)
        }

        return SymphonyIssueCollectionContract(
            issues: orderingPolicy.ordered(eligibleIssues)
        )
    }
}
