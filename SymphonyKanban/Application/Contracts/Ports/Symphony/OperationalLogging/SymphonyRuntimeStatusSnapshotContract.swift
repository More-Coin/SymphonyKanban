import Foundation

public struct SymphonyRuntimeStatusSnapshotContract: Equatable, Sendable {
    public let outcome: String
    public let generatedAt: Date
    public let running: [SymphonyRuntimeStatusRunningRowContract]
    public let retrying: [SymphonyRuntimeStatusRetryRowContract]
    public let claimedCount: Int
    public let completedCount: Int
    public let codexTotals: SymphonyCodexTotalsContract
    public let codexRateLimits: SymphonyCodexRateLimitSnapshotContract?

    public init(
        outcome: String,
        generatedAt: Date,
        running: [SymphonyRuntimeStatusRunningRowContract],
        retrying: [SymphonyRuntimeStatusRetryRowContract],
        claimedCount: Int,
        completedCount: Int,
        codexTotals: SymphonyCodexTotalsContract,
        codexRateLimits: SymphonyCodexRateLimitSnapshotContract?
    ) {
        self.outcome = outcome
        self.generatedAt = generatedAt
        self.running = running
        self.retrying = retrying
        self.claimedCount = claimedCount
        self.completedCount = completedCount
        self.codexTotals = codexTotals
        self.codexRateLimits = codexRateLimits
    }
}
