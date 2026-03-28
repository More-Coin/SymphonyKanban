import Foundation

public struct SymphonyCodexConnectionController {
    private let codexConnectionService: SymphonyCodexConnectionService
    private let presenter: SymphonyCodexConnectionPresenter
    private let currentWorkingDirectoryPath: String
    private let explicitWorkflowPath: String?

    public init(
        codexConnectionService: SymphonyCodexConnectionService,
        presenter: SymphonyCodexConnectionPresenter? = nil,
        currentWorkingDirectoryPath: String = FileManager.default.currentDirectoryPath,
        explicitWorkflowPath: String? = nil
    ) {
        self.codexConnectionService = codexConnectionService
        self.presenter = presenter ?? SymphonyCodexConnectionPresenter()
        self.currentWorkingDirectoryPath = currentWorkingDirectoryPath
        self.explicitWorkflowPath = explicitWorkflowPath
    }

    public func queryViewModel() -> SymphonyCodexConnectionViewModel {
        presenter.present(
            codexConnectionService.queryStatus(
                currentWorkingDirectoryPath: currentWorkingDirectoryPath,
                explicitWorkflowPath: explicitWorkflowPath
            )
        )
    }
}
