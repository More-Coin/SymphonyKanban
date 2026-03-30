public protocol SymphonyWorkspaceTrackerBindingPortProtocol: Sendable {
    func resolveBinding(
        for workspaceLocator: SymphonyWorkspaceLocatorContract
    ) throws -> SymphonyWorkspaceTrackerBindingContract?

    func listBindings() throws -> [SymphonyWorkspaceTrackerBindingContract]

    func saveBinding(
        _ binding: SymphonyWorkspaceTrackerBindingContract
    ) throws

    func removeBinding(
        forWorkspacePath workspacePath: String
    ) throws
}
