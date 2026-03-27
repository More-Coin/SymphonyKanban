import SwiftUI

public struct SymphonyRunningSessionsView: View {
    private let title: String
    private let emptyState: String
    private let rows: [SymphonyRunningSessionRowViewModel]
    private let onIssueSelected: (String) -> Void

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
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3.weight(.semibold))

            if rows.isEmpty {
                Text(emptyState)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(rows) { row in
                        Button {
                            onIssueSelected(row.issueIdentifier)
                        } label: {
                            rowView(row)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SymphonyDashboardStyle.panelBackground)
        .overlay(
            RoundedRectangle(cornerRadius: SymphonyDashboardStyle.panelCornerRadius, style: .continuous)
                .strokeBorder(SymphonyDashboardStyle.surfaceBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: SymphonyDashboardStyle.panelCornerRadius, style: .continuous))
    }

    private func rowView(_ row: SymphonyRunningSessionRowViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.issueIdentifier)
                    .font(.headline)
                Spacer(minLength: 16)
                Text(row.statusLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SymphonyDashboardStyle.secondaryAccent)
            }

            Text(row.detailLabel)
                .font(.subheadline)

            if let eventLabel = row.eventLabel {
                Text(eventLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(row.timingLabel)
                Spacer(minLength: 16)
                Text(row.tokenLabel)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SymphonyDashboardStyle.rowBackground(isSelected: row.isSelected))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(row.isSelected ? SymphonyDashboardStyle.accent : SymphonyDashboardStyle.surfaceBorder, lineWidth: 1)
        )
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
                detailLabel: "Session sess-142 • 9 turns",
                timingLabel: "Last event 2 minutes ago",
                tokenLabel: "16,000 total • 12,000 in • 4,000 out",
                eventLabel: "tool_call: Patched dashboard presenter",
                isSelected: true
            ),
            SymphonyRunningSessionRowViewModel(
                issueIdentifier: "KAN-177",
                statusLabel: "Review",
                detailLabel: "Session sess-177 • 5 turns • Retry 1",
                timingLabel: "Last event 10 minutes ago",
                tokenLabel: "11,400 total • 8,100 in • 3,300 out",
                eventLabel: "lint: Architecture linter passed",
                isSelected: false
            )
        ]
    )
    .padding()
    .background(SymphonyDashboardStyle.pageBackground)
}
