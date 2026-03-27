
public struct SymphonyIssueCollectionContract: Equatable, Sendable {
    public let issues: [SymphonyIssue]

    public init(issues: [SymphonyIssue]) {
        self.issues = issues
    }
}
