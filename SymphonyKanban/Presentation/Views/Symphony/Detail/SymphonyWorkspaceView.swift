import SwiftUI

public struct SymphonyWorkspaceView: View {
    private let viewModel: SymphonyWorkspaceViewModel

    public init(viewModel: SymphonyWorkspaceViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.md) {
            // Header
            HStack(alignment: .center) {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(SymphonyDesignStyle.Accent.blue)

                Text(viewModel.title)
                    .font(SymphonyDesignStyle.Typography.title3)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)

                Spacer(minLength: SymphonyDesignStyle.Spacing.lg)

                SymphonyStatusBadgeView(
                    viewModel.statusLabel,
                    statusKey: viewModel.statusLabel.lowercased(),
                    size: .small
                )
            }

            SymphonyDividerView()

            // Path
            HStack(alignment: .top, spacing: SymphonyDesignStyle.Spacing.sm) {
                Image(systemName: "folder")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                    .frame(width: 16, alignment: .center)
                    .padding(.top, 2)

                Text(viewModel.pathLabel)
                    .font(SymphonyDesignStyle.Typography.code)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                    .textSelection(.enabled)
                    .lineLimit(2)
            }

            // Branch
            if let branchLabel = viewModel.branchLabel {
                HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(SymphonyDesignStyle.Accent.green.opacity(0.7))
                        .frame(width: 16, alignment: .center)

                    Text(branchLabel)
                        .font(SymphonyDesignStyle.Typography.code)
                        .foregroundStyle(SymphonyDesignStyle.Accent.green)
                }
            }
        }
        .padding(SymphonyDesignStyle.Spacing.lg)
        .symphonyCard()
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
    .background(SymphonyDesignStyle.Background.secondary)
}
