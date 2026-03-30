@MainActor
public struct SymphonyWorkspaceSelectionController {
    private let workspaceSelectionService: SymphonyWorkspaceSelectionService
    private let presenter: SymphonyWorkspaceSelectionPresenter
    private let previewViewModel: SymphonyWorkspaceSelectionViewModel?

    public init(
        workspaceSelectionService: SymphonyWorkspaceSelectionService,
        presenter: SymphonyWorkspaceSelectionPresenter? = nil,
        previewViewModel: SymphonyWorkspaceSelectionViewModel? = nil
    ) {
        self.workspaceSelectionService = workspaceSelectionService
        self.presenter = presenter ?? SymphonyWorkspaceSelectionPresenter()
        self.previewViewModel = previewViewModel
    }

    public func withPreviewViewModel(
        _ previewViewModel: SymphonyWorkspaceSelectionViewModel
    ) -> SymphonyWorkspaceSelectionController {
        SymphonyWorkspaceSelectionController(
            workspaceSelectionService: workspaceSelectionService,
            presenter: presenter,
            previewViewModel: previewViewModel
        )
    }

    public func initialViewModel() -> SymphonyWorkspaceSelectionViewModel {
        previewViewModel ?? presenter.presentIdle()
    }

    public func selectWorkspace(
        workspacePath: String,
        explicitWorkflowPath: String? = nil
    ) -> SymphonyWorkspaceSelectionViewModel {
        if let previewViewModel {
            return previewViewModel
        }

        do {
            return presenter.present(
                try workspaceSelectionService.selectWorkspace(
                    workspacePath: workspacePath,
                    explicitWorkflowPath: explicitWorkflowPath
                )
            )
        } catch {
            return presenter.presentError(error)
        }
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
