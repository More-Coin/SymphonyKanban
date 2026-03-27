import Foundation

public struct SymphonyCodexRuntimeEventContract: Equatable, Sendable {
    public enum Kind: String, Equatable, Sendable {
        case sessionStarted = "session_started"
        case startupFailed = "startup_failed"
        case turnCompleted = "turn_completed"
        case turnFailed = "turn_failed"
        case turnCancelled = "turn_cancelled"
        case turnEndedWithError = "turn_ended_with_error"
        case turnInputRequired = "turn_input_required"
        case approvalAutoApproved = "approval_auto_approved"
        case unsupportedToolCall = "unsupported_tool_call"
        case notification = "notification"
        case otherMessage = "other_message"
        case malformed = "malformed"
    }

    public let kind: Kind
    public let timestamp: Date
    public let session: SymphonyCodexSessionIdentityContract?
    public let codexAppServerPID: String?
    public let requestKind: SymphonyCodexServerRequestKindContract?
    public let message: String?
    public let usage: SymphonyCodexUsageSnapshotContract?
    public let rateLimits: SymphonyCodexRateLimitSnapshotContract?
    public let metadata: SymphonyConfigValueContract?

    public init(
        kind: Kind,
        timestamp: Date,
        session: SymphonyCodexSessionIdentityContract? = nil,
        codexAppServerPID: String? = nil,
        requestKind: SymphonyCodexServerRequestKindContract? = nil,
        message: String? = nil,
        usage: SymphonyCodexUsageSnapshotContract? = nil,
        rateLimits: SymphonyCodexRateLimitSnapshotContract? = nil,
        metadata: SymphonyConfigValueContract? = nil
    ) {
        self.kind = kind
        self.timestamp = timestamp
        self.session = session
        self.codexAppServerPID = codexAppServerPID
        self.requestKind = requestKind
        self.message = message
        self.usage = usage
        self.rateLimits = rateLimits
        self.metadata = metadata
    }
}
