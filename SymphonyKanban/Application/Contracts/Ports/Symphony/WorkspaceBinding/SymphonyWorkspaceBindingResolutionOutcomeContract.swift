public enum SymphonyWorkspaceBindingResolutionOutcomeContract: Equatable, Sendable {
    case ready(activeBindings: [SymphonyActiveWorkspaceBindingContextContract])
    case setupRequired(workspaceLocator: SymphonyWorkspaceLocatorContract)
}
