public protocol SymphonyIssueDispatchEligibilityPolicyProtocol {
    func passesBlockerRule(
        issue: SymphonyIssue,
        terminalStates: [String]
    ) -> Bool
}
