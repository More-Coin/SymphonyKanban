import SwiftUI

public struct SymphonyRuntimeSummaryView: View {
    private let viewModel: SymphonyRuntimeSummaryViewModel

    public init(viewModel: SymphonyRuntimeSummaryViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.lg) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xs) {
                    Text(viewModel.title)
                        .font(SymphonyDesignStyle.Typography.title3)
                        .foregroundStyle(SymphonyDesignStyle.Text.primary)
                    Text(viewModel.generatedAtLabel)
                        .font(SymphonyDesignStyle.Typography.caption)
                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                }
                Spacer(minLength: SymphonyDesignStyle.Spacing.lg)
                SymphonyStatusBadgeView(viewModel.statusLabel, statusKey: "running")
            }

            // Metric Tiles Grid
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 140), spacing: SymphonyDesignStyle.Spacing.md)],
                alignment: .leading,
                spacing: SymphonyDesignStyle.Spacing.md
            ) {
                SymphonyMetricTileView(
                    value: metricValue(viewModel.runningCountLabel),
                    label: metricLabel(viewModel.runningCountLabel),
                    accentColor: SymphonyDesignStyle.Accent.teal
                )
                SymphonyMetricTileView(
                    value: metricValue(viewModel.retryCountLabel),
                    label: metricLabel(viewModel.retryCountLabel),
                    accentColor: SymphonyDesignStyle.Accent.amber
                )
                SymphonyMetricTileView(
                    value: metricValue(viewModel.claimedCountLabel),
                    label: metricLabel(viewModel.claimedCountLabel),
                    accentColor: SymphonyDesignStyle.Accent.blue
                )
                SymphonyMetricTileView(
                    value: metricValue(viewModel.completedCountLabel),
                    label: metricLabel(viewModel.completedCountLabel),
                    accentColor: SymphonyDesignStyle.Accent.green
                )
                SymphonyMetricTileView(
                    value: metricValue(viewModel.totalTokensLabel),
                    label: metricLabel(viewModel.totalTokensLabel),
                    accentColor: SymphonyDesignStyle.Accent.blue
                )
                SymphonyMetricTileView(
                    value: metricValue(viewModel.runtimeDurationLabel),
                    label: metricLabel(viewModel.runtimeDurationLabel),
                    accentColor: SymphonyDesignStyle.Text.secondary
                )
                if let rateLimitLabel = viewModel.rateLimitLabel {
                    SymphonyMetricTileView(
                        value: metricValue(rateLimitLabel),
                        label: metricLabel(rateLimitLabel),
                        accentColor: SymphonyDesignStyle.Accent.lavender
                    )
                }
            }
        }
        .padding(SymphonyDesignStyle.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .symphonyCard()
    }

    // MARK: - Helpers

    /// Splits a label like "2 running" into value "2" and label "running".
    /// For compound labels like "Runtime 58m 12s", returns the numeric portion as value.
    private func metricValue(_ text: String) -> String {
        let parts = text.split(separator: " ", maxSplits: 1)
        return parts.first.map(String.init) ?? text
    }

    private func metricLabel(_ text: String) -> String {
        let parts = text.split(separator: " ", maxSplits: 1)
        if parts.count > 1 {
            return String(parts[1])
        }
        return ""
    }
}

#Preview {
    SymphonyRuntimeSummaryView(
        viewModel: SymphonyRuntimeSummaryViewModel(
            title: "Runtime Summary",
            statusLabel: "Monitoring",
            generatedAtLabel: "Updated 1 minute ago",
            runningCountLabel: "2 running",
            retryCountLabel: "1 retrying",
            claimedCountLabel: "4 claimed",
            completedCountLabel: "18 completed",
            totalTokensLabel: "42,000 total tokens",
            runtimeDurationLabel: "58m runtime",
            rateLimitLabel: "87 requests remaining"
        )
    )
    .padding()
    .background(SymphonyDesignStyle.Background.primary)
}
