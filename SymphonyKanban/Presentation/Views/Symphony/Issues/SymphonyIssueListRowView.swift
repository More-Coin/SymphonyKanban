import SwiftUI

// MARK: - SymphonyIssueListRowView
/// Single data row in the issue list, matching header column widths.

public struct SymphonyIssueListRowView: View {
    let row: SymphonyIssueListRowViewModel
    let index: Int
    let isHovered: Bool
    let onSelected: () -> Void
    let onHover: (Bool) -> Void

    public init(
        row: SymphonyIssueListRowViewModel,
        index: Int,
        isHovered: Bool,
        onSelected: @escaping () -> Void,
        onHover: @escaping (Bool) -> Void
    ) {
        self.row = row
        self.index = index
        self.isHovered = isHovered
        self.onSelected = onSelected
        self.onHover = onHover
    }

    public var body: some View {
        Button(action: onSelected) {
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

                // Scope
                scopeCell
                    .frame(width: 110, alignment: .leading)

                // Status
                SymphonyStatusBadgeView(row.statusLabel, statusKey: row.statusKey, size: .small)
                    .frame(width: 100, alignment: .leading)

                // Agent
                agentCell
                    .frame(width: 110, alignment: .leading)

                // Labels
                labelsCell
                    .frame(width: 140, alignment: .leading)

                // Last Event
                lastEventCell
                    .frame(width: 150, alignment: .leading)

                // Tokens
                Text(row.tokenCount ?? "-")
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                    .frame(width: 90, alignment: .trailing)
            }
            .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)
            .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
            .background(rowBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover(perform: onHover)
    }

    // MARK: - Cells

    @ViewBuilder
    private var scopeCell: some View {
        if let scopeName = row.scopeName, scopeName.isEmpty == false {
            SymphonyLabelChipView(scopeName, color: SymphonyDesignStyle.Accent.indigo)
        } else {
            Text("-")
                .font(SymphonyDesignStyle.Typography.micro)
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
        }
    }

    @ViewBuilder
    private var agentCell: some View {
        if let name = row.agentName {
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

    private var labelsCell: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.xxs) {
            ForEach(row.labels.prefix(2), id: \.self) { label in
                SymphonyLabelChipView(label)
            }
            if row.labels.count > 2 {
                Text("+\(row.labels.count - 2)")
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            }
        }
    }

    private var lastEventCell: some View {
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
    }

    // MARK: - Background

    @ViewBuilder
    private var rowBackground: some View {
        if row.isSelected {
            SymphonyDesignStyle.Accent.blue.opacity(0.10)
        } else if isHovered {
            SymphonyDesignStyle.Background.elevated
        } else if index.isMultiple(of: 2) {
            SymphonyDesignStyle.Background.secondary
        } else {
            SymphonyDesignStyle.Background.tertiary
        }
    }
}
