import Foundation

public struct SymphonyWorkspaceBindingResolutionService {
    private let queryWorkspaceTrackerBindingsUseCase: QuerySymphonyWorkspaceTrackerBindingsUseCase

    public init(
        queryWorkspaceTrackerBindingsUseCase: QuerySymphonyWorkspaceTrackerBindingsUseCase
    ) {
        self.queryWorkspaceTrackerBindingsUseCase = queryWorkspaceTrackerBindingsUseCase
    }

    public func resolveStartupContext(
        for workspaceLocator: SymphonyWorkspaceLocatorContract
    ) throws -> SymphonyWorkspaceBindingResolutionOutcomeContract {
        let bindings = try queryWorkspaceTrackerBindingsUseCase.queryBindings()
        guard bindings.isEmpty == false else {
            return .setupRequired(workspaceLocator: workspaceLocator)
        }

        let normalizedCurrentWorkspacePath = normalizedPath(
            from: workspaceLocator.currentWorkingDirectoryPath
        )
        let activeBindings = bindings.map { binding in
            SymphonyActiveWorkspaceBindingContextContract(
                workspaceBinding: binding,
                effectiveWorkspaceLocator: SymphonyWorkspaceLocatorContract(
                    currentWorkingDirectoryPath: binding.workspacePath,
                    explicitWorkflowPath: effectiveWorkflowPath(
                        for: binding,
                        launchWorkspaceLocator: workspaceLocator,
                        normalizedCurrentWorkspacePath: normalizedCurrentWorkspacePath
                    )
                )
            )
        }

        return .ready(activeBindings: activeBindings)
    }

    private func effectiveWorkflowPath(
        for binding: SymphonyWorkspaceTrackerBindingContract,
        launchWorkspaceLocator: SymphonyWorkspaceLocatorContract,
        normalizedCurrentWorkspacePath: String
    ) -> String? {
        if normalizedPath(from: binding.workspacePath) == normalizedCurrentWorkspacePath {
            return launchWorkspaceLocator.explicitWorkflowPath ?? binding.explicitWorkflowPath
        }

        return binding.explicitWorkflowPath
    }

    private func normalizedPath(
        from rawPath: String
    ) -> String {
        let trimmedPath = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
        let homeExpandedPath = NSString(string: trimmedPath).expandingTildeInPath
        return URL(fileURLWithPath: homeExpandedPath)
            .resolvingSymlinksInPath()
            .standardizedFileURL
            .path
    }
}
