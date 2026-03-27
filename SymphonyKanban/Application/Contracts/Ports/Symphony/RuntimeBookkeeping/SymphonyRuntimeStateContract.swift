import Foundation

public struct SymphonyRuntimeStateContract<
    WorkerHandle: Equatable & Sendable,
    MonitorHandle: Equatable & Sendable,
    TimerHandle: Equatable & Sendable
>: Equatable, Sendable {
    public let pollIntervalMs: Int
    public let maxConcurrentAgents: Int
    public let running: [String: SymphonyRunningEntryContract<WorkerHandle, MonitorHandle>]
    public let claimed: Set<String>
    public let retryAttempts: [String: SymphonyRetryEntryContract<TimerHandle>]
    public let completed: Set<String>
    public let codexTotals: SymphonyCodexTotalsContract
    public let codexRateLimits: SymphonyCodexRateLimitSnapshotContract?

    public init(
        pollIntervalMs: Int,
        maxConcurrentAgents: Int,
        running: [String: SymphonyRunningEntryContract<WorkerHandle, MonitorHandle>],
        claimed: Set<String>,
        retryAttempts: [String: SymphonyRetryEntryContract<TimerHandle>],
        completed: Set<String>,
        codexTotals: SymphonyCodexTotalsContract,
        codexRateLimits: SymphonyCodexRateLimitSnapshotContract?
    ) {
        self.pollIntervalMs = pollIntervalMs
        self.maxConcurrentAgents = maxConcurrentAgents
        self.running = running
        self.claimed = claimed
        self.retryAttempts = retryAttempts
        self.completed = completed
        self.codexTotals = codexTotals
        self.codexRateLimits = codexRateLimits
    }

    public func canClaim(issueID: String) -> Bool {
        !claimed.contains(issueID)
    }

    public func availableSlots(
        forState stateName: String,
        using serviceConfig: SymphonyServiceConfigContract
    ) -> Int {
        let normalizedState = Self.normalizeState(stateName)
        let configuredLimit = serviceConfig.agent.maxConcurrentAgentsByState[normalizedState]
            ?? maxConcurrentAgents
        let activeCount = running.values.reduce(into: 0) { count, entry in
            if Self.normalizeState(entry.issue.state) == normalizedState {
                count += 1
            }
        }

        return max(configuredLimit - activeCount, 0)
    }

    public func hasAvailableSlot(
        for issue: SymphonyIssue,
        using serviceConfig: SymphonyServiceConfigContract
    ) -> Bool {
        availableSlots(
            forState: issue.state,
            using: serviceConfig
        ) > 0
    }

    private static func normalizeState(_ state: String) -> String {
        state.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
