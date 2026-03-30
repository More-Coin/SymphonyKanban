import Foundation

public struct SymphonyCodexConnectionController {
    private let codexConnectionService: SymphonyCodexConnectionService
    private let presenter: SymphonyCodexConnectionPresenter
    private let currentWorkingDirectoryPath: String
    private let explicitWorkflowPath: String?
    private let previewViewModel: SymphonyCodexConnectionViewModel?

    public init(
        codexConnectionService: SymphonyCodexConnectionService,
        presenter: SymphonyCodexConnectionPresenter? = nil,
        currentWorkingDirectoryPath: String = FileManager.default.currentDirectoryPath,
        explicitWorkflowPath: String? = nil,
        previewViewModel: SymphonyCodexConnectionViewModel? = nil
    ) {
        self.codexConnectionService = codexConnectionService
        self.presenter = presenter ?? SymphonyCodexConnectionPresenter()
        self.currentWorkingDirectoryPath = currentWorkingDirectoryPath
        self.explicitWorkflowPath = explicitWorkflowPath
        self.previewViewModel = previewViewModel
    }

    public func withPreviewViewModel(
        _ previewViewModel: SymphonyCodexConnectionViewModel
    ) -> SymphonyCodexConnectionController {
        SymphonyCodexConnectionController(
            codexConnectionService: codexConnectionService,
            presenter: presenter,
            currentWorkingDirectoryPath: currentWorkingDirectoryPath,
            explicitWorkflowPath: explicitWorkflowPath,
            previewViewModel: previewViewModel
        )
    }

    public func queryViewModel() -> SymphonyCodexConnectionViewModel {
        if let previewViewModel {
            return previewViewModel
        }

        return presenter.present(
            codexConnectionService.queryStatus(
                currentWorkingDirectoryPath: currentWorkingDirectoryPath,
                explicitWorkflowPath: explicitWorkflowPath
            )
        )
    }
}
