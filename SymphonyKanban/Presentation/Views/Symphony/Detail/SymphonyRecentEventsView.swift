import SwiftUI

public struct SymphonyRecentEventsView: View {
    private let title: String
    private let emptyState: String
    private let rows: [SymphonyRecentEventRowViewModel]

    @State private var isVisible = false

    public init(
        title: String,
        emptyState: String,
        rows: [SymphonyRecentEventRowViewModel]
    ) {
        self.title = title
        self.emptyState = emptyState
        self.rows = rows
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.md) {
            // Header
            SymphonySectionHeaderView(title, count: rows.isEmpty ? nil : rows.count)

            if rows.isEmpty {
                HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                    Text(emptyState)
                        .font(SymphonyDesignStyle.Typography.caption)
                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                }
                .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
            } else {
                // Timeline
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        timelineEntry(row: row, index: index, isLast: index == rows.count - 1)
                            .symphonyStaggerIn(index: index, isVisible: isVisible)
                    }
                }
            }
        }
        .padding(SymphonyDesignStyle.Spacing.lg)
        .symphonyCard()
        .onAppear {
            isVisible = true
        }
    }

    private func timelineEntry(row: SymphonyRecentEventRowViewModel, index: Int, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: SymphonyDesignStyle.Spacing.md) {
            // Timeline spine: dot + line
            VStack(spacing: 0) {
                Circle()
                    .fill(eventColor(for: row.title))
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)

                if !isLast {
                    Rectangle()
                        .fill(SymphonyDesignStyle.Border.default)
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 8)

            // Event card
            VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    // Event type badge
                    Text(row.title)
                        .font(SymphonyDesignStyle.Typography.micro)
                        .fontWeight(.bold)
                        .foregroundStyle(eventColor(for: row.title))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.xs, style: .continuous)
                                .fill(eventColor(for: row.title).opacity(0.12))
                        )

                    Spacer()

                    // Timestamp
                    Text(row.subtitle)
                        .font(SymphonyDesignStyle.Typography.micro)
                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                }

                ForEach(row.detailLines, id: \.self) { line in
                    Text(line)
                        .font(SymphonyDesignStyle.Typography.caption)
                        .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                        .lineLimit(2)
                }
            }
            .padding(SymphonyDesignStyle.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.sm, style: .continuous)
                    .fill(SymphonyDesignStyle.Background.elevated.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.sm, style: .continuous)
                    .strokeBorder(SymphonyDesignStyle.Border.subtle, lineWidth: 0.5)
            )
            .padding(.bottom, isLast ? 0 : SymphonyDesignStyle.Spacing.sm)
        }
    }

    private func eventColor(for type: String) -> Color {
        switch type.lowercased() {
        case "tool_call": return SymphonyDesignStyle.Accent.blue
        case "build": return SymphonyDesignStyle.Accent.green
        case "lint": return SymphonyDesignStyle.Accent.lavender
        case "error": return SymphonyDesignStyle.Accent.coral
        case "retry": return SymphonyDesignStyle.Accent.amber
        case "completed": return SymphonyDesignStyle.Accent.green
        default: return SymphonyDesignStyle.Accent.teal
        }
    }
}

#Preview {
    SymphonyRecentEventsView(
        title: "Recent Events",
        emptyState: "No recent events are available.",
        rows: [
            SymphonyRecentEventRowViewModel(
                title: "tool_call",
                subtitle: "2 minutes ago",
                detailLines: [
                    "Patched dashboard presenter",
                    "file: Presentation/Presenters/Symphony/SymphonyDashboardPresenter.swift"
                ]
            ),
            SymphonyRecentEventRowViewModel(
                title: "lint",
                subtitle: "8 minutes ago",
                detailLines: [
                    "Architecture linter passed"
                ]
            ),
            SymphonyRecentEventRowViewModel(
                title: "build",
                subtitle: "12 minutes ago",
                detailLines: [
                    "Build succeeded in 34s"
                ]
            ),
            SymphonyRecentEventRowViewModel(
                title: "error",
                subtitle: "15 minutes ago",
                detailLines: [
                    "Type mismatch in SymphonyDashboardView"
                ]
            )
        ]
    )
    .padding()
    .background(SymphonyDesignStyle.Background.secondary)
}
