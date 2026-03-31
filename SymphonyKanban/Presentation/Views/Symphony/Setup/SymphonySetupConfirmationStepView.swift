import SwiftUI

// MARK: - SymphonySetupConfirmationStepView

/// Confirmation step showing the single workspace binding that will be saved
/// before the setup flow completes.
public struct SymphonySetupConfirmationStepView: View {

    // MARK: - Parameters

    private let trackerKind: String
    private let selectedScope: SymphonySetupScopeSelectionViewModel.Option?
    private let selectedWorkspace: SymphonyWorkspaceSelectionViewModel.Selection?
    private let isSaving: Bool
    private let errorMessage: String?
    private let onComplete: () -> Void

    // MARK: - State

    @State private var appeared = false

    // MARK: - Computed

    private var trackerDisplayName: String {
        trackerKind == "linear" ? "Linear" : trackerKind.capitalized
    }

    // MARK: - Initializer

    public init(
        trackerKind: String,
        selectedScope: SymphonySetupScopeSelectionViewModel.Option?,
        selectedWorkspace: SymphonyWorkspaceSelectionViewModel.Selection? = nil,
        isSaving: Bool = false,
        errorMessage: String? = nil,
        onComplete: @escaping () -> Void
    ) {
        self.trackerKind = trackerKind
        self.selectedScope = selectedScope
        self.selectedWorkspace = selectedWorkspace
        self.isSaving = isSaving
        self.errorMessage = errorMessage
        self.onComplete = onComplete
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.xxl) {
            Spacer()

            header
            bindingCards
            if let errorMessage, errorMessage.isEmpty == false {
                errorBanner(errorMessage)
            }
            actions

            Spacer()
        }
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(SymphonyDesignStyle.Accent.green)

            Text("Ready to Connect")
                .font(SymphonyDesignStyle.Typography.title)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)

            Text("Review the scope and workspace folder that will be bound together before setup finishes.")
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .symphonyStaggerIn(index: 0, isVisible: appeared)
    }

    // MARK: - Binding Cards

    private var bindingCards: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            if let selectedScope {
                scopeCard(for: selectedScope)
            } else {
                missingCard("Choose a scope before saving this workspace binding.")
            }

            if let selectedWorkspace {
                workspaceCard(for: selectedWorkspace)
            } else {
                missingCard("Choose a workspace folder before saving this binding.")
            }
        }
    }

    private func scopeCard(
        for scope: SymphonySetupScopeSelectionViewModel.Option
    ) -> some View {
        HStack {
            SymphonyLabelChipView(
                scope.scopeKindLabel,
                color: SymphonyDesignStyle.Accent.indigo
            )

            VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xxs) {
                Text(scope.scopeName)
                    .font(SymphonyDesignStyle.Typography.headline)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)

                Text("\(trackerDisplayName) • \(scope.scopeIdentifier)")
                    .font(SymphonyDesignStyle.Typography.caption)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
            }

            Spacer()
        }
        .padding(SymphonyDesignStyle.Spacing.md)
        .symphonyCard()
        .symphonyStaggerIn(index: 1, isVisible: appeared)
    }

    private func workspaceCard(
        for workspace: SymphonyWorkspaceSelectionViewModel.Selection
    ) -> some View {
        HStack {
            SymphonyLabelChipView(
                "Folder",
                color: SymphonyDesignStyle.Accent.teal
            )

            VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xxs) {
                Text(workspace.workspaceName)
                    .font(SymphonyDesignStyle.Typography.headline)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)

                Text(workspace.workspacePath)
                    .font(SymphonyDesignStyle.Typography.caption)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                    .lineLimit(1)

                Text(workspace.resolvedWorkflowPath)
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(SymphonyDesignStyle.Spacing.md)
        .symphonyCard()
        .symphonyStaggerIn(index: 2, isVisible: appeared)
    }

    private func missingCard(_ text: String) -> some View {
        Text(text)
            .font(SymphonyDesignStyle.Typography.body)
            .foregroundStyle(SymphonyDesignStyle.Text.secondary)
            .padding(SymphonyDesignStyle.Spacing.lg)
            .symphonyCard()
    }

    // MARK: - Actions

    private var actions: some View {
        connectButton
            .symphonyStaggerIn(index: 2, isVisible: appeared)
    }

    private var connectButton: some View {
        Button(action: onComplete) {
            HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                }

                Text(isSaving ? "Saving Binding..." : "Connect Workspace")
            }
                .font(SymphonyDesignStyle.Typography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, SymphonyDesignStyle.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                        .fill(SymphonyDesignStyle.Accent.blue)
                )
        }
        .buttonStyle(.plain)
        .disabled(selectedScope == nil || selectedWorkspace == nil || isSaving)
        .opacity(selectedScope == nil || selectedWorkspace == nil || isSaving ? 0.5 : 1.0)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(SymphonyDesignStyle.Accent.coral)
            Text(message)
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
            Spacer()
        }
        .padding(SymphonyDesignStyle.Spacing.md)
        .background(SymphonyDesignStyle.Background.tertiary)
        .clipShape(
            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
        )
        .symphonyStaggerIn(index: 4, isVisible: appeared)
    }
}

// MARK: - Preview

#Preview("Complete") {
    SymphonySetupConfirmationStepView(
        trackerKind: "linear",
        selectedScope: .init(
            id: "team-eng",
            scopeKind: "team",
            scopeKindLabel: "Team",
            scopeIdentifier: "team-eng",
            scopeName: "Engineering",
            detailText: "Team key ENG"
        ),
        selectedWorkspace: .init(
            id: "/Users/dev/NaraIOS",
            workspacePath: "/Users/dev/NaraIOS",
            explicitWorkflowPath: nil,
            resolvedWorkflowPath: "/Users/dev/NaraIOS/WORKFLOW.md",
            workspaceName: "NaraIOS",
            workflowProvisioningStatus: .created
        ),
        onComplete: {}
    )
    .frame(width: 480, height: 600)
    .background(LinearGradient.symphonyBackground)
}

#Preview("Saving") {
    SymphonySetupConfirmationStepView(
        trackerKind: "linear",
        selectedScope: .init(
            id: "project-platform",
            scopeKind: "project",
            scopeKindLabel: "Project",
            scopeIdentifier: "platform",
            scopeName: "Platform Rewrite",
            detailText: "planned • Engineering"
        ),
        selectedWorkspace: .init(
            id: "/Users/dev/Platform",
            workspacePath: "/Users/dev/Platform",
            explicitWorkflowPath: nil,
            resolvedWorkflowPath: "/Users/dev/Platform/WORKFLOW.md",
            workspaceName: "Platform",
            workflowProvisioningStatus: .existing
        ),
        isSaving: true,
        onComplete: {}
    )
    .frame(width: 480, height: 600)
    .background(LinearGradient.symphonyBackground)
}

#Preview("Missing Workspace") {
    SymphonySetupConfirmationStepView(
        trackerKind: "linear",
        selectedScope: .init(
            id: "team-eng",
            scopeKind: "team",
            scopeKindLabel: "Team",
            scopeIdentifier: "team-eng",
            scopeName: "Engineering",
            detailText: "Team key ENG"
        ),
        onComplete: {}
    )
    .frame(width: 480, height: 600)
    .background(LinearGradient.symphonyBackground)
}
