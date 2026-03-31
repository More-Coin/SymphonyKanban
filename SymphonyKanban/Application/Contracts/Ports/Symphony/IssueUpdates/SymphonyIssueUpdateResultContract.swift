public struct SymphonyIssueUpdateResultContract: Equatable, Sendable {
    public let issueID: String
    public let issueIdentifier: String
    public let appliedStateID: String?

    public init(
        issueID: String,
        issueIdentifier: String,
        appliedStateID: String?
    ) {
        self.issueID = issueID
        self.issueIdentifier = issueIdentifier
        self.appliedStateID = appliedStateID
    }
}
