public protocol SymphonyConfigResolverPortProtocol {
    func resolveConfig(
        from definition: SymphonyWorkflowDefinitionContract
    ) -> SymphonyServiceConfigContract
}
