import SwiftUI

public struct SymphonyIssueRuntimeView: View {
    private let viewModel: SymphonyIssueRuntimeViewModel

    public init(viewModel: SymphonyIssueRuntimeViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.lg) {
            // Header with title and state badge
            HStack(alignment: .center, spacing: SymphonyDesignStyle.Spacing.sm) {
                Text(viewModel.title)
                    .font(SymphonyDesignStyle.Typography.title3)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)

                Spacer(minLength: SymphonyDesignStyle.Spacing.lg)

                HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                    if viewModel.stateLabel.lowercased() == "running" {
                        SymphonyPulsingDotView(color: SymphonyDesignStyle.Accent.teal)
                    }
                    SymphonyStatusBadgeView(
                        viewModel.stateLabel,
                        statusKey: viewModel.stateLabel.lowercased(),
                        size: .small
                    )
                }
            }

            // Metric tiles row
            HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                SymphonyMetricTileView(
                    value: extractValue(from: viewModel.turnCountLabel),
                    label: "Turns",
                    accentColor: SymphonyDesignStyle.Accent.blue
                )
                SymphonyMetricTileView(
                    value: extractTokenCount(from: viewModel.tokenLabel),
                    label: "Tokens",
                    accentColor: SymphonyDesignStyle.Accent.lavender
                )
            }

            SymphonyDividerView()

            // Session identifiers in monospaced style
            VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.sm) {
                idRow(icon: "cpu", text: viewModel.sessionIDLabel)
                idRow(icon: "line.3.horizontal", text: viewModel.threadIDLabel)
                idRow(icon: "arrow.turn.down.right", text: viewModel.turnIDLabel)
                if let processLabel = viewModel.processLabel {
                    idRow(icon: "terminal", text: processLabel)
                }
            }

            SymphonyDividerView()

            // Timing and event info
            VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xs) {
                metaRow(icon: "clock", text: viewModel.startedAtLabel)
                metaRow(icon: "chart.bar", text: viewModel.tokenLabel)
                if let lastEventLabel = viewModel.lastEventLabel {
                    metaRow(icon: "bolt", text: lastEventLabel)
                }
                if let lastMessageLabel = viewModel.lastMessageLabel {
                    metaRow(icon: "text.bubble", text: lastMessageLabel)
                }
            }
        }
        .padding(SymphonyDesignStyle.Spacing.lg)
        .symphonyCard()
    }

    // MARK: - Helpers

    private func idRow(icon: String, text: String) -> some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                .frame(width: 16, alignment: .center)

            Text(text)
                .font(SymphonyDesignStyle.Typography.code)
                .foregroundStyle(SymphonyDesignStyle.Accent.blue.opacity(0.8))
                .textSelection(.enabled)
        }
    }

    private func metaRow(icon: String, text: String) -> some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                .frame(width: 16, alignment: .center)

            Text(text)
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
        }
    }

    private func extractValue(from label: String) -> String {
        let parts = label.split(separator: " ")
        return parts.first.map(String.init) ?? label
    }

    private func extractTokenCount(from label: String) -> String {
        let parts = label.split(separator: " ")
        return parts.first.map(String.init) ?? label
    }
}

#Preview {
    SymphonyIssueRuntimeView(
        viewModel: SymphonyIssueRuntimeViewModel(
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
        )
    )
    .padding()
    .background(SymphonyDesignStyle.Background.secondary)
}
