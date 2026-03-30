import SwiftUI

// MARK: - SymphonyIssueListView
/// Power-user table/list view for issues, inspired by Linear's dense list layout.
/// Supports column sorting, status filtering, and search.

public struct SymphonyIssueListView: View {
    private let viewModel: SymphonyIssueListViewModel
    private let onIssueSelected: (String) -> Void

    @State private var searchText = ""
    @State private var statusFilter = "All"
    @State private var sortColumn: SymphonyIssueListSortColumnView = .identifier
    @State private var sortAscending = true
    @State private var hoveredRowID: String?

    public init(
        viewModel: SymphonyIssueListViewModel,
        onIssueSelected: @escaping (String) -> Void
    ) {
        self.viewModel = viewModel
        self.onIssueSelected = onIssueSelected
    }

    private var statusKeys: [String] {
        let keys = Set(viewModel.rows.map { $0.statusLabel })
        return ["All"] + keys.sorted()
    }

    private var filteredSections: [SymphonyIssueListSectionViewModel] {
        viewModel.sections.compactMap { section in
            let rows = filteredRows(from: section.rows)
            guard rows.isEmpty == false || section.errorMessage != nil else {
                return nil
            }

            return SymphonyIssueListSectionViewModel(
                id: section.id,
                title: section.title,
                subtitle: section.subtitle,
                errorMessage: section.errorMessage,
                rows: rows
            )
        }
    }

    private var filteredRowsCount: Int {
        filteredSections.reduce(0) { $0 + $1.rows.count }
    }

    public var body: some View {
        VStack(spacing: 0) {
            SymphonyIssueListFilterBarView(
                searchText: $searchText,
                statusFilter: $statusFilter,
                statusKeys: statusKeys,
                issueCount: filteredRowsCount
            )
            SymphonyDividerView()
            SymphonyIssueListHeaderRowView(
                sortColumn: $sortColumn,
                sortAscending: $sortAscending
            )
            SymphonyDividerView()
            dataRows
        }
        .background(SymphonyDesignStyle.Background.secondary)
    }

    // MARK: - Data Rows

    private var dataRows: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(filteredSections.enumerated()), id: \.element.id) { sectionIndex, section in
                    SymphonyIssueListSectionHeaderView(
                        section: section,
                        showHeader: shouldRenderSectionHeader(section)
                    )

                    ForEach(Array(section.rows.enumerated()), id: \.element.id) { rowIndex, row in
                        SymphonyIssueListRowView(
                            row: row,
                            index: sectionIndex * 1000 + rowIndex,
                            isHovered: hoveredRowID == row.id,
                            onSelected: { onIssueSelected(row.identifier) },
                            onHover: { isHovered in
                                hoveredRowID = isHovered ? row.id : nil
                            }
                        )
                        SymphonyDividerView(opacity: 0.03)
                    }
                }
            }
        }
    }

    private func filteredRows(
        from sourceRows: [SymphonyIssueListRowViewModel]
    ) -> [SymphonyIssueListRowViewModel] {
        var rows = sourceRows

        if statusFilter != "All" {
            rows = rows.filter { $0.statusLabel == statusFilter }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            rows = rows.filter {
                $0.identifier.lowercased().contains(query) ||
                $0.title.lowercased().contains(query) ||
                ($0.scopeName?.lowercased().contains(query) ?? false) ||
                ($0.agentName?.lowercased().contains(query) ?? false) ||
                $0.labels.contains(where: { $0.lowercased().contains(query) })
            }
        }

        rows.sort(by: rowComparator)
        return rows
    }

    private func shouldRenderSectionHeader(
        _ section: SymphonyIssueListSectionViewModel
    ) -> Bool {
        section.title != nil || section.errorMessage != nil || viewModel.sections.count > 1
    }

    private func rowComparator(
        _ a: SymphonyIssueListRowViewModel,
        _ b: SymphonyIssueListRowViewModel
    ) -> Bool {
        let result: Bool
        switch sortColumn {
        case .priority:
            result = a.priorityLevel < b.priorityLevel
        case .identifier:
            result = a.identifier.localizedStandardCompare(b.identifier) == .orderedAscending
        case .title:
            result = a.title.localizedStandardCompare(b.title) == .orderedAscending
        case .scope:
            result = (a.scopeName ?? "").localizedStandardCompare(b.scopeName ?? "") == .orderedAscending
        case .status:
            result = a.statusLabel.localizedStandardCompare(b.statusLabel) == .orderedAscending
        case .agent:
            result = (a.agentName ?? "").localizedStandardCompare(b.agentName ?? "") == .orderedAscending
        case .labels:
            return false
        case .lastEvent:
            result = (a.lastEvent ?? "").localizedStandardCompare(b.lastEvent ?? "") == .orderedAscending
        case .tokens:
            result = (a.tokenCount ?? "").localizedStandardCompare(b.tokenCount ?? "") == .orderedAscending
        }
        return sortAscending ? result : !result
    }
}

#Preview {
    SymphonyIssueListView(
        viewModel: SymphonyPreviewDI.makeIssueListViewModel(),
        onIssueSelected: { id in
            print("Selected: \(id)")
        }
    )
    .frame(width: 1200, height: 600)
    .background(SymphonyDesignStyle.Background.primary)
}
