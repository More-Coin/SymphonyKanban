public protocol SymphonyIssueDispatchEligibilityPolicyProtocol {
    func passesBlockerRule(
        issue: SymphonyIssue,
        terminalStateTypes: [String]
    ) -> Bool
}
