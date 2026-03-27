import Foundation

public struct SymphonyRuntimeQueryService {
    private let dashboardSnapshotUseCase: QuerySymphonyRuntimeDashboardSnapshotUseCase
    private let issueDetailSnapshotUseCase: QuerySymphonyRuntimeIssueDetailSnapshotUseCase

    public init(
        dashboardSnapshotUseCase: QuerySymphonyRuntimeDashboardSnapshotUseCase,
        issueDetailSnapshotUseCase: QuerySymphonyRuntimeIssueDetailSnapshotUseCase
    ) {
        self.dashboardSnapshotUseCase = dashboardSnapshotUseCase
        self.issueDetailSnapshotUseCase = issueDetailSnapshotUseCase
    }

    public func queryDashboardSnapshot() -> SymphonyRuntimeDashboardQueryResultContract {
        let snapshot = dashboardSnapshotUseCase.query()
        return SymphonyRuntimeDashboardQueryResultContract(
            snapshot: snapshot,
            hasRunningSessions: snapshot.counts.runningCount > 0,
            hasRetryQueue: snapshot.counts.retryingCount > 0,
            hasTrackedFields: snapshot.tracked.isEmpty == false,
            isEmpty: snapshot.counts.runningCount == 0
                && snapshot.counts.retryingCount == 0
                && snapshot.counts.claimedCount == 0
                && snapshot.counts.completedCount == 0
                && snapshot.running.isEmpty
                && snapshot.retrying.isEmpty
                && snapshot.tracked.isEmpty
                && snapshot.rateLimits == nil
                && snapshot.outcome == nil
                && snapshot.codexTotals.inputTokens == 0
                && snapshot.codexTotals.outputTokens == 0
                && snapshot.codexTotals.totalTokens == 0
                && snapshot.codexTotals.secondsRunning == 0
        )
    }

    public func queryIssueDetailSnapshot(
        issueIdentifier: String
    ) -> SymphonyRuntimeIssueDetailQueryResultContract {
        let normalizedIssueIdentifier = issueIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedIssueIdentifier.isEmpty == false else {
            return SymphonyRuntimeIssueDetailQueryResultContract(
                issueIdentifier: normalizedIssueIdentifier,
                snapshot: nil,
                isEmpty: true,
                hasRunningDetail: false,
                hasRetryDetail: false,
                hasRecentEvents: false,
                hasLastError: false,
                hasLogs: false
            )
        }

        let snapshot = issueDetailSnapshotUseCase.query(
            issueIdentifier: normalizedIssueIdentifier
        )
        let hasDetail = snapshot != nil

        return SymphonyRuntimeIssueDetailQueryResultContract(
            issueIdentifier: normalizedIssueIdentifier,
            snapshot: snapshot,
            isEmpty: hasDetail == false,
            hasRunningDetail: snapshot?.running != nil,
            hasRetryDetail: snapshot?.retry != nil,
            hasRecentEvents: snapshot?.recentEvents.isEmpty == false,
            hasLastError: snapshot?.lastError != nil,
            hasLogs: snapshot?.logs.codexSessionLogs.isEmpty == false
        )
    }
}
