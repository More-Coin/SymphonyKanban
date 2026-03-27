import SwiftUI

public struct SymphonyWorkspaceView: View {
    private let viewModel: SymphonyWorkspaceViewModel

    public init(viewModel: SymphonyWorkspaceViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.title)
                .font(.title3.weight(.semibold))
            Text(viewModel.pathLabel)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            if let branchLabel = viewModel.branchLabel {
                Text("Branch \(branchLabel)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Text(viewModel.statusLabel)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(SymphonyDashboardStyle.accent)
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
    SymphonyWorkspaceView(
        viewModel: SymphonyWorkspaceViewModel(
            title: "Workspace",
            pathLabel: "/tmp/symphony/workspaces/KAN-142",
            branchLabel: "feature/dashboard-pipeline",
            statusLabel: "Running"
        )
    )
    .padding()
    .background(SymphonyDashboardStyle.pageBackground)
}
