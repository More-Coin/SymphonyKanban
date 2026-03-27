import SwiftUI

public struct SymphonyRetryQueueView: View {
    private let title: String
    private let emptyState: String
    private let rows: [SymphonyRetryRowViewModel]
    private let onIssueSelected: (String) -> Void

    public init(
        title: String,
        emptyState: String,
        rows: [SymphonyRetryRowViewModel],
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
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(row.issueIdentifier)
                                        .font(.headline)
                                    Spacer(minLength: 16)
                                    Text(row.attemptLabel)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(SymphonyDashboardStyle.accent)
                                }

                                Text(row.dueLabel)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                if let errorLabel = row.errorLabel {
                                    Text(errorLabel)
                                        .font(.footnote)
                                        .foregroundStyle(Color(red: 0.99, green: 0.72, blue: 0.58))
                                }
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
}

#Preview {
    SymphonyRetryQueueView(
        title: "Retry Queue",
        emptyState: "Nothing is waiting in the retry queue.",
        rows: [
            SymphonyRetryRowViewModel(
                issueIdentifier: "KAN-181",
                attemptLabel: "Attempt 2",
                dueLabel: "Due in 7 minutes",
                errorLabel: "Linear sync timed out during status reconciliation.",
                isSelected: true
            )
        ]
    )
    .padding()
    .background(SymphonyDashboardStyle.pageBackground)
}
