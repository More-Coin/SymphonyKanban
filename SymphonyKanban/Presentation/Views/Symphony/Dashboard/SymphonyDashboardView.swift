import SwiftUI

public struct SymphonyDashboardView: View {
    private let viewModel: SymphonyDashboardViewModel
    private let onIssueSelected: (String) -> Void

    @State private var appeared = false

    public init(
        viewModel: SymphonyDashboardViewModel,
        onIssueSelected: @escaping (String) -> Void = { _ in }
    ) {
        self.viewModel = viewModel
        self.onIssueSelected = onIssueSelected
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xl) {
                header
                    .symphonyStaggerIn(index: 0, isVisible: appeared)

                SymphonyRuntimeSummaryView(viewModel: viewModel.runtimeSummary)
                    .symphonyStaggerIn(index: 1, isVisible: appeared)

                SymphonyRunningSessionsView(
                    title: viewModel.runningSectionTitle,
                    emptyState: viewModel.runningEmptyState,
                    rows: viewModel.runningSessions,
                    onIssueSelected: onIssueSelected
                )
                .symphonyStaggerIn(index: 2, isVisible: appeared)

                SymphonyRetryQueueView(
                    title: viewModel.retrySectionTitle,
                    emptyState: viewModel.retryEmptyState,
                    rows: viewModel.retryQueue,
                    onIssueSelected: onIssueSelected
                )
                .symphonyStaggerIn(index: 3, isVisible: appeared)

                trackedFieldsCard
                    .symphonyStaggerIn(index: 4, isVisible: appeared)
            }
            .padding(SymphonyDesignStyle.Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(SymphonyDesignStyle.Background.secondary)
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.sm) {
            Text(viewModel.title)
                .font(SymphonyDesignStyle.Typography.largeTitle)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)
            Text(viewModel.subtitle)
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
        }
    }

    // MARK: - Tracked Fields Card

    private var trackedFieldsCard: some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.md) {
            SymphonySectionHeaderView(viewModel.trackedSectionTitle)

            if viewModel.trackedFieldLines.isEmpty {
                Text("No tracked fields are available.")
                    .font(SymphonyDesignStyle.Typography.caption)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            } else {
                VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.sm) {
                    ForEach(viewModel.trackedFieldLines, id: \.self) { line in
                        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                            Circle()
                                .fill(SymphonyDesignStyle.Text.tertiary)
                                .frame(width: 4, height: 4)
                            Text(line)
                                .font(SymphonyDesignStyle.Typography.code)
                                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                        }
                    }
                }
            }
        }
        .padding(SymphonyDesignStyle.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .symphonyCard()
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
                runtimeDurationLabel: "58m runtime",
                rateLimitLabel: "87 requests remaining"
            ),
            runningSectionTitle: "Running Sessions",
            runningEmptyState: "No live sessions are currently active.",
            runningSessions: [
                SymphonyRunningSessionRowViewModel(
                    issueIdentifier: "KAN-142",
                    statusLabel: "Doing",
                    detailLabel: "Session sess-142 -- 9 turns",
                    timingLabel: "Last event 2 minutes ago",
                    tokenLabel: "16,000 total -- 12,000 in -- 4,000 out",
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
    .frame(width: 800, height: 900)
    .background(SymphonyDesignStyle.Background.primary)
}
