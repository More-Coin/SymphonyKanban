import Foundation

@MainActor
public struct SymphonyStartupStatusController {
    private let startupService: SymphonyStartupService
    private let presenter: SymphonyStartupStatusPresenter
    private let currentWorkingDirectoryPath: String
    private let explicitWorkflowPath: String?

    public init(
        startupService: SymphonyStartupService,
        presenter: SymphonyStartupStatusPresenter? = nil,
        currentWorkingDirectoryPath: String = FileManager.default.currentDirectoryPath,
        explicitWorkflowPath: String? = nil
    ) {
        self.startupService = startupService
        self.presenter = presenter ?? SymphonyStartupStatusPresenter()
        self.currentWorkingDirectoryPath = currentWorkingDirectoryPath
        self.explicitWorkflowPath = explicitWorkflowPath
    }

    public func queryViewModel() -> SymphonyStartupStatusViewModel {
        let workspaceLocator = SymphonyWorkspaceLocatorContract(
            currentWorkingDirectoryPath: currentWorkingDirectoryPath,
            explicitWorkflowPath: explicitWorkflowPath
        )

        do {
            return presenter.present(
                try startupService.execute(workspaceLocator)
            )
        } catch {
            return presenter.presentError(error, workspaceLocator: workspaceLocator)
        }
    }
}
