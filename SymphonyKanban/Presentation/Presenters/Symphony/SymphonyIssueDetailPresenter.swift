import Foundation

public struct SymphonyIssueDetailPresenter {
    private let dateFormatter: DateFormatter
    private let relativeDateFormatter: RelativeDateTimeFormatter

    public init(
        dateFormatter: DateFormatter? = nil,
        relativeDateFormatter: RelativeDateTimeFormatter = RelativeDateTimeFormatter()
    ) {
        self.dateFormatter = dateFormatter ?? Self.makeDateFormatter()
        self.relativeDateFormatter = relativeDateFormatter
        self.relativeDateFormatter.unitsStyle = .full
    }

    public func present(
        _ result: SymphonyRuntimeIssueDetailQueryResultContract
    ) -> SymphonyIssueDetailViewModel {
        guard let snapshot = result.snapshot else {
            let hasSelection = result.issueIdentifier.isEmpty == false
            return SymphonyIssueDetailViewModel(
                issueIdentifier: result.issueIdentifier,
                title: hasSelection ? result.issueIdentifier : "Select an issue",
                subtitle: hasSelection
                    ? "No Symphony runtime detail is available for this issue yet."
                    : "Choose a running or queued issue from the dashboard to inspect its runtime context.",
                stateLabel: "Idle",
                priorityLabel: nil,
                labels: [],
                descriptionText: nil,
                metadataLines: [],
                attemptsLabel: "No attempts recorded",
                generatedAtLabel: "No runtime snapshot",
                runtimeViewModel: nil,
                workspaceViewModel: nil,
                logsViewModel: SymphonyLogsViewModel(
                    title: "Logs",
                    subtitle: "Runtime logs appear here when a session is active.",
                    emptyState: "No log files are attached to this issue.",
                    entries: []
                ),
                recentEventsSectionTitle: "Recent Events",
                recentEventsEmptyState: "No recent events are available.",
                recentEventRows: [],
                lastErrorTitle: nil,
                lastErrorMessage: nil,
                lastErrorDetailLines: [],
                trackedSectionTitle: "Tracked Fields",
                trackedFieldLines: [],
                emptyStateTitle: hasSelection ? "No Runtime Detail Yet" : "Issue Detail",
                emptyStateMessage: hasSelection
                    ? "This issue has not produced a runtime snapshot yet."
                    : "Pick an issue from the dashboard to view runtime, workspace, logs, and event details."
            )
        }

        let metadataLines = [
            "Status: \(snapshot.status)",
            snapshot.issue.branchName.map { "Branch: \($0)" },
            snapshot.issue.url.map { "URL: \($0)" },
            snapshot.issue.createdAt.map { "Created \(dateFormatter.string(from: $0))" },
            snapshot.issue.updatedAt.map { "Updated \(dateFormatter.string(from: $0))" }
        ].compactMap { $0 }

        let runtimeViewModel = snapshot.running.map { running in
            SymphonyIssueRuntimeViewModel(
                title: "Runtime",
                stateLabel: running.state,
                sessionIDLabel: "Session \(running.sessionID)",
                threadIDLabel: "Thread \(running.threadID)",
                turnIDLabel: "Turn \(running.turnID)",
                processLabel: running.codexAppServerPID.map { "PID \($0)" },
                turnCountLabel: "\(running.turnCount) turns",
                startedAtLabel: "Started \(relativeDateFormatter.localizedString(for: running.startedAt, relativeTo: snapshot.generatedAt))",
                lastEventLabel: running.lastEvent.map { "Last event \($0)" },
                lastMessageLabel: running.lastMessage,
                tokenLabel: tokenLabel(for: running.tokens)
            )
        }

        let workspaceViewModel = snapshot.workspace.map {
            SymphonyWorkspaceViewModel(
                title: "Workspace",
                pathLabel: $0.path,
                branchLabel: snapshot.issue.branchName,
                statusLabel: snapshot.status
            )
        }

        let logsViewModel = SymphonyLogsViewModel(
            title: "Logs",
            subtitle: "Codex session output captured for this issue.",
            emptyState: "No log files are attached to this issue.",
            entries: snapshot.logs.codexSessionLogs.map {
                SymphonyLogsViewModel.Entry(
                    label: $0.label,
                    subtitle: $0.path,
                    destination: $0.url
                )
            }
        )

        let recentEventRows = snapshot.recentEvents.map {
            SymphonyRecentEventRowViewModel(
                title: $0.event,
                subtitle: relativeDateFormatter.localizedString(for: $0.at, relativeTo: snapshot.generatedAt),
                detailLines: eventDetailLines(for: $0)
            )
        }

        let trackedFieldLines = snapshot.tracked
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            .map { key, value in
                "\(key): \(stringify(configValue: value))"
            }

        let lastErrorDetailLines = snapshot.lastError.map {
            $0.details
                .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
                .map { "\($0.key): \(stringify(configValue: $0.value))" }
        } ?? []

        return SymphonyIssueDetailViewModel(
            issueIdentifier: snapshot.issue.issueIdentifier,
            title: snapshot.issue.title,
            subtitle: snapshot.issue.issueIdentifier,
            stateLabel: snapshot.status,
            priorityLabel: formatPriority(snapshot.issue.priority),
            labels: snapshot.issue.labels,
            descriptionText: snapshot.issue.description,
            metadataLines: metadataLines,
            attemptsLabel: attemptsLabel(for: snapshot.attempts),
            generatedAtLabel: "Snapshot \(relativeDateFormatter.localizedString(for: snapshot.generatedAt, relativeTo: snapshot.generatedAt.addingTimeInterval(90)))",
            runtimeViewModel: runtimeViewModel,
            workspaceViewModel: workspaceViewModel,
            logsViewModel: logsViewModel,
            recentEventsSectionTitle: "Recent Events",
            recentEventsEmptyState: "No recent events are available.",
            recentEventRows: recentEventRows,
            lastErrorTitle: snapshot.lastError.map { $0.code.map { "Last Error \($0)" } ?? "Last Error" },
            lastErrorMessage: snapshot.lastError?.message,
            lastErrorDetailLines: lastErrorDetailLines,
            trackedSectionTitle: "Tracked Fields",
            trackedFieldLines: trackedFieldLines,
            emptyStateTitle: nil,
            emptyStateMessage: nil
        )
    }

    public static func makeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    private func attemptsLabel(
        for attempts: SymphonyRuntimeIssueDetailSnapshotContract.Attempts
    ) -> String {
        var components = ["\(attempts.restartCount) restarts"]
        if let currentRetryAttempt = attempts.currentRetryAttempt {
            components.append("retry \(currentRetryAttempt)")
        }
        return components.joined(separator: " • ")
    }

    private func tokenLabel(for snapshot: SymphonyCodexUsageSnapshotContract) -> String {
        let total = snapshot.totalTokens ?? 0
        let input = snapshot.inputTokens ?? 0
        let output = snapshot.outputTokens ?? 0
        return "\(total.formatted()) total tokens • \(input.formatted()) in • \(output.formatted()) out"
    }

    private func eventDetailLines(
        for event: SymphonyRuntimeIssueDetailSnapshotContract.RecentEvent
    ) -> [String] {
        var lines: [String] = []
        if let message = event.message {
            lines.append(message)
        }
        lines.append(
            contentsOf: event.details
                .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
                .map { "\($0.key): \(stringify(configValue: $0.value))" }
        )
        return lines
    }

    private func formatPriority(_ priority: Int?) -> String? {
        guard let priority else {
            return nil
        }

        switch priority {
        case 0:
            return "Priority None"
        case 1:
            return "Priority Urgent"
        case 2:
            return "Priority High"
        case 3:
            return "Priority Medium"
        case 4:
            return "Priority Low"
        default:
            return "Priority \(priority)"
        }
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
