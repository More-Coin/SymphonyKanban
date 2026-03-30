public struct SymphonyStartupExecutionResultContract: Equatable, Sendable {
    public let result: SymphonyStartupResultContract
    public let workspaceLocator: SymphonyWorkspaceLocatorContract
    public let activeBindings: [SymphonyActiveWorkspaceBindingContextContract]

    public init(
        result: SymphonyStartupResultContract,
        workspaceLocator: SymphonyWorkspaceLocatorContract,
        activeBindings: [SymphonyActiveWorkspaceBindingContextContract]
    ) {
        self.result = result
        self.workspaceLocator = workspaceLocator
        self.activeBindings = activeBindings
    }
}
