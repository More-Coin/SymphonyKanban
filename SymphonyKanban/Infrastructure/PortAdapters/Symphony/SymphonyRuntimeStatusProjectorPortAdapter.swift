import Foundation

public struct SymphonyRuntimeStatusProjectorPortAdapter: SymphonyRuntimeStatusProjectorPortProtocol {
    public init() {}

    public func projectStatusSnapshot<
        WorkerHandle: Equatable & Sendable,
        MonitorHandle: Equatable & Sendable,
        TimerHandle: Equatable & Sendable
    >(
        from state: SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle>,
        outcome: String,
        generatedAt: Date
    ) -> SymphonyRuntimeStatusSnapshotContract {
        SymphonyRuntimeStatusSnapshotContract(
            outcome: outcome,
            generatedAt: generatedAt,
            running: state.running.values
                .sorted { lhs, rhs in
                    lhs.identifier.localizedStandardCompare(rhs.identifier) == .orderedAscending
                }
                .map {
                    SymphonyRuntimeStatusRunningRowContract(
                        issueID: $0.issue.id,
                        issueIdentifier: $0.identifier,
                        state: $0.issue.state,
                        sessionID: $0.liveSession?.sessionID,
                        turnCount: $0.liveSession?.turnCount,
                        retryAttempt: $0.retryAttempt,
                        startedAt: $0.startedAt
                    )
                },
            retrying: state.retryAttempts.values
                .sorted { lhs, rhs in
                    if lhs.dueAtMs == rhs.dueAtMs {
                        return lhs.identifier.localizedStandardCompare(rhs.identifier) == .orderedAscending
                    }
                    return lhs.dueAtMs < rhs.dueAtMs
                }
                .map {
                    SymphonyRuntimeStatusRetryRowContract(
                        issueID: $0.issueID,
                        issueIdentifier: $0.identifier,
                        attempt: $0.attempt,
                        dueAtMs: $0.dueAtMs,
                        error: $0.error
                    )
                },
            claimedCount: state.claimed.count,
            completedCount: state.completed.count,
            codexTotals: state.codexTotals,
            codexRateLimits: state.codexRateLimits
        )
    }
}
