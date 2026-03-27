public struct SymphonyRuntimeStatusRetryRowContract: Equatable, Sendable {
    public let issueID: String
    public let issueIdentifier: String
    public let attempt: Int
    public let dueAtMs: Int64
    public let error: String?

    public init(
        issueID: String,
        issueIdentifier: String,
        attempt: Int,
        dueAtMs: Int64,
        error: String?
    ) {
        self.issueID = issueID
        self.issueIdentifier = issueIdentifier
        self.attempt = attempt
        self.dueAtMs = dueAtMs
        self.error = error
    }
}
