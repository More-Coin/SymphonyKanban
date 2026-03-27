import SwiftUI

public struct SymphonyIssueRuntimeView: View {
    private let viewModel: SymphonyIssueRuntimeViewModel

    public init(viewModel: SymphonyIssueRuntimeViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(viewModel.title)
                    .font(.title3.weight(.semibold))
                Spacer(minLength: 16)
                Text(viewModel.stateLabel)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(SymphonyDashboardStyle.secondaryAccent.opacity(0.18)))
                    .foregroundStyle(SymphonyDashboardStyle.secondaryAccent)
            }

            detailLine(viewModel.sessionIDLabel)
            detailLine(viewModel.threadIDLabel)
            detailLine(viewModel.turnIDLabel)
            if let processLabel = viewModel.processLabel {
                detailLine(processLabel)
            }
            detailLine(viewModel.turnCountLabel)
            detailLine(viewModel.startedAtLabel)
            detailLine(viewModel.tokenLabel)
            if let lastEventLabel = viewModel.lastEventLabel {
                detailLine(lastEventLabel)
            }
            if let lastMessageLabel = viewModel.lastMessageLabel {
                detailLine(lastMessageLabel)
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

    private func detailLine(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
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
    .background(SymphonyDashboardStyle.pageBackground)
}
