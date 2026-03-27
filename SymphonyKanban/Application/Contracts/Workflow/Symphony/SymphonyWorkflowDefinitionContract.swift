public struct SymphonyWorkflowDefinitionContract: Equatable, Sendable {
    public let resolvedPath: String
    public let config: [String: SymphonyConfigValueContract]
    public let promptTemplate: String

    public init(
        resolvedPath: String,
        config: [String: SymphonyConfigValueContract],
        promptTemplate: String
    ) {
        self.resolvedPath = resolvedPath
        self.config = config
        self.promptTemplate = promptTemplate
    }
}
