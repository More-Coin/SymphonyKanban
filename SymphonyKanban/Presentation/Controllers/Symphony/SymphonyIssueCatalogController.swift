import Foundation

@MainActor
public struct SymphonyIssueCatalogController {
    private let issueCatalogService: SymphonyIssueCatalogService
    private let presenter: SymphonyIssueCatalogPresenter
    private let currentWorkingDirectoryPath: String
    private let explicitWorkflowPath: String?

    public init(
        issueCatalogService: SymphonyIssueCatalogService,
        presenter: SymphonyIssueCatalogPresenter? = nil,
        currentWorkingDirectoryPath: String = FileManager.default.currentDirectoryPath,
        explicitWorkflowPath: String? = nil
    ) {
        self.issueCatalogService = issueCatalogService
        self.presenter = presenter ?? SymphonyIssueCatalogPresenter()
        self.currentWorkingDirectoryPath = currentWorkingDirectoryPath
        self.explicitWorkflowPath = explicitWorkflowPath
    }

    public func queryViewModel(
        selectedIssueIdentifier: String?
    ) async throws -> SymphonyIssueCatalogViewModel {
        let issues = try await issueCatalogService.queryIssues(
            currentWorkingDirectoryPath: currentWorkingDirectoryPath,
            explicitWorkflowPath: explicitWorkflowPath
        ).issues
        return presenter.present(
            issues,
            selectedIssueIdentifier: selectedIssueIdentifier
        )
    }
}
