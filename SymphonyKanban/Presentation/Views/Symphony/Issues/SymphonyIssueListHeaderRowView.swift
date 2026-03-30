import SwiftUI

// MARK: - SymphonyIssueListSortColumnView
/// Defines the sortable columns available in the issue list.

public enum SymphonyIssueListSortColumnView: String, CaseIterable {
    case priority = "Priority"
    case identifier = "ID"
    case title = "Title"
    case scope = "Scope"
    case status = "Status"
    case agent = "Agent"
    case labels = "Labels"
    case lastEvent = "Last Event"
    case tokens = "Tokens"
}

// MARK: - SymphonyIssueListHeaderRowView
/// Sortable column header row for the issue list.

public struct SymphonyIssueListHeaderRowView: View {
    @Binding var sortColumn: SymphonyIssueListSortColumnView
    @Binding var sortAscending: Bool

    public init(
        sortColumn: Binding<SymphonyIssueListSortColumnView>,
        sortAscending: Binding<Bool>
    ) {
        self._sortColumn = sortColumn
        self._sortAscending = sortAscending
    }

    public var body: some View {
        HStack(spacing: 0) {
            sortableColumnHeader(.priority, width: 60)
            sortableColumnHeader(.identifier, width: 90)
            sortableColumnHeader(.title, minWidth: 160)
            sortableColumnHeader(.scope, width: 110)
            sortableColumnHeader(.status, width: 100)
            sortableColumnHeader(.agent, width: 110)
            nonSortableHeader("Labels", width: 140)
            sortableColumnHeader(.lastEvent, width: 150)
            sortableColumnHeader(.tokens, width: 90)
        }
        .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)
        .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
        .background(SymphonyDesignStyle.Background.primary.opacity(0.5))
    }

    // MARK: - Private

    private func sortableColumnHeader(
        _ column: SymphonyIssueListSortColumnView,
        width: CGFloat? = nil,
        minWidth: CGFloat? = nil
    ) -> some View {
        Button {
            if sortColumn == column {
                sortAscending.toggle()
            } else {
                sortColumn = column
                sortAscending = true
            }
        } label: {
            HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                Text(column.rawValue)
                    .font(SymphonyDesignStyle.Typography.micro)
                    .fontWeight(.semibold)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                    .textCase(.uppercase)
                    .tracking(0.6)

                if sortColumn == column {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(SymphonyDesignStyle.Accent.blue)
                }
            }
            .frame(maxWidth: minWidth != nil ? .infinity : nil, alignment: .leading)
        }
        .buttonStyle(.plain)
        .frame(width: width)
        .frame(minWidth: minWidth)
    }

    private func nonSortableHeader(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(SymphonyDesignStyle.Typography.micro)
            .fontWeight(.semibold)
            .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            .textCase(.uppercase)
            .tracking(0.6)
            .frame(width: width, alignment: .leading)
    }
}
