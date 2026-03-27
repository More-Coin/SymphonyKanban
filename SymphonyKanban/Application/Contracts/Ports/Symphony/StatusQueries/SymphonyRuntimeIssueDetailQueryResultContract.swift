public struct SymphonyRuntimeIssueDetailQueryResultContract: Equatable, Sendable {
    public let issueIdentifier: String
    public let snapshot: SymphonyRuntimeIssueDetailSnapshotContract?
    public let isEmpty: Bool
    public let hasRunningDetail: Bool
    public let hasRetryDetail: Bool
    public let hasRecentEvents: Bool
    public let hasLastError: Bool
    public let hasLogs: Bool

    public init(
        issueIdentifier: String,
        snapshot: SymphonyRuntimeIssueDetailSnapshotContract?,
        isEmpty: Bool,
        hasRunningDetail: Bool,
        hasRetryDetail: Bool,
        hasRecentEvents: Bool,
        hasLastError: Bool,
        hasLogs: Bool
    ) {
        self.issueIdentifier = issueIdentifier
        self.snapshot = snapshot
        self.isEmpty = isEmpty
        self.hasRunningDetail = hasRunningDetail
        self.hasRetryDetail = hasRetryDetail
        self.hasRecentEvents = hasRecentEvents
        self.hasLastError = hasLastError
        self.hasLogs = hasLogs
    }
}
