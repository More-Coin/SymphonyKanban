import Foundation

public struct SymphonyWorkerAttemptLogEventContract: Equatable, Sendable {
    public enum Kind: String, Equatable, Sendable {
        case attemptStarted = "attempt_started"
        case attemptCompleted = "attempt_completed"
        case startupFailure = "startup_failure"
        case timeout = "timeout"
        case cancellation = "cancellation"
        case abnormalExit = "abnormal_exit"
        case policyFailure = "policy_failure"
        case unsupportedToolEvent = "unsupported_tool_event"
        case userInputRequired = "user_input_required"
    }

    public let kind: Kind
    public let timestamp: Date
    public let issueID: String
    public let issueIdentifier: String
    public let attempt: Int?
    public let turnCount: Int
    public let workspacePath: String?
    public let sessionID: String?
    public let threadID: String?
    public let turnID: String?
    public let terminalReason: SymphonyWorkerAttemptTerminalReasonContract?
    public let message: String?

    public init(
        kind: Kind,
        timestamp: Date,
        issueID: String,
        issueIdentifier: String,
        attempt: Int?,
        turnCount: Int,
        workspacePath: String? = nil,
        sessionID: String? = nil,
        threadID: String? = nil,
        turnID: String? = nil,
        terminalReason: SymphonyWorkerAttemptTerminalReasonContract? = nil,
        message: String? = nil
    ) {
        self.kind = kind
        self.timestamp = timestamp
        self.issueID = issueID
        self.issueIdentifier = issueIdentifier
        self.attempt = attempt
        self.turnCount = turnCount
        self.workspacePath = workspacePath
        self.sessionID = sessionID
        self.threadID = threadID
        self.turnID = turnID
        self.terminalReason = terminalReason
        self.message = message
    }
}
