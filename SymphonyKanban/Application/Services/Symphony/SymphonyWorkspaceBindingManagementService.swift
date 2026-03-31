import Foundation

public struct SymphonyWorkspaceBindingManagementService {
    private let queryWorkspaceTrackerBindingsUseCase: QuerySymphonyWorkspaceTrackerBindingsUseCase
    private let removeBindingUseCase: RemoveSymphonyWorkspaceTrackerBindingUseCase
    private let resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase
    private let validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase
    private let validateTrackerConnectionUseCase: ValidateSymphonyTrackerConnectionReadinessUseCase

    public init(
        queryWorkspaceTrackerBindingsUseCase: QuerySymphonyWorkspaceTrackerBindingsUseCase,
        removeBindingUseCase: RemoveSymphonyWorkspaceTrackerBindingUseCase,
        resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase,
        validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase,
        validateTrackerConnectionUseCase: ValidateSymphonyTrackerConnectionReadinessUseCase
    ) {
        self.queryWorkspaceTrackerBindingsUseCase = queryWorkspaceTrackerBindingsUseCase
        self.removeBindingUseCase = removeBindingUseCase
        self.resolveWorkflowConfigurationUseCase = resolveWorkflowConfigurationUseCase
        self.validateStartupConfigurationUseCase = validateStartupConfigurationUseCase
        self.validateTrackerConnectionUseCase = validateTrackerConnectionUseCase
    }

    public func queryActiveBindingContexts(
        for workspaceLocator: SymphonyWorkspaceLocatorContract
    ) throws -> [SymphonyActiveWorkspaceBindingContextContract] {
        let bindings = try queryWorkspaceTrackerBindingsUseCase.queryBindings()
        let normalizedCurrentWorkspacePath = normalizedPath(
            from: workspaceLocator.currentWorkingDirectoryPath
        )

        return try bindings.map { binding in
            try resolveBindingContext(
                for: binding,
                launchWorkspaceLocator: workspaceLocator,
                normalizedCurrentWorkspacePath: normalizedCurrentWorkspacePath
            )
        }
    }

    public func removeBindingAndQueryActiveBindingContexts(
        forWorkspacePath workspacePath: String,
        workspaceLocator: SymphonyWorkspaceLocatorContract
    ) throws -> [SymphonyActiveWorkspaceBindingContextContract] {
        _ = try removeBindingUseCase.removeBinding(forWorkspacePath: workspacePath)
        return try queryActiveBindingContexts(for: workspaceLocator)
    }

    private func resolveBindingContext(
        for binding: SymphonyWorkspaceTrackerBindingContract,
        launchWorkspaceLocator: SymphonyWorkspaceLocatorContract,
        normalizedCurrentWorkspacePath: String
    ) throws -> SymphonyActiveWorkspaceBindingContextContract {
        let effectiveWorkspaceLocator = SymphonyWorkspaceLocatorContract(
            currentWorkingDirectoryPath: binding.workspacePath,
            explicitWorkflowPath: effectiveWorkflowPath(
                for: binding,
                launchWorkspaceLocator: launchWorkspaceLocator,
                normalizedCurrentWorkspacePath: normalizedCurrentWorkspacePath
            )
        )

        do {
            let configuration = try resolveWorkflowConfigurationUseCase.resolveValidated(
                effectiveWorkspaceLocator,
                validateStartupConfigurationUseCase: validateStartupConfigurationUseCase
            )
            let trackerAuthStatus = try validateTrackerConnectionUseCase.validate(
                configuration.serviceConfig.tracker
            )

            return SymphonyActiveWorkspaceBindingContextContract(
                workspaceBinding: binding,
                effectiveWorkspaceLocator: effectiveWorkspaceLocator,
                workflowConfiguration: configuration,
                trackerAuthStatus: trackerAuthStatus
            )
        } catch {
            return SymphonyActiveWorkspaceBindingContextContract(
                workspaceBinding: binding,
                effectiveWorkspaceLocator: effectiveWorkspaceLocator,
                workflowConfiguration: nil,
                trackerAuthStatus: nil,
                startupFailure: failureSummary(from: error)
            )
        }
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

    private func failureSummary(
        from error: any Error
    ) -> SymphonyFailureSummaryContract {
        if let structuredError = error as? any StructuredErrorProtocol {
            return SymphonyFailureSummaryContract(
                message: structuredError.message,
                details: structuredError.details
            )
        }

        return SymphonyFailureSummaryContract(message: error.localizedDescription)
    }
}
