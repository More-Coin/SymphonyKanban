import Foundation

@MainActor
public struct SymphonyWorkspaceBindingSetupController {
    private let setupService: SymphonyWorkspaceBindingSetupService

    public init(
        setupService: SymphonyWorkspaceBindingSetupService
    ) {
        self.setupService = setupService
    }

    public func saveBinding(
        workspacePath: String,
        explicitWorkflowPath: String?,
        trackerKind: String,
        selectedScope: SymphonySetupScopeSelectionViewModel.Option
    ) throws -> SymphonyWorkspaceTrackerBindingContract {
        try setupService.saveBinding(
            SymphonyWorkspaceTrackerBindingContract(
                workspacePath: workspacePath,
                explicitWorkflowPath: explicitWorkflowPath,
                trackerKind: trackerKind,
                scopeKind: selectedScope.scopeKind,
                scopeIdentifier: selectedScope.scopeIdentifier,
                scopeName: selectedScope.scopeName
            )
        )
    }

    public func saveBinding(
        selectedWorkspace: SymphonyWorkspaceSelectionViewModel.Selection,
        trackerKind: String,
        selectedScope: SymphonySetupScopeSelectionViewModel.Option
    ) throws -> SymphonyWorkspaceTrackerBindingContract {
        try saveBinding(
            workspacePath: selectedWorkspace.workspacePath,
            explicitWorkflowPath: selectedWorkspace.explicitWorkflowPath,
            trackerKind: trackerKind,
            selectedScope: selectedScope
        )
    }

    public func errorMessage(
        for error: any Error
    ) -> String {
        if let structuredError = error as? any StructuredErrorProtocol {
            guard let details = structuredError.details,
                  details.isEmpty == false else {
                return structuredError.message
            }

            return "\(structuredError.message) \(details)"
        }

        return error.localizedDescription
    }
}
