import Foundation

public struct SymphonyWorkspaceSelectionService {
    private let resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase

    public init(
        resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase
    ) {
        self.resolveWorkflowConfigurationUseCase = resolveWorkflowConfigurationUseCase
    }

    public func selectWorkspace(
        workspacePath: String,
        explicitWorkflowPath: String? = nil
    ) throws -> SymphonyWorkspaceSelectionResultContract {
        let normalizedWorkspacePath = normalizedPath(from: workspacePath)
        guard normalizedWorkspacePath.isEmpty == false else {
            throw SymphonyWorkspaceSelectionApplicationError.missingWorkspacePath
        }

        let normalizedExplicitWorkflowPath = normalizedOptionalPath(from: explicitWorkflowPath)
        let workspaceLocator = SymphonyWorkspaceLocatorContract(
            currentWorkingDirectoryPath: normalizedWorkspacePath,
            explicitWorkflowPath: normalizedExplicitWorkflowPath
        )
        let workflowConfiguration = try resolveWorkflowConfigurationUseCase.resolve(workspaceLocator)

        return SymphonyWorkspaceSelectionResultContract(
            workspaceLocator: workspaceLocator,
            resolvedWorkflowPath: workflowConfiguration.workflowDefinition.resolvedPath,
            workflowProvisioningStatus: .existing
        )
    }

    private func normalizedOptionalPath(
        from rawPath: String?
    ) -> String? {
        guard let rawPath else {
            return nil
        }

        let normalizedPath = normalizedPath(from: rawPath)
        return normalizedPath.isEmpty ? nil : normalizedPath
    }

    private func normalizedPath(
        from rawPath: String
    ) -> String {
        let trimmedPath = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedPath.isEmpty == false else {
            return ""
        }

        let homeExpandedPath = NSString(string: trimmedPath).expandingTildeInPath
        return URL(fileURLWithPath: homeExpandedPath)
            .resolvingSymlinksInPath()
            .standardizedFileURL
            .path
    }
}
