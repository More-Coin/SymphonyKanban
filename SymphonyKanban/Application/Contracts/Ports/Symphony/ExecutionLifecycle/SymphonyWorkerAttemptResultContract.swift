import Foundation

public struct SymphonyWorkerAttemptResultContract: Equatable, Sendable {
    public let issueID: String
    public let issueIdentifier: String
    public let attempt: Int?
    public let workspacePath: String?
    public let startedAt: Date
    public let completedAt: Date
    public let turnCount: Int
    public let terminalReason: SymphonyWorkerAttemptTerminalReasonContract
    public let refreshedIssue: SymphonyIssue?
    public let liveSession: SymphonyLiveSessionContract?
    public let completion: SymphonyRunAttemptCompletionContract?
    public let error: String?

    public init(
        issueID: String,
        issueIdentifier: String,
        attempt: Int?,
        workspacePath: String?,
        startedAt: Date,
        completedAt: Date,
        turnCount: Int,
        terminalReason: SymphonyWorkerAttemptTerminalReasonContract,
        refreshedIssue: SymphonyIssue?,
        liveSession: SymphonyLiveSessionContract?,
        completion: SymphonyRunAttemptCompletionContract?,
        error: String?
    ) {
        self.issueID = issueID
        self.issueIdentifier = issueIdentifier
        self.attempt = attempt
        self.workspacePath = workspacePath
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.turnCount = turnCount
        self.terminalReason = terminalReason
        self.refreshedIssue = refreshedIssue
        self.liveSession = liveSession
        self.completion = completion
        self.error = error
    }
}
