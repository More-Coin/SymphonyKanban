import Foundation

public struct SymphonyIssueCatalogPresenter {
    public init() {}

    public func present(
        _ collection: SymphonyIssueCollectionContract,
        displayMode: SymphonyIssueCatalogDisplayModeContract,
        selectedIssueIdentifier: String?
    ) -> SymphonyIssueCatalogViewModel {
        let sortedIssues = collection.issues.sorted(by: issueOrdering)
        return SymphonyIssueCatalogViewModel(
            displayMode: displayMode,
            issuesByIdentifier: Dictionary(
                uniqueKeysWithValues: sortedIssues.map { ($0.identifier, $0) }
            ),
            boardViewModel: makeBoardViewModel(
                from: collection,
                displayMode: displayMode
            ),
            listViewModel: makeListViewModel(
                from: collection,
                displayMode: displayMode,
                selectedIssueIdentifier: selectedIssueIdentifier
            ),
            activeBindingCount: collection.activeBindingCount,
            loadedBindingCount: collection.loadedBindingCount,
            failedBindingCount: collection.failedBindingCount
        )
    }

    private func makeBoardViewModel(
        from collection: SymphonyIssueCollectionContract,
        displayMode: SymphonyIssueCatalogDisplayModeContract
    ) -> SymphonyKanbanBoardViewModel {
        guard displayMode == .groupedSections,
              collection.bindingResults.isEmpty == false else {
            return makeMergedBoardViewModel(from: collection)
        }

        return SymphonyKanbanBoardViewModel(
            sections: collection.bindingResults.map { bindingResult in
                SymphonyKanbanBoardSectionViewModel(
                    id: bindingResult.id,
                    title: bindingResult.bindingContext.workspaceBinding.scopeName,
                    subtitle: bindingSubtitle(for: bindingResult),
                    errorMessage: bindingResult.loadError.map(errorMessage(for:)),
                    columns: makeColumns(
                        from: bindingResult.issues.sorted(by: issueOrdering),
                        scopeName: bindingResult.bindingContext.workspaceBinding.scopeName
                    )
                )
            }
        )
    }

    private func makeMergedBoardViewModel(
        from collection: SymphonyIssueCollectionContract
    ) -> SymphonyKanbanBoardViewModel {
        if collection.bindingResults.isEmpty {
            return SymphonyKanbanBoardViewModel(
                columns: makeColumns(
                    from: collection.issues.sorted(by: issueOrdering),
                    scopeName: nil
                )
            )
        }

        let entries = mergedIssueEntries(from: collection)
        let grouped = Dictionary(grouping: entries, by: { statusKey(for: $0.issue) })

        return SymphonyKanbanBoardViewModel(
            columns: [
                makeColumn(id: "backlog", title: "Backlog", entries: grouped["backlog"] ?? []),
                makeColumn(id: "ready", title: "Ready", entries: grouped["ready"] ?? []),
                makeColumn(id: "in_progress", title: "In Progress", entries: grouped["in_progress"] ?? []),
                makeColumn(id: "blocked", title: "Blocked", entries: grouped["blocked"] ?? []),
                makeColumn(id: "review", title: "Review", entries: grouped["review"] ?? []),
                makeColumn(id: "done", title: "Done", entries: grouped["done"] ?? [])
            ]
        )
    }

    private func makeColumns(
        from issues: [SymphonyIssue],
        scopeName: String?
    ) -> [SymphonyKanbanColumnViewModel] {
        let grouped = Dictionary(grouping: issues, by: statusKey(for:))
        return [
            makeColumn(id: "backlog", title: "Backlog", issues: grouped["backlog"] ?? [], scopeName: scopeName),
            makeColumn(id: "ready", title: "Ready", issues: grouped["ready"] ?? [], scopeName: scopeName),
            makeColumn(id: "in_progress", title: "In Progress", issues: grouped["in_progress"] ?? [], scopeName: scopeName),
            makeColumn(id: "blocked", title: "Blocked", issues: grouped["blocked"] ?? [], scopeName: scopeName),
            makeColumn(id: "review", title: "Review", issues: grouped["review"] ?? [], scopeName: scopeName),
            makeColumn(id: "done", title: "Done", issues: grouped["done"] ?? [], scopeName: scopeName)
        ]
    }

    private func makeColumn(
        id: String,
        title: String,
        entries: [(issue: SymphonyIssue, scopeName: String?)]
    ) -> SymphonyKanbanColumnViewModel {
        SymphonyKanbanColumnViewModel(
            id: id,
            title: title,
            statusKey: id,
            cards: entries.map { entry in
                SymphonyKanbanCardViewModel(
                    id: entry.issue.id,
                    identifier: entry.issue.identifier,
                    title: entry.issue.title,
                    scopeName: entry.scopeName,
                    priorityLevel: entry.issue.priority ?? 0,
                    statusKey: id,
                    labels: entry.issue.labels
                )
            }
        )
    }

    private func makeColumn(
        id: String,
        title: String,
        issues: [SymphonyIssue],
        scopeName: String?
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
                    scopeName: scopeName,
                    priorityLevel: issue.priority ?? 0,
                    statusKey: id,
                    labels: issue.labels
                )
            }
        )
    }

    private func makeListViewModel(
        from collection: SymphonyIssueCollectionContract,
        displayMode: SymphonyIssueCatalogDisplayModeContract,
        selectedIssueIdentifier: String?
    ) -> SymphonyIssueListViewModel {
        guard displayMode == .groupedSections,
              collection.bindingResults.isEmpty == false else {
            return makeMergedListViewModel(
                from: collection,
                selectedIssueIdentifier: selectedIssueIdentifier
            )
        }

        return SymphonyIssueListViewModel(
            sections: collection.bindingResults.map { bindingResult in
                SymphonyIssueListSectionViewModel(
                    id: bindingResult.id,
                    title: bindingResult.bindingContext.workspaceBinding.scopeName,
                    subtitle: bindingSubtitle(for: bindingResult),
                    errorMessage: bindingResult.loadError.map(errorMessage(for:)),
                    rows: makeRows(
                        from: bindingResult.issues.sorted(by: issueOrdering),
                        scopeName: bindingResult.bindingContext.workspaceBinding.scopeName,
                        selectedIssueIdentifier: selectedIssueIdentifier
                    )
                )
            }
        )
    }

    private func makeMergedListViewModel(
        from collection: SymphonyIssueCollectionContract,
        selectedIssueIdentifier: String?
    ) -> SymphonyIssueListViewModel {
        if collection.bindingResults.isEmpty {
            return SymphonyIssueListViewModel(
                rows: makeRows(
                    from: collection.issues.sorted(by: issueOrdering),
                    scopeName: nil,
                    selectedIssueIdentifier: selectedIssueIdentifier
                )
            )
        }

        return SymphonyIssueListViewModel(
            rows: mergedIssueEntries(from: collection).map { entry in
                let key = statusKey(for: entry.issue)
                return SymphonyIssueListRowViewModel(
                    id: entry.issue.id,
                    identifier: entry.issue.identifier,
                    title: entry.issue.title,
                    scopeName: entry.scopeName,
                    statusKey: key,
                    statusLabel: statusLabel(for: key),
                    priorityLevel: entry.issue.priority ?? 0,
                    agentName: nil,
                    labels: entry.issue.labels,
                    lastEvent: nil,
                    lastEventTime: nil,
                    tokenCount: nil,
                    isSelected: entry.issue.identifier == selectedIssueIdentifier
                )
            }
        )
    }

    private func makeRows(
        from issues: [SymphonyIssue],
        scopeName: String?,
        selectedIssueIdentifier: String?
    ) -> [SymphonyIssueListRowViewModel] {
        issues.map { issue in
            let key = statusKey(for: issue)
            return SymphonyIssueListRowViewModel(
                id: issue.id,
                identifier: issue.identifier,
                title: issue.title,
                scopeName: scopeName,
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
    }

    private func bindingSubtitle(
        for bindingResult: SymphonyIssueCatalogBindingResultContract
    ) -> String? {
        let count = bindingResult.issues.count
        switch bindingResult.loadState {
        case .loaded:
            return count == 1 ? "1 issue" : "\(count) issues"
        case .failed:
            return nil
        }
    }

    private func errorMessage(
        for failure: SymphonyFailureSummaryContract
    ) -> String {
        if let details = failure.details,
           details.isEmpty == false {
            return "\(failure.message) \(details)"
        }

        return failure.message
    }

    private func mergedIssueEntries(
        from collection: SymphonyIssueCollectionContract
    ) -> [(issue: SymphonyIssue, scopeName: String?)] {
        collection.bindingResults
            .flatMap { bindingResult in
                bindingResult.issues.map { issue in
                    (
                        issue: issue,
                        scopeName: bindingResult.bindingContext.workspaceBinding.scopeName
                    )
                }
            }
            .sorted { issueOrdering($0.issue, $1.issue) }
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
