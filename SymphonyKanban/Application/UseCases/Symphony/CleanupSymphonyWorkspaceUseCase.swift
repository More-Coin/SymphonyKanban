public struct CleanupSymphonyWorkspaceUseCase {
    private let workspaceLifecyclePort: any SymphonyWorkspaceLifecyclePortProtocol

    public init(workspaceLifecyclePort: any SymphonyWorkspaceLifecyclePortProtocol) {
        self.workspaceLifecyclePort = workspaceLifecyclePort
    }

    public func cleanupWorkspace(
        for issueIdentifier: String,
        using serviceConfig: SymphonyServiceConfigContract
    ) throws -> SymphonyWorkspaceCleanupContract {
        try workspaceLifecyclePort.cleanupWorkspace(
            for: issueIdentifier,
            using: serviceConfig
        )
    }
}
