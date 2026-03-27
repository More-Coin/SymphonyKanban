import Foundation

public struct SymphonyRuntimeIssueDetailSnapshotContract: Equatable, Sendable {
    public struct IssueSummary: Equatable, Sendable {
        public let issueID: String
        public let issueIdentifier: String
        public let title: String
        public let description: String?
        public let priority: Int?
        public let state: String
        public let branchName: String?
        public let url: String?
        public let labels: [String]
        public let createdAt: Date?
        public let updatedAt: Date?

        public init(
            issueID: String,
            issueIdentifier: String,
            title: String,
            description: String?,
            priority: Int?,
            state: String,
            branchName: String?,
            url: String?,
            labels: [String],
            createdAt: Date?,
            updatedAt: Date?
        ) {
            self.issueID = issueID
            self.issueIdentifier = issueIdentifier
            self.title = title
            self.description = description
            self.priority = priority
            self.state = state
            self.branchName = branchName
            self.url = url
            self.labels = labels
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    public struct Workspace: Equatable, Sendable {
        public let path: String

        public init(path: String) {
            self.path = path
        }
    }

    public struct Attempts: Equatable, Sendable {
        public let restartCount: Int
        public let currentRetryAttempt: Int?

        public init(
            restartCount: Int,
            currentRetryAttempt: Int?
        ) {
            self.restartCount = restartCount
            self.currentRetryAttempt = currentRetryAttempt
        }
    }

    public struct RunningDetail: Equatable, Sendable {
        public let sessionID: String
        public let threadID: String
        public let turnID: String
        public let codexAppServerPID: String?
        public let turnCount: Int
        public let state: String
        public let startedAt: Date
        public let lastEvent: String?
        public let lastMessage: String?
        public let lastEventAt: Date?
        public let tokens: SymphonyCodexUsageSnapshotContract

        public init(
            sessionID: String,
            threadID: String,
            turnID: String,
            codexAppServerPID: String?,
            turnCount: Int,
            state: String,
            startedAt: Date,
            lastEvent: String?,
            lastMessage: String?,
            lastEventAt: Date?,
            tokens: SymphonyCodexUsageSnapshotContract
        ) {
            self.sessionID = sessionID
            self.threadID = threadID
            self.turnID = turnID
            self.codexAppServerPID = codexAppServerPID
            self.turnCount = turnCount
            self.state = state
            self.startedAt = startedAt
            self.lastEvent = lastEvent
            self.lastMessage = lastMessage
            self.lastEventAt = lastEventAt
            self.tokens = tokens
        }
    }

    public struct RetryDetail: Equatable, Sendable {
        public let attempt: Int
        public let dueAt: Date
        public let error: String?

        public init(
            attempt: Int,
            dueAt: Date,
            error: String?
        ) {
            self.attempt = attempt
            self.dueAt = dueAt
            self.error = error
        }
    }

    public struct LogLink: Equatable, Sendable {
        public let label: String
        public let path: String
        public let url: String?

        public init(
            label: String,
            path: String,
            url: String?
        ) {
            self.label = label
            self.path = path
            self.url = url
        }
    }

    public struct LogCollection: Equatable, Sendable {
        public let codexSessionLogs: [LogLink]

        public init(codexSessionLogs: [LogLink]) {
            self.codexSessionLogs = codexSessionLogs
        }
    }

    public struct RecentEvent: Equatable, Sendable {
        public let at: Date
        public let event: String
        public let message: String?
        public let details: [String: SymphonyConfigValueContract]

        public init(
            at: Date,
            event: String,
            message: String?,
            details: [String: SymphonyConfigValueContract] = [:]
        ) {
            self.at = at
            self.event = event
            self.message = message
            self.details = details
        }
    }

    public struct ErrorSnapshot: Equatable, Sendable {
        public let code: String?
        public let message: String
        public let occurredAt: Date?
        public let details: [String: SymphonyConfigValueContract]

        public init(
            code: String?,
            message: String,
            occurredAt: Date?,
            details: [String: SymphonyConfigValueContract] = [:]
        ) {
            self.code = code
            self.message = message
            self.occurredAt = occurredAt
            self.details = details
        }
    }

    public let generatedAt: Date
    public let issue: IssueSummary
    public let status: String
    public let workspace: Workspace?
    public let attempts: Attempts
    public let running: RunningDetail?
    public let retry: RetryDetail?
    public let logs: LogCollection
    public let recentEvents: [RecentEvent]
    public let lastError: ErrorSnapshot?
    public let tracked: [String: SymphonyConfigValueContract]

    public init(
        generatedAt: Date,
        issue: IssueSummary,
        status: String,
        workspace: Workspace?,
        attempts: Attempts,
        running: RunningDetail?,
        retry: RetryDetail?,
        logs: LogCollection,
        recentEvents: [RecentEvent],
        lastError: ErrorSnapshot?,
        tracked: [String: SymphonyConfigValueContract] = [:]
    ) {
        self.generatedAt = generatedAt
        self.issue = issue
        self.status = status
        self.workspace = workspace
        self.attempts = attempts
        self.running = running
        self.retry = retry
        self.logs = logs
        self.recentEvents = recentEvents
        self.lastError = lastError
        self.tracked = tracked
    }
}
