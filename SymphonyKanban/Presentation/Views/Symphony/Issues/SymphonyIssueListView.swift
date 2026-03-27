import SwiftUI

// MARK: - SymphonyIssueListView
/// Power-user table/list view for issues, inspired by Linear's dense list layout.
/// Supports column sorting, status filtering, and search.

public struct SymphonyIssueListView: View {
    private let onIssueSelected: (String) -> Void

    @State private var viewModel = SymphonyIssueListView.mockViewModel
    @State private var searchText = ""
    @State private var statusFilter = "All"
    @State private var sortColumn: SortColumn = .identifier
    @State private var sortAscending = true
    @State private var hoveredRowID: String?

    private enum SortColumn: String, CaseIterable {
        case priority = "Priority"
        case identifier = "ID"
        case title = "Title"
        case status = "Status"
        case agent = "Agent"
        case lastEvent = "Last Event"
        case tokens = "Tokens"
    }

    public init(onIssueSelected: @escaping (String) -> Void) {
        self.onIssueSelected = onIssueSelected
    }

    private var statusKeys: [String] {
        let keys = Set(viewModel.rows.map { $0.statusLabel })
        return ["All"] + keys.sorted()
    }

    private var filteredRows: [SymphonyIssueListRowViewModel] {
        var rows = viewModel.rows

        if statusFilter != "All" {
            rows = rows.filter { $0.statusLabel == statusFilter }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            rows = rows.filter {
                $0.identifier.lowercased().contains(query) ||
                $0.title.lowercased().contains(query) ||
                ($0.agentName?.lowercased().contains(query) ?? false) ||
                $0.labels.contains(where: { $0.lowercased().contains(query) })
            }
        }

        rows.sort { a, b in
            let result: Bool
            switch sortColumn {
            case .priority:
                result = a.priorityLevel < b.priorityLevel
            case .identifier:
                result = a.identifier.localizedStandardCompare(b.identifier) == .orderedAscending
            case .title:
                result = a.title.localizedStandardCompare(b.title) == .orderedAscending
            case .status:
                result = a.statusLabel.localizedStandardCompare(b.statusLabel) == .orderedAscending
            case .agent:
                result = (a.agentName ?? "").localizedStandardCompare(b.agentName ?? "") == .orderedAscending
            case .lastEvent:
                result = (a.lastEvent ?? "").localizedStandardCompare(b.lastEvent ?? "") == .orderedAscending
            case .tokens:
                result = (a.tokenCount ?? "").localizedStandardCompare(b.tokenCount ?? "") == .orderedAscending
            }
            return sortAscending ? result : !result
        }

        return rows
    }

    public var body: some View {
        VStack(spacing: 0) {
            filterBar
            SymphonyDividerView()
            headerRow
            SymphonyDividerView()
            dataRows
        }
        .background(SymphonyDesignStyle.Background.secondary)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.md) {
            SymphonySearchFieldView(placeholder: "Filter issues...", text: $searchText)
                .frame(maxWidth: 260)

            Picker("Status", selection: $statusFilter) {
                ForEach(statusKeys, id: \.self) { key in
                    Text(key).tag(key)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)

            Spacer()

            Text("\(filteredRows.count) issues")
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
        }
        .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)
        .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
        .background(SymphonyDesignStyle.Background.tertiary)
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(spacing: 0) {
            columnHeader(.priority, width: 60)
            columnHeader(.identifier, width: 90)
            columnHeader(.title, minWidth: 200)
            columnHeader(.status, width: 100)
            columnHeader(.agent, width: 110)
            labelsHeader(width: 140)
            columnHeader(.lastEvent, width: 150)
            columnHeader(.tokens, width: 90)
        }
        .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)
        .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
        .background(SymphonyDesignStyle.Background.primary.opacity(0.5))
    }

    private func columnHeader(_ column: SortColumn, width: CGFloat? = nil, minWidth: CGFloat? = nil) -> some View {
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

    private func labelsHeader(width: CGFloat) -> some View {
        Text("Labels")
            .font(SymphonyDesignStyle.Typography.micro)
            .fontWeight(.semibold)
            .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            .textCase(.uppercase)
            .tracking(0.6)
            .frame(width: width, alignment: .leading)
    }

    // MARK: - Data Rows

    private var dataRows: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(filteredRows.enumerated()), id: \.element.id) { index, row in
                    issueRow(row, index: index)
                    SymphonyDividerView(opacity: 0.03)
                }
            }
        }
    }

    private func issueRow(_ row: SymphonyIssueListRowViewModel, index: Int) -> some View {
        Button {
            onIssueSelected(row.identifier)
        } label: {
            HStack(spacing: 0) {
                // Priority
                SymphonyPriorityDotView(level: row.priorityLevel)
                    .frame(width: 60, alignment: .leading)

                // Identifier
                Text(row.identifier)
                    .font(SymphonyDesignStyle.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(SymphonyDesignStyle.Accent.blue)
                    .frame(width: 90, alignment: .leading)

                // Title
                Text(row.title)
                    .font(SymphonyDesignStyle.Typography.body)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Status
                SymphonyStatusBadgeView(row.statusLabel, statusKey: row.statusKey, size: .small)
                    .frame(width: 100, alignment: .leading)

                // Agent
                agentCell(row.agentName)
                    .frame(width: 110, alignment: .leading)

                // Labels
                labelsCell(row.labels)
                    .frame(width: 140, alignment: .leading)

                // Last Event
                VStack(alignment: .leading, spacing: 1) {
                    if let event = row.lastEvent {
                        Text(event)
                            .font(SymphonyDesignStyle.Typography.micro)
                            .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                            .lineLimit(1)
                    }
                    if let time = row.lastEventTime {
                        Text(time)
                            .font(SymphonyDesignStyle.Typography.micro)
                            .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                    }
                }
                .frame(width: 150, alignment: .leading)

                // Tokens
                Text(row.tokenCount ?? "-")
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                    .frame(width: 90, alignment: .trailing)
            }
            .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)
            .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
            .background(rowBackground(row: row, index: index))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered in
            hoveredRowID = isHovered ? row.id : nil
        }
    }

    private func rowBackground(row: SymphonyIssueListRowViewModel, index: Int) -> some View {
        Group {
            if row.isSelected {
                SymphonyDesignStyle.Accent.blue.opacity(0.10)
            } else if hoveredRowID == row.id {
                SymphonyDesignStyle.Background.elevated
            } else if index.isMultiple(of: 2) {
                SymphonyDesignStyle.Background.secondary
            } else {
                SymphonyDesignStyle.Background.tertiary.opacity(0.4)
            }
        }
    }

    private func agentCell(_ name: String?) -> some View {
        Group {
            if let name {
                HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                    SymphonyAgentAvatarView(name: name, size: 18)
                    Text(name)
                        .font(SymphonyDesignStyle.Typography.micro)
                        .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                        .lineLimit(1)
                }
            } else {
                Text("-")
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            }
        }
    }

    private func labelsCell(_ labels: [String]) -> some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.xxs) {
            ForEach(labels.prefix(2), id: \.self) { label in
                SymphonyLabelChipView(label)
            }
            if labels.count > 2 {
                Text("+\(labels.count - 2)")
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            }
        }
    }
}

// MARK: - Mock Data

extension SymphonyIssueListView {
    static var mockViewModel: SymphonyIssueListViewModel {
        SymphonyIssueListViewModel(rows: [
            SymphonyIssueListRowViewModel(
                id: "issue-142", identifier: "KAN-142",
                title: "Rebuild Symphony dashboard pipeline",
                statusKey: "in_progress", statusLabel: "In Progress",
                priorityLevel: 2, agentName: "Codex Alpha",
                labels: ["symphony", "dashboard"],
                lastEvent: "tool_call", lastEventTime: "2 min ago",
                tokenCount: "16,000", isSelected: true
            ),
            SymphonyIssueListRowViewModel(
                id: "issue-177", identifier: "KAN-177",
                title: "Wire issue detail renderer",
                statusKey: "review", statusLabel: "Review",
                priorityLevel: 3, agentName: "Codex Beta",
                labels: ["symphony", "detail"],
                lastEvent: "lint", lastEventTime: "10 min ago",
                tokenCount: "11,400", isSelected: false
            ),
            SymphonyIssueListRowViewModel(
                id: "issue-181", identifier: "KAN-181",
                title: "Harden refresh route selection handling",
                statusKey: "blocked", statusLabel: "Blocked",
                priorityLevel: 2, agentName: nil,
                labels: ["symphony", "refresh"],
                lastEvent: "retry_scheduled", lastEventTime: "5 min ago",
                tokenCount: "8,200", isSelected: false
            ),
            SymphonyIssueListRowViewModel(
                id: "issue-190", identifier: "KAN-190",
                title: "Add kanban column drag-and-drop reordering",
                statusKey: "ready", statusLabel: "Ready",
                priorityLevel: 1, agentName: nil,
                labels: ["kanban", "ux"],
                lastEvent: nil, lastEventTime: nil,
                tokenCount: nil, isSelected: false
            ),
            SymphonyIssueListRowViewModel(
                id: "issue-195", identifier: "KAN-195",
                title: "Implement sidebar navigation collapse",
                statusKey: "backlog", statusLabel: "Backlog",
                priorityLevel: 4, agentName: nil,
                labels: ["navigation"],
                lastEvent: nil, lastEventTime: nil,
                tokenCount: nil, isSelected: false
            ),
            SymphonyIssueListRowViewModel(
                id: "issue-200", identifier: "KAN-200",
                title: "Design token color contrast audit",
                statusKey: "done", statusLabel: "Done",
                priorityLevel: 3, agentName: "Codex Alpha",
                labels: ["design", "a11y"],
                lastEvent: "completed", lastEventTime: "1 hr ago",
                tokenCount: "22,800", isSelected: false
            ),
            SymphonyIssueListRowViewModel(
                id: "issue-205", identifier: "KAN-205",
                title: "Add rate limit backpressure to runtime loop",
                statusKey: "in_progress", statusLabel: "In Progress",
                priorityLevel: 1, agentName: "Codex Gamma",
                labels: ["runtime", "reliability"],
                lastEvent: "build", lastEventTime: "30 sec ago",
                tokenCount: "5,100", isSelected: false
            ),
            SymphonyIssueListRowViewModel(
                id: "issue-210", identifier: "KAN-210",
                title: "Create agent management dashboard view",
                statusKey: "ready", statusLabel: "Ready",
                priorityLevel: 2, agentName: nil,
                labels: ["agents", "dashboard"],
                lastEvent: nil, lastEventTime: nil,
                tokenCount: nil, isSelected: false
            ),
            SymphonyIssueListRowViewModel(
                id: "issue-215", identifier: "KAN-215",
                title: "Integrate Linear webhook for real-time updates",
                statusKey: "backlog", statusLabel: "Backlog",
                priorityLevel: 3, agentName: nil,
                labels: ["linear", "integration"],
                lastEvent: nil, lastEventTime: nil,
                tokenCount: nil, isSelected: false
            ),
            SymphonyIssueListRowViewModel(
                id: "issue-220", identifier: "KAN-220",
                title: "Fix retry queue exponential backoff timing",
                statusKey: "done", statusLabel: "Done",
                priorityLevel: 2, agentName: "Codex Beta",
                labels: ["runtime", "bugfix"],
                lastEvent: "completed", lastEventTime: "3 hrs ago",
                tokenCount: "14,600", isSelected: false
            )
        ])
    }
}

#Preview {
    SymphonyIssueListView(onIssueSelected: { id in
        print("Selected: \(id)")
    })
    .frame(width: 1200, height: 600)
    .background(SymphonyDesignStyle.Background.primary)
}
