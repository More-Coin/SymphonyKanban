public struct RemoveSymphonyWorkspaceTrackerBindingUseCase: Sendable {
    private let workspaceTrackerBindingPort: any SymphonyWorkspaceTrackerBindingPortProtocol

    public init(
        workspaceTrackerBindingPort: any SymphonyWorkspaceTrackerBindingPortProtocol
    ) {
        self.workspaceTrackerBindingPort = workspaceTrackerBindingPort
    }

    public func removeBinding(
        forWorkspacePath workspacePath: String
    ) throws -> SymphonyWorkspaceTrackerBindingRemovalResultContract {
        try workspaceTrackerBindingPort.removeBinding(forWorkspacePath: workspacePath)
        return SymphonyWorkspaceTrackerBindingRemovalResultContract(
            workspacePath: workspacePath
        )
    }
}
