public struct ResolveSymphonyWorkspaceTrackerBindingUseCase: Sendable {
    private let workspaceTrackerBindingPort: any SymphonyWorkspaceTrackerBindingPortProtocol

    public init(
        workspaceTrackerBindingPort: any SymphonyWorkspaceTrackerBindingPortProtocol
    ) {
        self.workspaceTrackerBindingPort = workspaceTrackerBindingPort
    }

    public func resolve(
        for workspaceLocator: SymphonyWorkspaceLocatorContract
    ) throws -> SymphonyWorkspaceTrackerBindingContract? {
        try workspaceTrackerBindingPort.resolveBinding(for: workspaceLocator)
    }
}
