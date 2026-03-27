import SwiftUI

public struct SymphonyRefreshTriggerView: View {
    private let viewModel: SymphonyRefreshTriggerViewModel
    private let onRefreshTapped: () -> Void

    public init(
        viewModel: SymphonyRefreshTriggerViewModel,
        onRefreshTapped: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onRefreshTapped = onRefreshTapped
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.lg) {
            header
            SymphonyDividerView()
            content
            SymphonyDividerView()
            actionRow
        }
        .padding(SymphonyDesignStyle.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .symphonyCard()
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: SymphonyDesignStyle.Spacing.md) {
            VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xs) {
                Text(viewModel.title)
                    .font(SymphonyDesignStyle.Typography.title3)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)
                Text(viewModel.subtitle)
                    .font(SymphonyDesignStyle.Typography.body)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
            }

            Spacer(minLength: SymphonyDesignStyle.Spacing.md)

            SymphonyStatusBadgeView(
                viewModel.statusLabel,
                statusKey: viewModel.isRefreshing ? "retrying" : "done"
            )
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.sm) {
            infoRow(icon: "antenna.radiowaves.left.and.right", text: viewModel.sourceLabel)
            if let lastRefreshLabel = viewModel.lastRefreshLabel {
                infoRow(icon: "clock.arrow.circlepath", text: lastRefreshLabel)
            }
            if let noteLabel = viewModel.noteLabel {
                infoRow(icon: "text.bubble", text: noteLabel)
            }
        }
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SymphonyDesignStyle.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                .frame(width: 14)
            Text(text)
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Action Row

    private var actionRow: some View {
        HStack {
            Button(action: onRefreshTapped) {
                HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                    Text(viewModel.primaryActionTitle)
                        .font(SymphonyDesignStyle.Typography.callout)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)
                .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.sm, style: .continuous)
                        .fill(SymphonyDesignStyle.Accent.teal)
                )
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.isPrimaryActionEnabled)
            .opacity(viewModel.isPrimaryActionEnabled ? 1.0 : 0.5)
            .accessibilityLabel(viewModel.primaryActionAccessibilityLabel)

            Spacer(minLength: SymphonyDesignStyle.Spacing.md)

            if viewModel.isRefreshing {
                HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(SymphonyDesignStyle.Accent.teal)
                    Text("Syncing...")
                        .font(SymphonyDesignStyle.Typography.micro)
                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                }
            }
        }
    }
}

#Preview("Refresh idle") {
    SymphonyRefreshTriggerView(
        viewModel: SymphonyRefreshTriggerViewModel(
            title: "Symphony Refresh",
            subtitle: "Refresh the Symphony runtime data before reviewing the next change.",
            sourceLabel: "Triggered from dashboard",
            statusLabel: "Ready",
            lastRefreshLabel: "Last refreshed 5 minutes ago",
            noteLabel: "Note: Manual refresh requested by the user.",
            primaryActionTitle: "Refresh now",
            primaryActionAccessibilityLabel: "Refresh Symphony runtime data",
            isRefreshing: false,
            isPrimaryActionEnabled: true
        )
    )
    .padding()
    .background(SymphonyDesignStyle.Background.primary)
}

#Preview("Refreshing") {
    SymphonyRefreshTriggerView(
        viewModel: SymphonyRefreshTriggerViewModel(
            title: "Symphony Refresh",
            subtitle: "Refreshing Symphony runtime data.",
            sourceLabel: "Triggered from issue detail",
            statusLabel: "Refreshing",
            lastRefreshLabel: "Last refreshed just now",
            noteLabel: nil,
            primaryActionTitle: "Refreshing...",
            primaryActionAccessibilityLabel: "Refresh Symphony runtime data in progress",
            isRefreshing: true,
            isPrimaryActionEnabled: false
        )
    )
    .padding()
    .background(SymphonyDesignStyle.Background.primary)
}
