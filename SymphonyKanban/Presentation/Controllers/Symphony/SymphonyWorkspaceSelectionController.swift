@MainActor
public struct SymphonyWorkspaceSelectionController {
    private let workspaceProvisioningService: SymphonyWorkspaceWorkflowProvisioningService
    private let presenter: SymphonyWorkspaceSelectionPresenter
    private let previewViewModel: SymphonyWorkspaceSelectionViewModel?

    public init(
        workspaceProvisioningService: SymphonyWorkspaceWorkflowProvisioningService,
        presenter: SymphonyWorkspaceSelectionPresenter? = nil,
        previewViewModel: SymphonyWorkspaceSelectionViewModel? = nil
    ) {
        self.workspaceProvisioningService = workspaceProvisioningService
        self.presenter = presenter ?? SymphonyWorkspaceSelectionPresenter()
        self.previewViewModel = previewViewModel
    }

    public func withPreviewViewModel(
        _ previewViewModel: SymphonyWorkspaceSelectionViewModel
    ) -> SymphonyWorkspaceSelectionController {
        SymphonyWorkspaceSelectionController(
            workspaceProvisioningService: workspaceProvisioningService,
            presenter: presenter,
            previewViewModel: previewViewModel
        )
    }

    public func initialViewModel() -> SymphonyWorkspaceSelectionViewModel {
        previewViewModel ?? presenter.presentIdle()
    }

    public func selectWorkspace(
        workspacePath: String,
        explicitWorkflowPath: String? = nil,
        selectedScope: SymphonyTrackerScopeOptionContract
    ) -> SymphonyWorkspaceSelectionViewModel {
        if let previewViewModel {
            return previewViewModel
        }

        do {
            return presenter.present(
                try workspaceProvisioningService.provisionWorkspace(
                    workspacePath: workspacePath,
                    explicitWorkflowPath: explicitWorkflowPath,
                    selectedScope: selectedScope
                )
            )
        } catch {
            return presenter.presentError(error)
        }
    }

    public func selectWorkspace(
        workspacePath: String,
        explicitWorkflowPath: String? = nil,
        selectedScope: SymphonySetupScopeSelectionViewModel.Option
    ) -> SymphonyWorkspaceSelectionViewModel {
        selectWorkspace(
            workspacePath: workspacePath,
            explicitWorkflowPath: explicitWorkflowPath,
            selectedScope: SymphonyTrackerScopeOptionContract(
                id: selectedScope.id,
                scopeKind: selectedScope.scopeKind,
                scopeIdentifier: selectedScope.scopeIdentifier,
                scopeName: selectedScope.scopeName,
                detailText: selectedScope.detailText
            )
        )
    }

    public func selectWorkspace(
        workspacePath: String,
        explicitWorkflowPath: String? = nil,
        scopeKind: String,
        scopeIdentifier: String,
        scopeName: String
    ) -> SymphonyWorkspaceSelectionViewModel {
        selectWorkspace(
            workspacePath: workspacePath,
            explicitWorkflowPath: explicitWorkflowPath,
            selectedScope: SymphonyTrackerScopeOptionContract(
                id: "\(scopeKind):\(scopeIdentifier)",
                scopeKind: scopeKind,
                scopeIdentifier: scopeIdentifier,
                scopeName: scopeName
            )
        )
    }

    public func workspaceLocator(
        for selection: SymphonyWorkspaceSelectionViewModel.Selection
    ) -> SymphonyWorkspaceLocatorContract {
        SymphonyWorkspaceLocatorContract(
            currentWorkingDirectoryPath: selection.workspacePath,
            explicitWorkflowPath: selection.explicitWorkflowPath
        )
    }
}
