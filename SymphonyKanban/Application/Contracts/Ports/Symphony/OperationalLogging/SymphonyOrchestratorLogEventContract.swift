import Foundation

public struct SymphonyOrchestratorLogEventContract: Equatable, Sendable {
    public enum Kind: String, Equatable, Sendable {
        case startup = "startup"
        case tick = "tick"
        case dispatch = "dispatch"
        case retry = "retry"
        case reconciliation = "reconciliation"
        case startupCleanup = "startup_cleanup"
        case warning = "warning"
    }

    public let kind: Kind
    public let timestamp: Date
    public let outcome: String
    public let issueID: String?
    public let issueIdentifier: String?
    public let sessionID: String?
    public let message: String?
    public let details: [String: String]

    public init(
        kind: Kind,
        timestamp: Date,
        outcome: String,
        issueID: String? = nil,
        issueIdentifier: String? = nil,
        sessionID: String? = nil,
        message: String? = nil,
        details: [String: String] = [:]
    ) {
        self.kind = kind
        self.timestamp = timestamp
        self.outcome = outcome
        self.issueID = issueID
        self.issueIdentifier = issueIdentifier
        self.sessionID = sessionID
        self.message = message
        self.details = details
    }
}
