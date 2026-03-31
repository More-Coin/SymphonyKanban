public struct SaveSymphonyWorkspaceTrackerBindingUseCase: Sendable {
    private let workspaceTrackerBindingPort: any SymphonyWorkspaceTrackerBindingPortProtocol

    public init(
        workspaceTrackerBindingPort: any SymphonyWorkspaceTrackerBindingPortProtocol
    ) {
        self.workspaceTrackerBindingPort = workspaceTrackerBindingPort
    }

    public func save(
        _ binding: SymphonyWorkspaceTrackerBindingContract
    ) throws -> SymphonyWorkspaceTrackerBindingContract {
        try workspaceTrackerBindingPort.saveBinding(binding)
        return binding
    }
}
