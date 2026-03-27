import SwiftUI

public struct SymphonyLogsView: View {
    private let viewModel: SymphonyLogsViewModel

    public init(viewModel: SymphonyLogsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.title)
                .font(.title3.weight(.semibold))
            Text(viewModel.subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if viewModel.entries.isEmpty {
                Text(viewModel.emptyState)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.entries) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.label)
                                .font(.headline)
                            Text(entry.subtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                            if let destination = entry.destination {
                                Text(destination)
                                    .font(.caption)
                                    .foregroundStyle(SymphonyDashboardStyle.accent)
                                    .textSelection(.enabled)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(SymphonyDashboardStyle.surfaceOverlay)
                        )
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
    SymphonyLogsView(
        viewModel: SymphonyLogsViewModel(
            title: "Logs",
            subtitle: "Codex session output captured for this issue.",
            emptyState: "No log files are attached to this issue.",
            entries: [
                SymphonyLogsViewModel.Entry(
                    label: "Console",
                    subtitle: "/tmp/symphony/logs/KAN-142-console.log",
                    destination: "file:///tmp/symphony/logs/KAN-142-console.log"
                ),
                SymphonyLogsViewModel.Entry(
                    label: "Structured Events",
                    subtitle: "/tmp/symphony/logs/KAN-142-events.jsonl",
                    destination: nil
                )
            ]
        )
    )
    .padding()
    .background(SymphonyDashboardStyle.pageBackground)
}
