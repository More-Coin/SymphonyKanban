import Foundation

public struct SymphonyRuntimeStatusRunningRowContract: Equatable, Sendable {
    public let issueID: String
    public let issueIdentifier: String
    public let state: String
    public let sessionID: String?
    public let turnCount: Int?
    public let retryAttempt: Int?
    public let startedAt: Date

    public init(
        issueID: String,
        issueIdentifier: String,
        state: String,
        sessionID: String?,
        turnCount: Int?,
        retryAttempt: Int?,
        startedAt: Date
    ) {
        self.issueID = issueID
        self.issueIdentifier = issueIdentifier
        self.state = state
        self.sessionID = sessionID
        self.turnCount = turnCount
        self.retryAttempt = retryAttempt
        self.startedAt = startedAt
    }
}
