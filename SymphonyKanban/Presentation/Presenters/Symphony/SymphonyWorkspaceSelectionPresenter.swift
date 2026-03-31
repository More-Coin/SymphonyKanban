import Foundation

public struct SymphonyWorkspaceSelectionPresenter {
    public init() {}

    public func presentIdle() -> SymphonyWorkspaceSelectionViewModel {
        SymphonyWorkspaceSelectionViewModel(
            state: .idle,
            title: "Select Workspace",
            message: "Choose the local workspace folder Symphony should bind to the selected tracker scope."
        )
    }

    public func present(
        _ result: SymphonyWorkspaceSelectionResultContract
    ) -> SymphonyWorkspaceSelectionViewModel {
        let selection = makeSelection(from: result)
        let message: String

        switch result.workflowProvisioningStatus {
        case .created:
            message = "Symphony created a new WORKFLOW.md file and validated this workspace folder."
        case .existing:
            message = "Symphony validated the existing workflow file for this workspace folder."
        }

        return SymphonyWorkspaceSelectionViewModel(
            state: .selected,
            title: "Select Workspace",
            message: message,
            selection: selection
        )
    }

    public func presentError(
        _ error: any Error
    ) -> SymphonyWorkspaceSelectionViewModel {
        SymphonyWorkspaceSelectionViewModel(
            state: .failed,
            title: "Select Workspace",
            message: "Symphony could not validate the selected workspace folder.",
            errorMessage: structuredMessage(for: error)
        )
    }

    private func makeSelection(
        from result: SymphonyWorkspaceSelectionResultContract
    ) -> SymphonyWorkspaceSelectionViewModel.Selection {
        let workspacePath = result.workspaceLocator.currentWorkingDirectoryPath
        let workspaceURL = URL(fileURLWithPath: workspacePath, isDirectory: true)
        let workspaceName = workspaceURL.lastPathComponent.isEmpty
            ? workspacePath
            : workspaceURL.lastPathComponent

        return SymphonyWorkspaceSelectionViewModel.Selection(
            id: workspacePath,
            workspacePath: workspacePath,
            explicitWorkflowPath: result.workspaceLocator.explicitWorkflowPath,
            resolvedWorkflowPath: result.resolvedWorkflowPath,
            workspaceName: workspaceName,
            workflowProvisioningStatus: result.workflowProvisioningStatus
        )
    }

    private func structuredMessage(
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
