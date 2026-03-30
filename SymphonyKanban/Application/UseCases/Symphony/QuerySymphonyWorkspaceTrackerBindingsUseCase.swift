public struct QuerySymphonyWorkspaceTrackerBindingsUseCase: Sendable {
    private let workspaceTrackerBindingPort: any SymphonyWorkspaceTrackerBindingPortProtocol

    public init(
        workspaceTrackerBindingPort: any SymphonyWorkspaceTrackerBindingPortProtocol
    ) {
        self.workspaceTrackerBindingPort = workspaceTrackerBindingPort
    }

    public func queryBindings() throws -> [SymphonyWorkspaceTrackerBindingContract] {
        try workspaceTrackerBindingPort.listBindings()
    }
}
