import Foundation

@MainActor
public struct SymphonyStartupStatusController {
    private let startupService: SymphonyStartupService
    private let presenter: SymphonyStartupStatusPresenter
    private let currentWorkingDirectoryPath: String
    private let explicitWorkflowPath: String?
    private let previewViewModel: SymphonyStartupStatusViewModel?

    public init(
        startupService: SymphonyStartupService,
        presenter: SymphonyStartupStatusPresenter? = nil,
        currentWorkingDirectoryPath: String = FileManager.default.currentDirectoryPath,
        explicitWorkflowPath: String? = nil,
        previewViewModel: SymphonyStartupStatusViewModel? = nil
    ) {
        self.startupService = startupService
        self.presenter = presenter ?? SymphonyStartupStatusPresenter()
        self.currentWorkingDirectoryPath = currentWorkingDirectoryPath
        self.explicitWorkflowPath = explicitWorkflowPath
        self.previewViewModel = previewViewModel
    }

    public func withPreviewViewModel(
        _ previewViewModel: SymphonyStartupStatusViewModel
    ) -> SymphonyStartupStatusController {
        SymphonyStartupStatusController(
            startupService: startupService,
            presenter: presenter,
            currentWorkingDirectoryPath: currentWorkingDirectoryPath,
            explicitWorkflowPath: explicitWorkflowPath,
            previewViewModel: previewViewModel
        )
    }

    public func queryViewModel() -> SymphonyStartupStatusViewModel {
        queryViewModel(
            for: SymphonyWorkspaceLocatorContract(
                currentWorkingDirectoryPath: currentWorkingDirectoryPath,
                explicitWorkflowPath: explicitWorkflowPath
            )
        )
    }

    public func withWorkspaceLocator(
        _ workspaceLocator: SymphonyWorkspaceLocatorContract
    ) -> SymphonyStartupStatusController {
        SymphonyStartupStatusController(
            startupService: startupService,
            presenter: presenter,
            currentWorkingDirectoryPath: workspaceLocator.currentWorkingDirectoryPath,
            explicitWorkflowPath: workspaceLocator.explicitWorkflowPath,
            previewViewModel: previewViewModel
        )
    }

    public func queryViewModel(
        currentWorkingDirectoryPath: String,
        explicitWorkflowPath: String? = nil
    ) -> SymphonyStartupStatusViewModel {
        queryViewModel(
            for: SymphonyWorkspaceLocatorContract(
                currentWorkingDirectoryPath: currentWorkingDirectoryPath,
                explicitWorkflowPath: explicitWorkflowPath
            )
        )
    }

    public func queryViewModel(
        for workspaceLocator: SymphonyWorkspaceLocatorContract
    ) -> SymphonyStartupStatusViewModel {
        if let previewViewModel {
            return previewViewModel
        }

        do {
            return presenter.present(
                try startupService.execute(workspaceLocator)
            )
        } catch {
            return presenter.presentError(error, workspaceLocator: workspaceLocator)
        }
    }
}
