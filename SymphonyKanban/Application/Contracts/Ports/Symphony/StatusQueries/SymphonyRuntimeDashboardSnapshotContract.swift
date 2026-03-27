import Foundation

public struct SymphonyRuntimeDashboardSnapshotContract: Equatable, Sendable {
    public struct Counts: Equatable, Sendable {
        public let runningCount: Int
        public let retryingCount: Int
        public let claimedCount: Int
        public let completedCount: Int

        public init(
            runningCount: Int,
            retryingCount: Int,
            claimedCount: Int,
            completedCount: Int
        ) {
            self.runningCount = runningCount
            self.retryingCount = retryingCount
            self.claimedCount = claimedCount
            self.completedCount = completedCount
        }
    }

    public struct RunningRow: Equatable, Sendable {
        public let issueID: String
        public let issueIdentifier: String
        public let state: String
        public let sessionID: String?
        public let turnCount: Int
        public let retryAttempt: Int?
        public let lastEvent: String?
        public let lastMessage: String?
        public let startedAt: Date
        public let lastEventAt: Date?
        public let tokens: SymphonyCodexUsageSnapshotContract

        public init(
            issueID: String,
            issueIdentifier: String,
            state: String,
            sessionID: String?,
            turnCount: Int,
            retryAttempt: Int?,
            lastEvent: String?,
            lastMessage: String?,
            startedAt: Date,
            lastEventAt: Date?,
            tokens: SymphonyCodexUsageSnapshotContract
        ) {
            self.issueID = issueID
            self.issueIdentifier = issueIdentifier
            self.state = state
            self.sessionID = sessionID
            self.turnCount = turnCount
            self.retryAttempt = retryAttempt
            self.lastEvent = lastEvent
            self.lastMessage = lastMessage
            self.startedAt = startedAt
            self.lastEventAt = lastEventAt
            self.tokens = tokens
        }
    }

    public struct RetryRow: Equatable, Sendable {
        public let issueID: String
        public let issueIdentifier: String
        public let attempt: Int
        public let dueAt: Date
        public let error: String?

        public init(
            issueID: String,
            issueIdentifier: String,
            attempt: Int,
            dueAt: Date,
            error: String?
        ) {
            self.issueID = issueID
            self.issueIdentifier = issueIdentifier
            self.attempt = attempt
            self.dueAt = dueAt
            self.error = error
        }
    }

    public let generatedAt: Date
    public let outcome: String?
    public let counts: Counts
    public let running: [RunningRow]
    public let retrying: [RetryRow]
    public let codexTotals: SymphonyCodexTotalsContract
    public let rateLimits: SymphonyCodexRateLimitSnapshotContract?
    public let tracked: [String: SymphonyConfigValueContract]

    public init(
        generatedAt: Date,
        outcome: String?,
        counts: Counts,
        running: [RunningRow],
        retrying: [RetryRow],
        codexTotals: SymphonyCodexTotalsContract,
        rateLimits: SymphonyCodexRateLimitSnapshotContract?,
        tracked: [String: SymphonyConfigValueContract] = [:]
    ) {
        self.generatedAt = generatedAt
        self.outcome = outcome
        self.counts = counts
        self.running = running
        self.retrying = retrying
        self.codexTotals = codexTotals
        self.rateLimits = rateLimits
        self.tracked = tracked
    }
}
