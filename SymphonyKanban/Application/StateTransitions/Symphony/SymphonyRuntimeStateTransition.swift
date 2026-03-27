import Foundation

public struct SymphonyRuntimeStateTransition {
    public init() {}

    public func claim<
        WorkerHandle: Equatable & Sendable,
        MonitorHandle: Equatable & Sendable,
        TimerHandle: Equatable & Sendable
    >(
        issueID: String,
        in state: SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle>
    ) -> SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle> {
        var claimed = state.claimed
        claimed.insert(issueID)
        return makeState(from: state, claimed: claimed)
    }

    public func unclaim<
        WorkerHandle: Equatable & Sendable,
        MonitorHandle: Equatable & Sendable,
        TimerHandle: Equatable & Sendable
    >(
        issueID: String,
        in state: SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle>
    ) -> SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle> {
        var claimed = state.claimed
        claimed.remove(issueID)
        return makeState(from: state, claimed: claimed)
    }

    public func release<
        WorkerHandle: Equatable & Sendable,
        MonitorHandle: Equatable & Sendable,
        TimerHandle: Equatable & Sendable
    >(
        issueID: String,
        in state: SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle>
    ) -> SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle> {
        var running = state.running
        var claimed = state.claimed
        var retryAttempts = state.retryAttempts

        running.removeValue(forKey: issueID)
        claimed.remove(issueID)
        retryAttempts.removeValue(forKey: issueID)

        return makeState(
            from: state,
            running: running,
            claimed: claimed,
            retryAttempts: retryAttempts
        )
    }

    public func registerRunning<
        WorkerHandle: Equatable & Sendable,
        MonitorHandle: Equatable & Sendable,
        TimerHandle: Equatable & Sendable
    >(
        issueID: String,
        entry: SymphonyRunningEntryContract<WorkerHandle, MonitorHandle>,
        in state: SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle>
    ) -> SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle> {
        var running = state.running
        var claimed = state.claimed
        var retryAttempts = state.retryAttempts

        running[issueID] = entry
        claimed.insert(issueID)
        retryAttempts.removeValue(forKey: issueID)

        return makeState(
            from: state,
            running: running,
            claimed: claimed,
            retryAttempts: retryAttempts
        )
    }

    public func updateRunningEntry<
        WorkerHandle: Equatable & Sendable,
        MonitorHandle: Equatable & Sendable,
        TimerHandle: Equatable & Sendable
    >(
        issueID: String,
        issue: SymphonyIssue,
        liveSession: SymphonyLiveSessionContract?,
        in state: SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle>
    ) -> SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle> {
        guard let existingEntry = state.running[issueID] else {
            return state
        }

        var running = state.running
        running[issueID] = SymphonyRunningEntryContract(
            workerHandle: existingEntry.workerHandle,
            monitorHandle: existingEntry.monitorHandle,
            identifier: existingEntry.identifier,
            issue: issue,
            liveSession: liveSession ?? existingEntry.liveSession,
            retryAttempt: existingEntry.retryAttempt,
            startedAt: existingEntry.startedAt
        )

        return makeState(from: state, running: running)
    }

    public func scheduleContinuationRetry<
        WorkerHandle: Equatable & Sendable,
        MonitorHandle: Equatable & Sendable,
        TimerHandle: Equatable & Sendable
    >(
        issueID: String,
        identifier: String,
        timerHandle: TimerHandle,
        dueAtMs: Int64,
        in state: SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle>
    ) -> SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle> {
        var running = state.running
        var retryAttempts = state.retryAttempts

        running.removeValue(forKey: issueID)
        retryAttempts[issueID] = SymphonyRetryEntryContract(
            issueID: issueID,
            identifier: identifier,
            attempt: 1,
            dueAtMs: dueAtMs,
            timerHandle: timerHandle,
            error: nil
        )

        return makeState(
            from: state,
            running: running,
            retryAttempts: retryAttempts
        )
    }

    public func scheduleFailureRetry<
        WorkerHandle: Equatable & Sendable,
        MonitorHandle: Equatable & Sendable,
        TimerHandle: Equatable & Sendable
    >(
        issueID: String,
        identifier: String,
        nextAttempt: Int,
        error: String?,
        timerHandle: TimerHandle,
        dueAtMs: Int64,
        in state: SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle>
    ) -> SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle> {
        var running = state.running
        var retryAttempts = state.retryAttempts

        running.removeValue(forKey: issueID)
        retryAttempts[issueID] = SymphonyRetryEntryContract(
            issueID: issueID,
            identifier: identifier,
            attempt: nextAttempt,
            dueAtMs: dueAtMs,
            timerHandle: timerHandle,
            error: error
        )

        return makeState(
            from: state,
            running: running,
            retryAttempts: retryAttempts
        )
    }

    public func completeAttempt<
        WorkerHandle: Equatable & Sendable,
        MonitorHandle: Equatable & Sendable,
        TimerHandle: Equatable & Sendable
    >(
        _ result: SymphonyWorkerAttemptResultContract,
        latestRateLimits: SymphonyCodexRateLimitSnapshotContract?,
        in state: SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle>
    ) -> SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle> {
        var running = state.running
        var claimed = state.claimed
        var retryAttempts = state.retryAttempts
        var completed = state.completed

        running.removeValue(forKey: result.issueID)
        claimed.remove(result.issueID)
        retryAttempts.removeValue(forKey: result.issueID)
        completed.insert(result.issueID)

        let session = result.liveSession
        let duration = max(result.completedAt.timeIntervalSince(result.startedAt), 0)
        let updatedTotals = SymphonyCodexTotalsContract(
            inputTokens: state.codexTotals.inputTokens + (session?.codexInputTokens ?? 0),
            outputTokens: state.codexTotals.outputTokens + (session?.codexOutputTokens ?? 0),
            totalTokens: state.codexTotals.totalTokens + (session?.codexTotalTokens ?? 0),
            secondsRunning: state.codexTotals.secondsRunning + duration
        )

        return makeState(
            from: state,
            running: running,
            claimed: claimed,
            retryAttempts: retryAttempts,
            completed: completed,
            codexTotals: updatedTotals,
            codexRateLimits: latestRateLimits ?? state.codexRateLimits
        )
    }

    public func snapshotActiveRuntime<
        WorkerHandle: Equatable & Sendable,
        MonitorHandle: Equatable & Sendable,
        TimerHandle: Equatable & Sendable
    >(
        at now: Date,
        from state: SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle>
    ) -> SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle> {
        let snapshotTotals = state.running.values.reduce(into: state.codexTotals) { totals, entry in
            let duration = max(now.timeIntervalSince(entry.startedAt), 0)
            totals = SymphonyCodexTotalsContract(
                inputTokens: totals.inputTokens + (entry.liveSession?.codexInputTokens ?? 0),
                outputTokens: totals.outputTokens + (entry.liveSession?.codexOutputTokens ?? 0),
                totalTokens: totals.totalTokens + (entry.liveSession?.codexTotalTokens ?? 0),
                secondsRunning: totals.secondsRunning + duration
            )
        }

        return makeState(from: state, codexTotals: snapshotTotals)
    }

    public func apply<
        WorkerHandle: Equatable & Sendable,
        MonitorHandle: Equatable & Sendable,
        TimerHandle: Equatable & Sendable
    >(
        serviceConfig: SymphonyServiceConfigContract,
        to state: SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle>
    ) -> SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle> {
        makeState(
            from: state,
            pollIntervalMs: serviceConfig.polling.intervalMs,
            maxConcurrentAgents: serviceConfig.agent.maxConcurrentAgents
        )
    }

    private func makeState<
        WorkerHandle: Equatable & Sendable,
        MonitorHandle: Equatable & Sendable,
        TimerHandle: Equatable & Sendable
    >(
        from state: SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle>,
        pollIntervalMs: Int? = nil,
        maxConcurrentAgents: Int? = nil,
        running: [String: SymphonyRunningEntryContract<WorkerHandle, MonitorHandle>]? = nil,
        claimed: Set<String>? = nil,
        retryAttempts: [String: SymphonyRetryEntryContract<TimerHandle>]? = nil,
        completed: Set<String>? = nil,
        codexTotals: SymphonyCodexTotalsContract? = nil,
        codexRateLimits: SymphonyCodexRateLimitSnapshotContract? = nil
    ) -> SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle> {
        SymphonyRuntimeStateContract(
            pollIntervalMs: pollIntervalMs ?? state.pollIntervalMs,
            maxConcurrentAgents: maxConcurrentAgents ?? state.maxConcurrentAgents,
            running: running ?? state.running,
            claimed: claimed ?? state.claimed,
            retryAttempts: retryAttempts ?? state.retryAttempts,
            completed: completed ?? state.completed,
            codexTotals: codexTotals ?? state.codexTotals,
            codexRateLimits: codexRateLimits ?? state.codexRateLimits
        )
    }
}
