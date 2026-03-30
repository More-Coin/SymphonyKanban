public struct SymphonyWorkspaceSelectionResultContract: Equatable, Sendable {
    public let workspaceLocator: SymphonyWorkspaceLocatorContract
    public let resolvedWorkflowPath: String

    public init(
        workspaceLocator: SymphonyWorkspaceLocatorContract,
        resolvedWorkflowPath: String
    ) {
        self.workspaceLocator = workspaceLocator
        self.resolvedWorkflowPath = resolvedWorkflowPath
    }
}
