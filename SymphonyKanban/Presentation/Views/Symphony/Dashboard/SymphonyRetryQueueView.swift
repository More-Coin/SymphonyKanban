import SwiftUI

public struct SymphonyRetryQueueView: View {
    private let title: String
    private let emptyState: String
    private let rows: [SymphonyRetryRowViewModel]
    private let onIssueSelected: (String) -> Void

    @State private var appeared = false

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
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.lg) {
            SymphonySectionHeaderView(title, count: rows.count, accentColor: SymphonyDesignStyle.Accent.amber)

            if rows.isEmpty {
                SymphonyEmptyStateView(
                    icon: "arrow.clockwise",
                    title: "Queue Empty",
                    message: emptyState
                )
            } else {
                VStack(spacing: SymphonyDesignStyle.Spacing.md) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        Button {
                            onIssueSelected(row.issueIdentifier)
                        } label: {
                            retryRow(row)
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

    // MARK: - Retry Row

    private func retryRow(_ row: SymphonyRetryRowViewModel) -> some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.md) {
            // Header: Identifier + Attempt badge
            HStack {
                Text(row.issueIdentifier)
                    .font(SymphonyDesignStyle.Typography.headline)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)

                Spacer(minLength: SymphonyDesignStyle.Spacing.lg)

                // Attempt counter badge
                Text(row.attemptLabel)
                    .font(SymphonyDesignStyle.Typography.micro)
                    .fontWeight(.bold)
                    .foregroundStyle(SymphonyDesignStyle.Accent.amber)
                    .padding(.horizontal, SymphonyDesignStyle.Spacing.sm)
                    .padding(.vertical, SymphonyDesignStyle.Spacing.xs)
                    .background(
                        Capsule(style: .continuous)
                            .fill(SymphonyDesignStyle.Accent.amber.opacity(0.14))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(SymphonyDesignStyle.Accent.amber.opacity(0.20), lineWidth: 0.5)
                    )
            }

            // Due label
            HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                    .foregroundStyle(SymphonyDesignStyle.Accent.amber)
                Text(row.dueLabel)
                    .font(SymphonyDesignStyle.Typography.caption)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
            }

            // Error message in coral
            if let errorLabel = row.errorLabel {
                HStack(alignment: .top, spacing: SymphonyDesignStyle.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(SymphonyDesignStyle.Accent.coral)

                    Text(errorLabel)
                        .font(SymphonyDesignStyle.Typography.caption)
                        .foregroundStyle(SymphonyDesignStyle.Accent.coral.opacity(0.85))
                }
            }
        }
        .padding(SymphonyDesignStyle.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                .fill(SymphonyDesignStyle.Background.tertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                .strokeBorder(
                    row.isSelected
                        ? SymphonyDesignStyle.Accent.amber.opacity(0.4)
                        : SymphonyDesignStyle.Accent.amber.opacity(0.12),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous))
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
    .background(SymphonyDesignStyle.Background.primary)
}
