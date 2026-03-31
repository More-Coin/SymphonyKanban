import Foundation

public struct SymphonyWorkspaceWorkflowProvisioningService {
    private let resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase
    private let validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase
    private let workflowWritePort: any SymphonyWorkflowWritePortProtocol
    private let workflowTemplatePort: any SymphonyWorkflowTemplatePortProtocol

    public init(
        resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase,
        validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase,
        workflowWritePort: any SymphonyWorkflowWritePortProtocol,
        workflowTemplatePort: any SymphonyWorkflowTemplatePortProtocol
    ) {
        self.resolveWorkflowConfigurationUseCase = resolveWorkflowConfigurationUseCase
        self.validateStartupConfigurationUseCase = validateStartupConfigurationUseCase
        self.workflowWritePort = workflowWritePort
        self.workflowTemplatePort = workflowTemplatePort
    }

    public func provisionWorkspace(
        workspacePath: String,
        explicitWorkflowPath: String? = nil,
        selectedScope: SymphonyTrackerScopeOptionContract
    ) throws -> SymphonyWorkspaceSelectionResultContract {
        let normalizedWorkspacePath = normalizedPath(from: workspacePath)
        guard normalizedWorkspacePath.isEmpty == false else {
            throw SymphonyWorkspaceSelectionApplicationError.missingWorkspacePath
        }

        let normalizedScopeKind = selectedScope.scopeKind
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let normalizedScopeIdentifier = selectedScope.scopeIdentifier
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedScopeName = selectedScope.scopeName
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalizedScopeKind.isEmpty == false,
              normalizedScopeIdentifier.isEmpty == false,
              normalizedScopeName.isEmpty == false else {
            throw SymphonyWorkspaceSelectionApplicationError.missingScopeSelection
        }

        let normalizedExplicitWorkflowPath = normalizedOptionalPath(from: explicitWorkflowPath)
        let workspaceLocator = SymphonyWorkspaceLocatorContract(
            currentWorkingDirectoryPath: normalizedWorkspacePath,
            explicitWorkflowPath: normalizedExplicitWorkflowPath
        )
        let definitionPath = normalizedExplicitWorkflowPath
            ?? workflowWritePort.defaultDefinitionPath(forWorkspacePath: normalizedWorkspacePath)

        let wasCreated = try workflowWritePort.ensureDefinitionExists(
            contents: workflowTemplatePort.makeDefinitionContents(
                for: SymphonyTrackerScopeOptionContract(
                    id: selectedScope.id,
                    scopeKind: normalizedScopeKind,
                    scopeIdentifier: normalizedScopeIdentifier,
                    scopeName: normalizedScopeName,
                    detailText: selectedScope.detailText
                )
            ),
            atPath: definitionPath
        )

        let workflowConfiguration = try resolveWorkflowConfigurationUseCase.resolveValidated(
            workspaceLocator,
            validateStartupConfigurationUseCase: validateStartupConfigurationUseCase
        )
        try validateResolvedScope(
            workflowConfiguration.serviceConfig.tracker,
            expectedScopeKind: normalizedScopeKind,
            expectedScopeIdentifier: normalizedScopeIdentifier
        )

        return SymphonyWorkspaceSelectionResultContract(
            workspaceLocator: workspaceLocator,
            resolvedWorkflowPath: workflowConfiguration.workflowDefinition.resolvedPath,
            workflowProvisioningStatus: wasCreated ? .created : .existing
        )
    }

    private func validateResolvedScope(
        _ tracker: SymphonyServiceConfigContract.Tracker,
        expectedScopeKind: String,
        expectedScopeIdentifier: String
    ) throws {
        guard let actualScope = workflowTemplatePort.configuredScopeReference(from: tracker) else {
            throw SymphonyWorkspaceSelectionApplicationError.missingScopeSelection
        }

        guard actualScope.scopeKind == expectedScopeKind,
              actualScope.scopeIdentifier == expectedScopeIdentifier else {
            throw SymphonyWorkspaceSelectionApplicationError.workflowScopeMismatch(
                expectedScopeKind: expectedScopeKind,
                expectedScopeIdentifier: expectedScopeIdentifier,
                actualScopeKind: actualScope.scopeKind,
                actualScopeIdentifier: actualScope.scopeIdentifier
            )
        }
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
