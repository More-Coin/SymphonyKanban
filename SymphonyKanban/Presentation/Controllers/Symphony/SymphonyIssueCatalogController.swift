import Foundation

@MainActor
public struct SymphonyIssueCatalogController {
    private let startupService: SymphonyStartupService
    private let issueCatalogWorkflowService: SymphonyIssueCatalogWorkflowService
    private let displayPreferenceService: SymphonyIssueCatalogDisplayPreferenceService
    private let presenter: SymphonyIssueCatalogPresenter
    private let currentWorkingDirectoryPath: String
    private let explicitWorkflowPath: String?
    private let previewViewModel: SymphonyIssueCatalogViewModel?

    public init(
        startupService: SymphonyStartupService,
        issueCatalogWorkflowService: SymphonyIssueCatalogWorkflowService,
        displayPreferenceService: SymphonyIssueCatalogDisplayPreferenceService,
        presenter: SymphonyIssueCatalogPresenter? = nil,
        currentWorkingDirectoryPath: String = FileManager.default.currentDirectoryPath,
        explicitWorkflowPath: String? = nil,
        previewViewModel: SymphonyIssueCatalogViewModel? = nil
    ) {
        self.startupService = startupService
        self.issueCatalogWorkflowService = issueCatalogWorkflowService
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
            issueCatalogWorkflowService: issueCatalogWorkflowService,
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
            workspaceLocator
        )
        let collection = try await issueCatalogWorkflowService.queryIssues(
            activeBindings: startupExecutionResult.activeBindings
        )

        return try makeViewModel(
            from: collection,
            selectedIssueIdentifier: selectedIssueIdentifier
        )
    }

    public func updatingIssueViewModel(
        issueIdentifier: String,
        selectedIssueIdentifier: String?
    ) async throws -> SymphonyIssueCatalogViewModel {
        if let previewViewModel {
            return previewViewModel
        }

        let startupExecutionResult = try startupService.execute(workspaceLocator)
        let collection = try await issueCatalogWorkflowService.queryIssues(
            activeBindings: startupExecutionResult.activeBindings
        )

        return try makeViewModel(
            from: collection,
            selectedIssueIdentifier: selectedIssueIdentifier,
            updatingIssueIdentifier: issueIdentifier
        )
    }

    public func updateIssueViewModel(
        _ request: SymphonyIssueUpdateRequestContract,
        selectedIssueIdentifier: String?
    ) async throws -> SymphonyIssueCatalogViewModel {
        if let previewViewModel {
            return previewViewModel
        }

        let startupExecutionResult = try startupService.execute(workspaceLocator)

        do {
            let collection = try await issueCatalogWorkflowService.updateIssue(
                request,
                activeBindings: startupExecutionResult.activeBindings
            )

            return try makeViewModel(
                from: collection,
                selectedIssueIdentifier: selectedIssueIdentifier
            )
        } catch {
            let collection = try await issueCatalogWorkflowService.queryIssues(
                activeBindings: startupExecutionResult.activeBindings
            )

            return try makeViewModel(
                from: collection,
                selectedIssueIdentifier: selectedIssueIdentifier,
                mutationErrorMessage: errorMessage(for: error)
            )
        }
    }

    public func cancelIssueViewModel(
        issueIdentifier: String,
        selectedIssueIdentifier: String?
    ) async throws -> SymphonyIssueCatalogViewModel {
        if let previewViewModel {
            return previewViewModel
        }

        let startupExecutionResult = try startupService.execute(workspaceLocator)

        do {
            let collection = try await issueCatalogWorkflowService.cancelIssue(
                issueIdentifier: issueIdentifier,
                activeBindings: startupExecutionResult.activeBindings
            )

            return try makeViewModel(
                from: collection,
                selectedIssueIdentifier: selectedIssueIdentifier
            )
        } catch {
            let collection = try await issueCatalogWorkflowService.queryIssues(
                activeBindings: startupExecutionResult.activeBindings
            )

            return try makeViewModel(
                from: collection,
                selectedIssueIdentifier: selectedIssueIdentifier,
                mutationErrorMessage: errorMessage(for: error)
            )
        }
    }

    private var workspaceLocator: SymphonyWorkspaceLocatorContract {
        SymphonyWorkspaceLocatorContract(
            currentWorkingDirectoryPath: currentWorkingDirectoryPath,
            explicitWorkflowPath: explicitWorkflowPath
        )
    }

    private func makeViewModel(
        from collection: SymphonyIssueCollectionContract,
        selectedIssueIdentifier: String?,
        mutationErrorMessage: String? = nil,
        updatingIssueIdentifier: String? = nil
    ) throws -> SymphonyIssueCatalogViewModel {
        let displayMode = try displayPreferenceService.queryDisplayMode()

        return presenter.present(
            collection,
            displayMode: displayMode,
            selectedIssueIdentifier: selectedIssueIdentifier,
            mutationErrorMessage: mutationErrorMessage,
            updatingIssueIdentifier: updatingIssueIdentifier
        )
    }

    private func errorMessage(
        for error: any Error
    ) -> String {
        if let structuredError = error as? any StructuredErrorProtocol,
           let details = structuredError.details,
           details.isEmpty == false {
            return "\(structuredError.message) \(details)"
        }

        if let structuredError = error as? any StructuredErrorProtocol {
            return structuredError.message
        }

        return error.localizedDescription
    }
}
