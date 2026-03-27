public protocol SymphonyWorkflowLoaderPortProtocol {
    func loadWorkflow(
        using request: SymphonyWorkflowConfigurationRequestContract
    ) throws -> SymphonyWorkflowDefinitionContract
}
