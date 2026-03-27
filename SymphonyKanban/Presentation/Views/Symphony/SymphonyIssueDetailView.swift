import SwiftUI

public struct SymphonyIssueDetailView: View {
    private let viewModel: SymphonyIssueDetailViewModel

    public init(viewModel: SymphonyIssueDetailViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            if viewModel.isEmptyState {
                emptyStateCard
            } else {
                if let descriptionText = viewModel.descriptionText {
                    descriptionCard(descriptionText)
                }
                if let runtimeViewModel = viewModel.runtimeViewModel {
                    SymphonyIssueRuntimeView(viewModel: runtimeViewModel)
                }
                if let workspaceViewModel = viewModel.workspaceViewModel {
                    SymphonyWorkspaceView(viewModel: workspaceViewModel)
                }
                SymphonyLogsView(viewModel: viewModel.logsViewModel)
                SymphonyRecentEventsView(
                    title: viewModel.recentEventsSectionTitle,
                    emptyState: viewModel.recentEventsEmptyState,
                    rows: viewModel.recentEventRows
                )
                if let lastErrorTitle = viewModel.lastErrorTitle,
                   let lastErrorMessage = viewModel.lastErrorMessage {
                    lastErrorCard(title: lastErrorTitle, message: lastErrorMessage)
                }
                trackedFieldsCard
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text(viewModel.subtitle)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 16)
                Text(viewModel.stateLabel)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(SymphonyDashboardStyle.accent.opacity(0.18)))
                    .foregroundStyle(SymphonyDashboardStyle.accent)
            }

            if viewModel.labels.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.labels, id: \.self) { label in
                            Text(label)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(SymphonyDashboardStyle.surfaceOverlay)
                                )
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                if let priorityLabel = viewModel.priorityLabel {
                    Text(priorityLabel)
                        .font(.footnote.weight(.semibold))
                }
                Text(viewModel.attemptsLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(viewModel.generatedAtLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                ForEach(viewModel.metadataLines, id: \.self) { line in
                    Text(line)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let emptyStateTitle = viewModel.emptyStateTitle {
                Text(emptyStateTitle)
                    .font(.title3.weight(.semibold))
            }
            if let emptyStateMessage = viewModel.emptyStateMessage {
                Text(emptyStateMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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

    private func descriptionCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Description")
                .font(.title3.weight(.semibold))
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
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

    private func lastErrorCard(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color(red: 0.99, green: 0.72, blue: 0.58))
            ForEach(viewModel.lastErrorDetailLines, id: \.self) { line in
                Text(line)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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

    private var trackedFieldsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.trackedSectionTitle)
                .font(.title3.weight(.semibold))
            if viewModel.trackedFieldLines.isEmpty {
                Text("No tracked fields are available.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.trackedFieldLines, id: \.self) { line in
                    Text(line)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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

#Preview("Issue Detail") {
    SymphonyIssueDetailView(
        viewModel: SymphonyIssueDetailViewModel(
            issueIdentifier: "KAN-142",
            title: "Rebuild Symphony dashboard pipeline",
            subtitle: "KAN-142",
            stateLabel: "Running",
            priorityLabel: "Priority High",
            labels: ["symphony", "dashboard"],
            descriptionText: "Rebuild the dashboard presentation slice around controller, presenter, and page-level view models.",
            metadataLines: [
                "Status: Running",
                "Branch: feature/dashboard-pipeline"
            ],
            attemptsLabel: "2 restarts • retry 1",
            generatedAtLabel: "Snapshot 1 minute ago",
            runtimeViewModel: SymphonyIssueRuntimeViewModel(
                title: "Runtime",
                stateLabel: "Running",
                sessionIDLabel: "Session sess-142",
                threadIDLabel: "Thread thr-142",
                turnIDLabel: "Turn turn-9",
                processLabel: "PID 80121",
                turnCountLabel: "9 turns",
                startedAtLabel: "Started 54 minutes ago",
                lastEventLabel: "Last event tool_call",
                lastMessageLabel: "Patched dashboard presenter",
                tokenLabel: "16,000 total tokens • 12,000 in • 4,000 out"
            ),
            workspaceViewModel: SymphonyWorkspaceViewModel(
                title: "Workspace",
                pathLabel: "/tmp/symphony/workspaces/KAN-142",
                branchLabel: "feature/dashboard-pipeline",
                statusLabel: "Running"
            ),
            logsViewModel: SymphonyLogsViewModel(
                title: "Logs",
                subtitle: "Codex session output captured for this issue.",
                emptyState: "No log files are attached to this issue.",
                entries: [
                    SymphonyLogsViewModel.Entry(
                        label: "Console",
                        subtitle: "/tmp/symphony/logs/KAN-142-console.log",
                        destination: nil
                    )
                ]
            ),
            recentEventsSectionTitle: "Recent Events",
            recentEventsEmptyState: "No recent events are available.",
            recentEventRows: [
                SymphonyRecentEventRowViewModel(
                    title: "tool_call",
                    subtitle: "2 minutes ago",
                    detailLines: ["Patched dashboard presenter"]
                )
            ],
            lastErrorTitle: nil,
            lastErrorMessage: nil,
            lastErrorDetailLines: [],
            trackedSectionTitle: "Tracked Fields",
            trackedFieldLines: ["workflow: dashboard"],
            emptyStateTitle: nil,
            emptyStateMessage: nil
        )
    )
    .padding()
    .background(SymphonyDashboardStyle.pageBackground)
}

#Preview("Empty Detail") {
    SymphonyIssueDetailView(
        viewModel: SymphonyIssueDetailViewModel(
            issueIdentifier: "",
            title: "Select an issue",
            subtitle: "Choose a running or queued issue from the dashboard to inspect its runtime context.",
            stateLabel: "Idle",
            priorityLabel: nil,
            labels: [],
            descriptionText: nil,
            metadataLines: [],
            attemptsLabel: "No attempts recorded",
            generatedAtLabel: "No runtime snapshot",
            runtimeViewModel: nil,
            workspaceViewModel: nil,
            logsViewModel: SymphonyLogsViewModel(
                title: "Logs",
                subtitle: "Runtime logs appear here when a session is active.",
                emptyState: "No log files are attached to this issue.",
                entries: []
            ),
            recentEventsSectionTitle: "Recent Events",
            recentEventsEmptyState: "No recent events are available.",
            recentEventRows: [],
            lastErrorTitle: nil,
            lastErrorMessage: nil,
            lastErrorDetailLines: [],
            trackedSectionTitle: "Tracked Fields",
            trackedFieldLines: [],
            emptyStateTitle: "Issue Detail",
            emptyStateMessage: "Pick an issue from the dashboard to view runtime, workspace, logs, and event details."
        )
    )
    .padding()
    .background(SymphonyDashboardStyle.pageBackground)
}
