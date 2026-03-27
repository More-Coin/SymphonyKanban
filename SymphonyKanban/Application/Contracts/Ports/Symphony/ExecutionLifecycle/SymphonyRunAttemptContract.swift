import Foundation

public struct SymphonyRunAttemptContract: Equatable, Sendable {
    public let issueID: String
    public let issueIdentifier: String
    public let attempt: Int?
    public let workspacePath: String
    public let startedAt: Date
    public let status: String
    public let error: String?

    public init(
        issueID: String,
        issueIdentifier: String,
        attempt: Int?,
        workspacePath: String,
        startedAt: Date,
        status: String,
        error: String?
    ) {
        self.issueID = issueID
        self.issueIdentifier = issueIdentifier
        self.attempt = attempt
        self.workspacePath = workspacePath
        self.startedAt = startedAt
        self.status = status
        self.error = error
    }
}
