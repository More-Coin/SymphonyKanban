import Foundation

@MainActor
public struct SymphonyIssueCatalogController {
    private let startupService: SymphonyStartupService
    private let issueCatalogService: SymphonyIssueCatalogService
    private let displayPreferenceService: SymphonyIssueCatalogDisplayPreferenceService
    private let presenter: SymphonyIssueCatalogPresenter
    private let currentWorkingDirectoryPath: String
    private let explicitWorkflowPath: String?
    private let previewViewModel: SymphonyIssueCatalogViewModel?

    public init(
        startupService: SymphonyStartupService,
        issueCatalogService: SymphonyIssueCatalogService,
        displayPreferenceService: SymphonyIssueCatalogDisplayPreferenceService,
        presenter: SymphonyIssueCatalogPresenter? = nil,
        currentWorkingDirectoryPath: String = FileManager.default.currentDirectoryPath,
        explicitWorkflowPath: String? = nil,
        previewViewModel: SymphonyIssueCatalogViewModel? = nil
    ) {
        self.startupService = startupService
        self.issueCatalogService = issueCatalogService
        self.displayPreferenceService = displayPreferenceService
        self.presenter = presenter ?? SymphonyIssueCatalogPresenter()
        self.currentWorkingDirectoryPath = currentWorkingDirectoryPath
        self.explicitWorkflowPath = explicitWorkflowPath
        self.previewViewModel = previewViewModel
    }

    public func withPreviewViewModel(
        _ previewViewModel: SymphonyIssueCatalogViewModel
    ) -> SymphonyIssueCatalogController {
        SymphonyIssueCatalogController(
            startupService: startupService,
            issueCatalogService: issueCatalogService,
            displayPreferenceService: displayPreferenceService,
            presenter: presenter,
            currentWorkingDirectoryPath: currentWorkingDirectoryPath,
            explicitWorkflowPath: explicitWorkflowPath,
            previewViewModel: previewViewModel
        )
    }

    public func queryViewModel(
        selectedIssueIdentifier: String?
    ) async throws -> SymphonyIssueCatalogViewModel {
        if let previewViewModel {
            return previewViewModel
        }

        let startupExecutionResult = try startupService.execute(
            SymphonyWorkspaceLocatorContract(
                currentWorkingDirectoryPath: currentWorkingDirectoryPath,
                explicitWorkflowPath: explicitWorkflowPath
            )
        )
        let collection = try await issueCatalogService.queryIssues(
            activeBindings: startupExecutionResult.activeBindings
        )
        let displayMode = try displayPreferenceService.queryDisplayMode()

        return presenter.present(
            collection,
            displayMode: displayMode,
            selectedIssueIdentifier: selectedIssueIdentifier
        )
    }
}
