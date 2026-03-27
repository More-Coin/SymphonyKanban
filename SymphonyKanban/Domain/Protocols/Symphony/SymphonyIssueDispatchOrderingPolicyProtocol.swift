public protocol SymphonyIssueDispatchOrderingPolicyProtocol {
    func ordered(_ issues: [SymphonyIssue]) -> [SymphonyIssue]
}
