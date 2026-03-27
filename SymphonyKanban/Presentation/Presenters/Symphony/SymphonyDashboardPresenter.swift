import Foundation

public struct SymphonyDashboardPresenter {
    private let relativeDateFormatter: RelativeDateTimeFormatter

    public init(relativeDateFormatter: RelativeDateTimeFormatter = RelativeDateTimeFormatter()) {
        self.relativeDateFormatter = relativeDateFormatter
        self.relativeDateFormatter.unitsStyle = .full
    }

    public func present(
        _ result: SymphonyRuntimeDashboardQueryResultContract,
        selectedIssueIdentifier: String?
    ) -> SymphonyDashboardViewModel {
        let snapshot = result.snapshot
        let runtimeSummary = SymphonyRuntimeSummaryViewModel(
            title: "Runtime Summary",
            statusLabel: snapshot.outcome ?? "Monitoring",
            generatedAtLabel: "Updated \(relativeDateFormatter.localizedString(for: snapshot.generatedAt, relativeTo: snapshot.generatedAt.addingTimeInterval(45)))",
            runningCountLabel: "\(snapshot.counts.runningCount) running",
            retryCountLabel: "\(snapshot.counts.retryingCount) retrying",
            claimedCountLabel: "\(snapshot.counts.claimedCount) claimed",
            completedCountLabel: "\(snapshot.counts.completedCount) completed",
            totalTokensLabel: "\(snapshot.codexTotals.totalTokens.formatted()) total tokens",
            runtimeDurationLabel: "Runtime \(formatDuration(snapshot.codexTotals.secondsRunning))",
            rateLimitLabel: snapshot.rateLimits.map { "Rate limits \(stringify(configValue: $0.payload))" }
        )

        let runningSessions = snapshot.running.map {
            SymphonyRunningSessionRowViewModel(
                issueIdentifier: $0.issueIdentifier,
                statusLabel: $0.state,
                detailLabel: runningDetailLabel(for: $0),
                timingLabel: runningTimingLabel(for: $0, generatedAt: snapshot.generatedAt),
                tokenLabel: tokenLabel(for: $0.tokens),
                eventLabel: runningEventLabel(for: $0),
                isSelected: $0.issueIdentifier == selectedIssueIdentifier
            )
        }
        let retryQueue = snapshot.retrying.map {
            SymphonyRetryRowViewModel(
                issueIdentifier: $0.issueIdentifier,
                attemptLabel: "Attempt \($0.attempt)",
                dueLabel: "Due \(relativeDateFormatter.localizedString(for: $0.dueAt, relativeTo: snapshot.generatedAt))",
                errorLabel: $0.error,
                isSelected: $0.issueIdentifier == selectedIssueIdentifier
            )
        }
        let trackedFieldLines = snapshot.tracked
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            .map { key, value in
                "\(key): \(stringify(configValue: value))"
            }

        return SymphonyDashboardViewModel(
            title: "Symphony Dashboard",
            subtitle: result.isEmpty
                ? "No active Symphony runtime activity is available yet."
                : "Monitor running sessions, retries, and tracked runtime context from one surface.",
            runtimeSummary: runtimeSummary,
            runningSectionTitle: "Running Sessions",
            runningEmptyState: "No live sessions are currently active.",
            runningSessions: runningSessions,
            retrySectionTitle: "Retry Queue",
            retryEmptyState: "Nothing is waiting in the retry queue.",
            retryQueue: retryQueue,
            trackedSectionTitle: "Tracked Fields",
            trackedFieldLines: trackedFieldLines
        )
    }

    private func runningDetailLabel(
        for row: SymphonyRuntimeDashboardSnapshotContract.RunningRow
    ) -> String {
        var components: [String] = []
        if let sessionID = row.sessionID {
            components.append("Session \(sessionID)")
        }
        components.append("\(row.turnCount) turns")
        if let retryAttempt = row.retryAttempt {
            components.append("Retry \(retryAttempt)")
        }
        return components.joined(separator: " • ")
    }

    private func runningTimingLabel(
        for row: SymphonyRuntimeDashboardSnapshotContract.RunningRow,
        generatedAt: Date
    ) -> String {
        if let lastEventAt = row.lastEventAt {
            return "Last event \(relativeDateFormatter.localizedString(for: lastEventAt, relativeTo: generatedAt))"
        }
        return "Started \(relativeDateFormatter.localizedString(for: row.startedAt, relativeTo: generatedAt))"
    }

    private func runningEventLabel(
        for row: SymphonyRuntimeDashboardSnapshotContract.RunningRow
    ) -> String? {
        switch (row.lastEvent, row.lastMessage) {
        case let (event?, message?):
            return "\(event): \(message)"
        case let (event?, nil):
            return event
        case let (nil, message?):
            return message
        default:
            return nil
        }
    }

    private func tokenLabel(for snapshot: SymphonyCodexUsageSnapshotContract) -> String {
        let total = snapshot.totalTokens ?? 0
        let input = snapshot.inputTokens ?? 0
        let output = snapshot.outputTokens ?? 0
        return "\(total.formatted()) total • \(input.formatted()) in • \(output.formatted()) out"
    }

    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        if minutes == 0 {
            return "\(remainingSeconds)s"
        }
        return "\(minutes)m \(remainingSeconds)s"
    }

    private func stringify(configValue: SymphonyConfigValueContract) -> String {
        switch configValue {
        case .string(let value):
            return value
        case .integer(let value):
            return value.formatted()
        case .double(let value):
            return value.formatted(.number.precision(.fractionLength(0...2)))
        case .bool(let value):
            return value ? "true" : "false"
        case .array(let values):
            return values.map(stringify(configValue:)).joined(separator: ", ")
        case .object(let values):
            return values
                .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
                .map { "\($0.key)=\(stringify(configValue: $0.value))" }
                .joined(separator: ", ")
        case .null:
            return "null"
        }
    }
}
