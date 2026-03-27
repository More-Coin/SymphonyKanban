import SwiftUI

public struct SymphonyRunningSessionsView: View {
    private let title: String
    private let emptyState: String
    private let rows: [SymphonyRunningSessionRowViewModel]
    private let onIssueSelected: (String) -> Void

    @State private var appeared = false

    public init(
        title: String,
        emptyState: String,
        rows: [SymphonyRunningSessionRowViewModel],
        onIssueSelected: @escaping (String) -> Void = { _ in }
    ) {
        self.title = title
        self.emptyState = emptyState
        self.rows = rows
        self.onIssueSelected = onIssueSelected
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.lg) {
            SymphonySectionHeaderView(title, count: rows.count, accentColor: SymphonyDesignStyle.Accent.teal)

            if rows.isEmpty {
                SymphonyEmptyStateView(
                    icon: "bolt.slash",
                    title: "No Active Sessions",
                    message: emptyState
                )
            } else {
                VStack(spacing: SymphonyDesignStyle.Spacing.md) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        Button {
                            onIssueSelected(row.issueIdentifier)
                        } label: {
                            sessionRow(row)
                        }
                        .buttonStyle(.plain)
                        .symphonyStaggerIn(index: index, isVisible: appeared)
                    }
                }
            }
        }
        .padding(SymphonyDesignStyle.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .symphonyCard()
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }

    // MARK: - Session Row

    private func sessionRow(_ row: SymphonyRunningSessionRowViewModel) -> some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.md) {
            // Top: Identifier + Status
            HStack(alignment: .center) {
                HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    if row.statusLabel.lowercased().contains("doing") || row.statusLabel.lowercased().contains("running") {
                        SymphonyPulsingDotView(color: SymphonyDesignStyle.Accent.teal)
                    }

                    Text(row.issueIdentifier)
                        .font(SymphonyDesignStyle.Typography.headline)
                        .foregroundStyle(SymphonyDesignStyle.Text.primary)
                }

                Spacer(minLength: SymphonyDesignStyle.Spacing.lg)

                SymphonyStatusBadgeView(row.statusLabel, statusKey: row.statusLabel.lowercased(), size: .small)
            }

            // Detail
            Text(row.detailLabel)
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)

            // Event
            if let eventLabel = row.eventLabel {
                HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(SymphonyDesignStyle.Accent.teal)
                    Text(eventLabel)
                        .font(SymphonyDesignStyle.Typography.caption)
                        .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                }
            }

            // Timing + Tokens
            HStack {
                Text(row.timingLabel)
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)

                Spacer(minLength: SymphonyDesignStyle.Spacing.lg)

                Text(row.tokenLabel)
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            }
        }
        .padding(SymphonyDesignStyle.Spacing.lg)
        .symphonyCard(selected: row.isSelected)
    }
}

#Preview {
    SymphonyRunningSessionsView(
        title: "Running Sessions",
        emptyState: "No live sessions are currently active.",
        rows: [
            SymphonyRunningSessionRowViewModel(
                issueIdentifier: "KAN-142",
                statusLabel: "Doing",
                detailLabel: "Session sess-142 -- 9 turns",
                timingLabel: "Last event 2 minutes ago",
                tokenLabel: "16,000 total -- 12,000 in -- 4,000 out",
                eventLabel: "tool_call: Patched dashboard presenter",
                isSelected: true
            ),
            SymphonyRunningSessionRowViewModel(
                issueIdentifier: "KAN-177",
                statusLabel: "Review",
                detailLabel: "Session sess-177 -- 5 turns -- Retry 1",
                timingLabel: "Last event 10 minutes ago",
                tokenLabel: "11,400 total -- 8,100 in -- 3,300 out",
                eventLabel: "lint: Architecture linter passed",
                isSelected: false
            )
        ]
    )
    .padding()
    .background(SymphonyDesignStyle.Background.primary)
}
