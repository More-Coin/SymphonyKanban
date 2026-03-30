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
        _ result: SymphonyRuntimeIssueDetailQueryResultContract,
        issue: SymphonyIssue? = nil
    ) -> SymphonyIssueDetailViewModel {
        guard let snapshot = result.snapshot else {
            let hasSelection = result.issueIdentifier.isEmpty == false
            guard let issue else {
                return SymphonyIssueDetailViewModel(
                    issueIdentifier: result.issueIdentifier,
                    title: hasSelection ? result.issueIdentifier : "Select an issue",
                    subtitle: hasSelection
                        ? "No Symphony runtime detail is available for this issue yet."
                        : "Choose a running or queued issue from the dashboard to inspect its runtime context.",
                    stateLabel: "Idle",
                    stateKey: "idle",
                    runtimeStatusLabel: "Idle",
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

            let metadataLines = metadataLines(
                branchName: issue.branchName,
                url: issue.url,
                createdAt: issue.createdAt,
                updatedAt: issue.updatedAt
            )
            return SymphonyIssueDetailViewModel(
                issueIdentifier: issue.identifier,
                title: issue.title,
                subtitle: "No local runtime session is active for this issue.",
                stateLabel: issue.state,
                stateKey: normalizedStateKey(issue.state),
                runtimeStatusLabel: "Idle",
                priorityLabel: formatPriority(issue.priority),
                labels: issue.labels,
                descriptionText: issue.description,
                metadataLines: metadataLines,
                attemptsLabel: "No attempts recorded",
                generatedAtLabel: "Issue metadata only",
                runtimeViewModel: nil,
                workspaceViewModel: nil,
                logsViewModel: SymphonyLogsViewModel(
                    title: "Logs",
                    subtitle: "Runtime logs appear here when a local session is active.",
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
                emptyStateTitle: nil,
                emptyStateMessage: nil
            )
        }

        let issueIdentifier = issue?.identifier ?? snapshot.issue.issueIdentifier
        let title = issue?.title ?? snapshot.issue.title
        let descriptionText = issue?.description ?? snapshot.issue.description
        let labels = issue?.labels ?? snapshot.issue.labels
        let priority = issue?.priority ?? snapshot.issue.priority
        let trackerState = issue?.state ?? snapshot.issue.state
        let metadataLines = [
            "Runtime Status: \(snapshot.status)"
        ] + metadataLines(
            branchName: issue?.branchName ?? snapshot.issue.branchName,
            url: issue?.url ?? snapshot.issue.url,
            createdAt: issue?.createdAt ?? snapshot.issue.createdAt,
            updatedAt: issue?.updatedAt ?? snapshot.issue.updatedAt
        )

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
            issueIdentifier: issueIdentifier,
            title: title,
            subtitle: issueIdentifier,
            stateLabel: trackerState,
            stateKey: normalizedStateKey(trackerState),
            runtimeStatusLabel: snapshot.status,
            priorityLabel: formatPriority(priority),
            labels: labels,
            descriptionText: descriptionText,
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

    private func metadataLines(
        branchName: String?,
        url: String?,
        createdAt: Date?,
        updatedAt: Date?
    ) -> [String] {
        [
            branchName.map { "Branch: \($0)" },
            url.map { "URL: \($0)" },
            createdAt.map { "Created \(dateFormatter.string(from: $0))" },
            updatedAt.map { "Updated \(dateFormatter.string(from: $0))" }
        ].compactMap { $0 }
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

    private func normalizedStateKey(_ state: String) -> String {
        state
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
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
