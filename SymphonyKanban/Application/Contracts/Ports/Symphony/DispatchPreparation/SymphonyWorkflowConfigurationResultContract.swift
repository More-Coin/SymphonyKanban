public struct SymphonyWorkflowConfigurationResultContract: Equatable, Sendable {
    public let workflowDefinition: SymphonyWorkflowDefinitionContract
    public let serviceConfig: SymphonyServiceConfigContract

    public init(
        workflowDefinition: SymphonyWorkflowDefinitionContract,
        serviceConfig: SymphonyServiceConfigContract
    ) {
        self.workflowDefinition = workflowDefinition
        self.serviceConfig = serviceConfig
    }
}
