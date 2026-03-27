import Foundation

public struct SymphonyCodexTurnExecutionResultContract: Equatable, Sendable {
    public enum Outcome: String, Equatable, Sendable {
        case completed = "completed"
        case failed = "failed"
        case cancelled = "cancelled"
    }

    public let session: SymphonyCodexSessionIdentityContract
    public let outcome: Outcome
    public let completedAt: Date
    public let codexAppServerPID: String?
    public let lastEvent: SymphonyCodexRuntimeEventContract?
    public let usage: SymphonyCodexUsageSnapshotContract?
    public let rateLimits: SymphonyCodexRateLimitSnapshotContract?

    public init(
        session: SymphonyCodexSessionIdentityContract,
        outcome: Outcome,
        completedAt: Date,
        codexAppServerPID: String? = nil,
        lastEvent: SymphonyCodexRuntimeEventContract? = nil,
        usage: SymphonyCodexUsageSnapshotContract? = nil,
        rateLimits: SymphonyCodexRateLimitSnapshotContract? = nil
    ) {
        self.session = session
        self.outcome = outcome
        self.completedAt = completedAt
        self.codexAppServerPID = codexAppServerPID
        self.lastEvent = lastEvent
        self.usage = usage
        self.rateLimits = rateLimits
    }
}
