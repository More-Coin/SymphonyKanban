import Foundation

@MainActor
public struct SymphonyWorkspaceBindingManagementController {
    private let managementService: SymphonyWorkspaceBindingManagementService
    private let setupController: SymphonyWorkspaceBindingSetupController
    private let presenter: SymphonyWorkspaceBindingManagementPresenter
    private let currentWorkingDirectoryPath: String
    private let explicitWorkflowPath: String?
    private let previewViewModel: SymphonyWorkspaceBindingManagementViewModel?

    public init(
        managementService: SymphonyWorkspaceBindingManagementService,
        setupController: SymphonyWorkspaceBindingSetupController,
        presenter: SymphonyWorkspaceBindingManagementPresenter? = nil,
        currentWorkingDirectoryPath: String = FileManager.default.currentDirectoryPath,
        explicitWorkflowPath: String? = nil,
        previewViewModel: SymphonyWorkspaceBindingManagementViewModel? = nil
    ) {
        self.managementService = managementService
        self.setupController = setupController
        self.presenter = presenter ?? SymphonyWorkspaceBindingManagementPresenter()
        self.currentWorkingDirectoryPath = currentWorkingDirectoryPath
        self.explicitWorkflowPath = explicitWorkflowPath
        self.previewViewModel = previewViewModel
    }

    public func withPreviewViewModel(
        _ previewViewModel: SymphonyWorkspaceBindingManagementViewModel
    ) -> SymphonyWorkspaceBindingManagementController {
        SymphonyWorkspaceBindingManagementController(
            managementService: managementService,
            setupController: setupController,
            presenter: presenter,
            currentWorkingDirectoryPath: currentWorkingDirectoryPath,
            explicitWorkflowPath: explicitWorkflowPath,
            previewViewModel: previewViewModel
        )
    }

    public func queryViewModel(
        bannerMessage: String? = nil
    ) -> SymphonyWorkspaceBindingManagementViewModel {
        if let previewViewModel {
            guard let bannerMessage,
                  bannerMessage.isEmpty == false else {
                return previewViewModel
            }

            return SymphonyWorkspaceBindingManagementViewModel(
                title: previewViewModel.title,
                subtitle: previewViewModel.subtitle,
                bannerMessage: bannerMessage,
                cards: previewViewModel.cards
            )
        }

        do {
            return presenter.present(
                try queryActiveBindingContexts(),
                bannerMessage: bannerMessage
            )
        } catch {
            return presenter.presentError(error)
        }
    }

    public func removeBinding(
        forWorkspacePath workspacePath: String
    ) -> SymphonyWorkspaceBindingManagementViewModel {
        if let previewViewModel { return previewViewModel }

        do {
            return presenter.present(
                try managementService.removeBindingAndQueryActiveBindingContexts(
                    forWorkspacePath: workspacePath,
                    workspaceLocator: workspaceLocator
                )
            )
        } catch {
            return viewModelRetainingCurrentBindings(for: error)
        }
    }

    public func updateBindingWorkspace(
        existingWorkspacePath: String,
        newWorkspacePath: String,
        explicitWorkflowPath: String?,
        trackerKind: String,
        scopeKind: String,
        scopeIdentifier: String,
        scopeName: String
    ) -> SymphonyWorkspaceBindingManagementViewModel {
        if let previewViewModel { return previewViewModel }

        do {
            _ = try managementService.removeBindingAndQueryActiveBindingContexts(
                forWorkspacePath: existingWorkspacePath,
                workspaceLocator: workspaceLocator
            )
            _ = try setupController.saveBinding(
                workspacePath: newWorkspacePath,
                explicitWorkflowPath: explicitWorkflowPath,
                trackerKind: trackerKind,
                selectedScope: SymphonySetupScopeSelectionViewModel.Option(
                    id: "\(scopeKind):\(scopeIdentifier)",
                    scopeKind: scopeKind,
                    scopeKindLabel: scopeKind == "project" ? "Project" : "Team",
                    scopeIdentifier: scopeIdentifier,
                    scopeName: scopeName,
                    detailText: nil
                )
            )
            return queryViewModel()
        } catch {
            return viewModelRetainingCurrentBindings(for: error)
        }
    }

    public func errorMessage(for error: any Error) -> String {
        setupController.errorMessage(for: error)
    }

    private func viewModelRetainingCurrentBindings(
        for error: any Error
    ) -> SymphonyWorkspaceBindingManagementViewModel {
        let bannerMessage = errorMessage(for: error)

        do {
            return presenter.present(
                try queryActiveBindingContexts(),
                bannerMessage: bannerMessage
            )
        } catch {
            return presenter.presentError(error)
        }
    }

    private func queryActiveBindingContexts() throws -> [SymphonyActiveWorkspaceBindingContextContract] {
        try managementService.queryActiveBindingContexts(for: workspaceLocator)
    }

    private var workspaceLocator: SymphonyWorkspaceLocatorContract {
        SymphonyWorkspaceLocatorContract(
            currentWorkingDirectoryPath: currentWorkingDirectoryPath,
            explicitWorkflowPath: explicitWorkflowPath
        )
    }
}
