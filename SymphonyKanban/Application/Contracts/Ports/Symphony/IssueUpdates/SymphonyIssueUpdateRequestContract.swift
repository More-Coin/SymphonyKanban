public struct SymphonyIssueStateChangeContract: Equatable, Sendable {
    public let targetStateType: String

    public init(targetStateType: String) {
        self.targetStateType = targetStateType
    }
}

public struct SymphonyIssueUpdateRequestContract: Equatable, Sendable {
    public let issueIdentifier: String
    public let stateChange: SymphonyIssueStateChangeContract?

    public init(
        issueIdentifier: String,
        stateChange: SymphonyIssueStateChangeContract?
    ) {
        self.issueIdentifier = issueIdentifier
        self.stateChange = stateChange
    }
}
