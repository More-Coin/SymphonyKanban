import Foundation

public struct SymphonyIssueCatalogPresenter {
    public init() {}

    public func present(
        _ issues: [SymphonyIssue],
        selectedIssueIdentifier: String?
    ) -> SymphonyIssueCatalogViewModel {
        let sortedIssues = issues.sorted(by: issueOrdering)
        return SymphonyIssueCatalogViewModel(
            issuesByIdentifier: Dictionary(
                uniqueKeysWithValues: sortedIssues.map { ($0.identifier, $0) }
            ),
            boardViewModel: makeBoardViewModel(from: sortedIssues),
            listViewModel: makeListViewModel(
                from: sortedIssues,
                selectedIssueIdentifier: selectedIssueIdentifier
            )
        )
    }

    private func makeBoardViewModel(
        from issues: [SymphonyIssue]
    ) -> SymphonyKanbanBoardViewModel {
        let grouped = Dictionary(grouping: issues, by: statusKey(for:))
        return SymphonyKanbanBoardViewModel(
            columns: [
                makeColumn(id: "backlog", title: "Backlog", issues: grouped["backlog"] ?? []),
                makeColumn(id: "ready", title: "Ready", issues: grouped["ready"] ?? []),
                makeColumn(id: "in_progress", title: "In Progress", issues: grouped["in_progress"] ?? []),
                makeColumn(id: "blocked", title: "Blocked", issues: grouped["blocked"] ?? []),
                makeColumn(id: "review", title: "Review", issues: grouped["review"] ?? []),
                makeColumn(id: "done", title: "Done", issues: grouped["done"] ?? [])
            ]
        )
    }

    private func makeColumn(
        id: String,
        title: String,
        issues: [SymphonyIssue]
    ) -> SymphonyKanbanColumnViewModel {
        SymphonyKanbanColumnViewModel(
            id: id,
            title: title,
            statusKey: id,
            cards: issues.map { issue in
                SymphonyKanbanCardViewModel(
                    id: issue.id,
                    identifier: issue.identifier,
                    title: issue.title,
                    priorityLevel: issue.priority ?? 0,
                    statusKey: id,
                    labels: issue.labels
                )
            }
        )
    }

    private func makeListViewModel(
        from issues: [SymphonyIssue],
        selectedIssueIdentifier: String?
    ) -> SymphonyIssueListViewModel {
        SymphonyIssueListViewModel(
            rows: issues.map { issue in
                let key = statusKey(for: issue)
                return SymphonyIssueListRowViewModel(
                    id: issue.id,
                    identifier: issue.identifier,
                    title: issue.title,
                    statusKey: key,
                    statusLabel: statusLabel(for: key),
                    priorityLevel: issue.priority ?? 0,
                    agentName: nil,
                    labels: issue.labels,
                    lastEvent: nil,
                    lastEventTime: nil,
                    tokenCount: nil,
                    isSelected: issue.identifier == selectedIssueIdentifier
                )
            }
        )
    }

    private func issueOrdering(
        _ lhs: SymphonyIssue,
        _ rhs: SymphonyIssue
    ) -> Bool {
        let lhsPriority = lhs.priority ?? Int.max
        let rhsPriority = rhs.priority ?? Int.max

        if lhsPriority != rhsPriority {
            return lhsPriority < rhsPriority
        }

        return lhs.identifier.localizedStandardCompare(rhs.identifier) == .orderedAscending
    }

    private func statusKey(for issue: SymphonyIssue) -> String {
        let normalizedState = normalizeStatusKey(issue.state)
        let normalizedStateType = normalizeStatusKey(issue.stateType)

        if normalizedState.contains("review") {
            return "review"
        }

        if normalizedState.contains("blocked") {
            return "blocked"
        }

        if normalizedState == "ready" {
            return "ready"
        }

        if normalizedState.contains("done")
            || normalizedState.contains("complete")
            || normalizedState.contains("cancel")
            || normalizedStateType.contains("complete")
            || normalizedStateType.contains("cancel") {
            return "done"
        }

        if normalizedState.contains("doing")
            || normalizedState.contains("in_progress")
            || normalizedState == "running"
            || normalizedStateType == "started" {
            return "in_progress"
        }

        if normalizedState.contains("backlog")
            || normalizedState.contains("todo")
            || normalizedState.contains("triage")
            || normalizedStateType == "backlog"
            || normalizedStateType == "unstarted" {
            return "backlog"
        }

        return "backlog"
    }

    private func statusLabel(for key: String) -> String {
        switch key {
        case "ready":
            return "Ready"
        case "in_progress":
            return "In Progress"
        case "blocked":
            return "Blocked"
        case "review":
            return "Review"
        case "done":
            return "Done"
        default:
            return "Backlog"
        }
    }

    private func normalizeStatusKey(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
    }
}
