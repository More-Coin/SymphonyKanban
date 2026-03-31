public protocol SymphonyWorkflowLoaderPortProtocol {
    func loadWorkflow(
        using workspaceLocator: SymphonyWorkspaceLocatorContract
    ) throws -> SymphonyWorkflowDefinitionContract
}
