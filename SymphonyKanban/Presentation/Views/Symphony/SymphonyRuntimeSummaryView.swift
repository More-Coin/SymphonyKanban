import SwiftUI

public struct SymphonyRuntimeSummaryView: View {
    private let viewModel: SymphonyRuntimeSummaryViewModel

    public init(viewModel: SymphonyRuntimeSummaryViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.title)
                        .font(.title3.weight(.semibold))
                    Text(viewModel.generatedAtLabel)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 16)
                Text(viewModel.statusLabel)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(SymphonyDashboardStyle.secondaryAccent.opacity(0.18)))
                    .foregroundStyle(SymphonyDashboardStyle.secondaryAccent)
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                metricChip(viewModel.runningCountLabel)
                metricChip(viewModel.retryCountLabel)
                metricChip(viewModel.claimedCountLabel)
                metricChip(viewModel.completedCountLabel)
                metricChip(viewModel.totalTokensLabel)
                metricChip(viewModel.runtimeDurationLabel)
                if let rateLimitLabel = viewModel.rateLimitLabel {
                    metricChip(rateLimitLabel)
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

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 140), spacing: 12, alignment: .leading)]
    }

    private func metricChip(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(SymphonyDashboardStyle.surfaceOverlay)
            )
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
            runtimeDurationLabel: "Runtime 58m 12s",
            rateLimitLabel: "Rate limits requestsRemaining=87, tokensRemaining=412000"
        )
    )
    .padding()
    .background(SymphonyDashboardStyle.pageBackground)
}
