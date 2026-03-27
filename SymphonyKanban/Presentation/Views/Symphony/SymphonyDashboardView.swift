import SwiftUI

public struct SymphonyDashboardView: View {
    private let viewModel: SymphonyDashboardViewModel
    private let onIssueSelected: (String) -> Void

    public init(
        viewModel: SymphonyDashboardViewModel,
        onIssueSelected: @escaping (String) -> Void = { _ in }
    ) {
        self.viewModel = viewModel
        self.onIssueSelected = onIssueSelected
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            SymphonyRuntimeSummaryView(viewModel: viewModel.runtimeSummary)
            SymphonyRunningSessionsView(
                title: viewModel.runningSectionTitle,
                emptyState: viewModel.runningEmptyState,
                rows: viewModel.runningSessions,
                onIssueSelected: onIssueSelected
            )
            SymphonyRetryQueueView(
                title: viewModel.retrySectionTitle,
                emptyState: viewModel.retryEmptyState,
                rows: viewModel.retryQueue,
                onIssueSelected: onIssueSelected
            )
            trackedFieldsCard
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
            Text(viewModel.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var trackedFieldsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.trackedSectionTitle)
                .font(.title3.weight(.semibold))

            if viewModel.trackedFieldLines.isEmpty {
                Text("No tracked fields are available.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.trackedFieldLines, id: \.self) { line in
                        Text(line)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
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
    SymphonyDashboardView(
        viewModel: SymphonyDashboardViewModel(
            title: "Symphony Dashboard",
            subtitle: "Monitor running sessions, retries, and tracked runtime context from one surface.",
            runtimeSummary: SymphonyRuntimeSummaryViewModel(
                title: "Runtime Summary",
                statusLabel: "Monitoring",
                generatedAtLabel: "Updated 1 minute ago",
                runningCountLabel: "2 running",
                retryCountLabel: "1 retrying",
                claimedCountLabel: "4 claimed",
                completedCountLabel: "18 completed",
                totalTokensLabel: "42,000 total tokens",
                runtimeDurationLabel: "Runtime 58m 12s",
                rateLimitLabel: "Rate limits requestsRemaining=87"
            ),
            runningSectionTitle: "Running Sessions",
            runningEmptyState: "No live sessions are currently active.",
            runningSessions: [
                SymphonyRunningSessionRowViewModel(
                    issueIdentifier: "KAN-142",
                    statusLabel: "Doing",
                    detailLabel: "Session sess-142 • 9 turns",
                    timingLabel: "Last event 2 minutes ago",
                    tokenLabel: "16,000 total • 12,000 in • 4,000 out",
                    eventLabel: "tool_call: Patched dashboard presenter",
                    isSelected: true
                )
            ],
            retrySectionTitle: "Retry Queue",
            retryEmptyState: "Nothing is waiting in the retry queue.",
            retryQueue: [
                SymphonyRetryRowViewModel(
                    issueIdentifier: "KAN-181",
                    attemptLabel: "Attempt 2",
                    dueLabel: "Due in 7 minutes",
                    errorLabel: "Linear sync timed out during status reconciliation.",
                    isSelected: false
                )
            ],
            trackedSectionTitle: "Tracked Fields",
            trackedFieldLines: [
                "model: gpt-5.4",
                "workflow: dashboard"
            ]
        )
    )
    .padding()
    .background(SymphonyDashboardStyle.pageBackground)
}
