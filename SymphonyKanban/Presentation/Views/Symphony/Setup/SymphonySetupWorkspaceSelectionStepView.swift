import SwiftUI

// MARK: - SymphonySetupWorkspaceSelectionStepView

/// Workspace selection step allowing the user to choose a local folder
/// that will be bound to the previously selected tracker scope.
public struct SymphonySetupWorkspaceSelectionStepView: View {

    // MARK: - Parameters

    private let workspaceSelectionController: SymphonyWorkspaceSelectionController
    private let chooseWorkspaceDirectory: @MainActor (String?) -> String?
    private let selectedScope: SymphonySetupScopeSelectionViewModel.Option?
    @Binding private var selectedWorkspace: SymphonyWorkspaceSelectionViewModel.Selection?
    private let onContinue: () -> Void

    // MARK: - State

    @State private var appeared = false
    @State private var viewModel: SymphonyWorkspaceSelectionViewModel

    // MARK: - Initializer

    public init(
        workspaceSelectionController: SymphonyWorkspaceSelectionController,
        chooseWorkspaceDirectory: @escaping @MainActor (String?) -> String?,
        selectedScope: SymphonySetupScopeSelectionViewModel.Option?,
        selectedWorkspace: Binding<SymphonyWorkspaceSelectionViewModel.Selection?>,
        onContinue: @escaping () -> Void
    ) {
        self.workspaceSelectionController = workspaceSelectionController
        self.chooseWorkspaceDirectory = chooseWorkspaceDirectory
        self.selectedScope = selectedScope
        self._selectedWorkspace = selectedWorkspace
        self.onContinue = onContinue
        _viewModel = State(
            initialValue: workspaceSelectionController.initialViewModel()
        )
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.xxl) {
            Spacer()

            titleArea
            contentArea
            actions

            Spacer()
        }
        .onAppear {
            rehydrateViewModelIfNeeded()
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }

    // MARK: - Title Area

    private var titleArea: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(SymphonyDesignStyle.Accent.teal)

            Text(viewModel.title)
                .font(SymphonyDesignStyle.Typography.title)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)

            Text(viewModel.message)
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .symphonyStaggerIn(index: 0, isVisible: appeared)
    }

    // MARK: - Content Area

    private var contentArea: some View {
        Group {
            switch viewModel.state {
            case .idle:
                idleContent
            case .selected:
                selectedContent
            case .failed:
                failedContent
            }
        }
    }

    // MARK: - Idle Content

    private var idleContent: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.md) {
            Text("No folder selected yet.")
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)

            chooseFolderButton
        }
        .padding(SymphonyDesignStyle.Spacing.lg)
        .symphonyCard()
        .symphonyStaggerIn(index: 1, isVisible: appeared)
    }

    // MARK: - Selected Content

    private var selectedContent: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.md) {
            if let selection = viewModel.selection {
                workspaceCard(for: selection)
            }

            chooseDifferentFolderButton
        }
        .symphonyStaggerIn(index: 1, isVisible: appeared)
    }

    private func workspaceCard(
        for selection: SymphonyWorkspaceSelectionViewModel.Selection
    ) -> some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.sm) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(SymphonyDesignStyle.Accent.teal)

                Text(selection.workspaceName)
                    .font(SymphonyDesignStyle.Typography.headline)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(SymphonyDesignStyle.Accent.green)
            }

            Text(selection.workspacePath)
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                .lineLimit(2)

            HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                Image(systemName: "doc.text")
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)

                Text(selection.resolvedWorkflowPath)
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                    .lineLimit(1)
            }

            HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                Image(systemName: selection.workflowProvisioningStatus == .created
                    ? "sparkles"
                    : "checkmark.seal")
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Accent.green)

                Text(selection.workflowProvisioningStatus == .created
                    ? "Created new WORKFLOW.md"
                    : "Using existing WORKFLOW.md")
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
            }
        }
        .padding(SymphonyDesignStyle.Spacing.lg)
        .symphonyCard()
    }

    // MARK: - Failed Content

    private var failedContent: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.md) {
            if let errorMessage = viewModel.errorMessage, errorMessage.isEmpty == false {
                HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(SymphonyDesignStyle.Accent.coral)
                    Text(errorMessage)
                        .font(SymphonyDesignStyle.Typography.caption)
                        .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                    Spacer()
                }
                .padding(SymphonyDesignStyle.Spacing.md)
                .background(SymphonyDesignStyle.Background.tertiary)
                .clipShape(
                    RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                )
            }

            chooseFolderButton
        }
        .padding(SymphonyDesignStyle.Spacing.lg)
        .symphonyCard()
        .symphonyStaggerIn(index: 1, isVisible: appeared)
    }

    // MARK: - Actions

    private var actions: some View {
        continueButton
            .symphonyStaggerIn(index: 2, isVisible: appeared)
    }

    private var chooseFolderButton: some View {
        Button(action: chooseFolder) {
            HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                Image(systemName: "folder.badge.plus")
                Text("Choose Folder")
            }
            .font(SymphonyDesignStyle.Typography.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, SymphonyDesignStyle.Spacing.xl)
            .padding(.vertical, SymphonyDesignStyle.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                    .fill(SymphonyDesignStyle.Accent.blue)
            )
        }
        .buttonStyle(.plain)
    }

    private var chooseDifferentFolderButton: some View {
        Button(action: chooseFolder) {
            HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                Image(systemName: "folder")
                Text("Choose Different Folder")
            }
            .font(SymphonyDesignStyle.Typography.caption)
            .foregroundStyle(SymphonyDesignStyle.Accent.blue)
        }
        .buttonStyle(.plain)
    }

    private var continueButton: some View {
        Button(action: onContinue) {
            Text("Continue")
                .font(SymphonyDesignStyle.Typography.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, SymphonyDesignStyle.Spacing.xxl)
                .padding(.vertical, SymphonyDesignStyle.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                        .fill(SymphonyDesignStyle.Accent.blue)
                )
        }
        .buttonStyle(.plain)
        .disabled(selectedWorkspace == nil)
        .opacity(selectedWorkspace == nil ? 0.5 : 1.0)
    }

    // MARK: - Helpers

    /// Syncs the local view model with the parent's `selectedWorkspace` binding
    /// so that navigating back from confirmation shows the correct visual state
    /// instead of resetting to idle.
    private func rehydrateViewModelIfNeeded() {
        if let selectedWorkspace,
           let selectedScope,
           viewModel.state == .idle {
            viewModel = workspaceSelectionController.selectWorkspace(
                workspacePath: selectedWorkspace.workspacePath,
                explicitWorkflowPath: selectedWorkspace.explicitWorkflowPath,
                selectedScope: selectedScope
            )
        }
    }

    private func chooseFolder() {
        guard let chosenPath = chooseWorkspaceDirectory(selectedWorkspace?.workspacePath) else {
            return
        }

        guard let selectedScope else {
            return
        }

        let result = workspaceSelectionController.selectWorkspace(
            workspacePath: chosenPath,
            selectedScope: selectedScope
        )

        withAnimation(SymphonyDesignStyle.Motion.smooth) {
            viewModel = result
            selectedWorkspace = result.selection
        }
    }
}

// MARK: - Preview

#Preview("Idle") {
    SymphonySetupWorkspaceSelectionStepView(
        workspaceSelectionController: SymphonyPreviewDI.makeWorkspaceSelectionController()
            .withPreviewViewModel(
                SymphonyWorkspaceSelectionViewModel(
                    state: .idle,
                    title: "Choose Workspace Folder",
                    message: "Select the local folder that should be bound to the tracker scope you just chose."
                )
            ),
        chooseWorkspaceDirectory: { _ in nil },
        selectedScope: SymphonySetupScopeSelectionViewModel.Option(
            id: "team:team-ios",
            scopeKind: "team",
            scopeKindLabel: "Team",
            scopeIdentifier: "team-ios",
            scopeName: "Nara iOS",
            detailText: nil
        ),
        selectedWorkspace: .constant(nil),
        onContinue: {}
    )
    .frame(width: 480, height: 600)
    .background(LinearGradient.symphonyBackground)
}

#Preview("Selected") {
    SymphonySetupWorkspaceSelectionStepView(
        workspaceSelectionController: SymphonyPreviewDI.makeWorkspaceSelectionController(),
        chooseWorkspaceDirectory: { _ in nil },
        selectedScope: SymphonySetupScopeSelectionViewModel.Option(
            id: "project:nara-server",
            scopeKind: "project",
            scopeKindLabel: "Project",
            scopeIdentifier: "nara-server",
            scopeName: "Nara Server",
            detailText: nil
        ),
        selectedWorkspace: .constant(
            .init(
                id: "/Preview/NaraIOS",
                workspacePath: "/Preview/NaraIOS",
                explicitWorkflowPath: nil,
                resolvedWorkflowPath: "/Preview/NaraIOS/WORKFLOW.md",
                workspaceName: "NaraIOS",
                workflowProvisioningStatus: .created
            )
        ),
        onContinue: {}
    )
    .frame(width: 480, height: 600)
    .background(LinearGradient.symphonyBackground)
}

#Preview("Failed") {
    SymphonySetupWorkspaceSelectionStepView(
        workspaceSelectionController: SymphonyPreviewDI.makeWorkspaceSelectionController()
            .withPreviewViewModel(
                SymphonyWorkspaceSelectionViewModel(
                    state: .failed,
                    title: "Choose Workspace Folder",
                    message: "The selected folder could not be validated.",
                    errorMessage: "No WORKFLOW.md was found at the expected path."
                )
            ),
        chooseWorkspaceDirectory: { _ in nil },
        selectedScope: SymphonySetupScopeSelectionViewModel.Option(
            id: "team:team-ios",
            scopeKind: "team",
            scopeKindLabel: "Team",
            scopeIdentifier: "team-ios",
            scopeName: "Nara iOS",
            detailText: nil
        ),
        selectedWorkspace: .constant(nil),
        onContinue: {}
    )
    .frame(width: 480, height: 600)
    .background(LinearGradient.symphonyBackground)
}
