public struct ResolveSymphonyWorkflowConfigurationUseCase {
    private let workflowLoaderPort: any SymphonyWorkflowLoaderPortProtocol
    private let configResolverPort: any SymphonyConfigResolverPortProtocol

    public init(
        workflowLoaderPort: any SymphonyWorkflowLoaderPortProtocol,
        configResolverPort: any SymphonyConfigResolverPortProtocol
    ) {
        self.workflowLoaderPort = workflowLoaderPort
        self.configResolverPort = configResolverPort
    }

    public func resolve(
        _ workspaceLocator: SymphonyWorkspaceLocatorContract
    ) throws -> SymphonyWorkflowConfigurationResultContract {
        let workflowDefinition = try loadWorkflowDefinition(using: workspaceLocator)
        let serviceConfig = configResolverPort.resolveConfig(from: workflowDefinition)

        return SymphonyWorkflowConfigurationResultContract(
            workflowDefinition: workflowDefinition,
            serviceConfig: serviceConfig
        )
    }

    public func resolveValidated(
        _ workspaceLocator: SymphonyWorkspaceLocatorContract,
        validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase
    ) throws -> SymphonyWorkflowConfigurationResultContract {
        let workflowDefinition = try loadWorkflowDefinition(using: workspaceLocator)
        let serviceConfig = configResolverPort.resolveConfig(from: workflowDefinition)
        let validatedServiceConfig = try validateStartupConfigurationUseCase.validate(serviceConfig)

        return SymphonyWorkflowConfigurationResultContract(
            workflowDefinition: workflowDefinition,
            serviceConfig: validatedServiceConfig
        )
    }

    private func loadWorkflowDefinition(
        using workspaceLocator: SymphonyWorkspaceLocatorContract
    ) throws -> SymphonyWorkflowDefinitionContract {
        try workflowLoaderPort.loadWorkflow(using: workspaceLocator)
    }
}
