public struct PrepareSymphonyWorkspaceUseCase {
    private let workspaceLifecyclePort: any SymphonyWorkspaceLifecyclePortProtocol

    public init(workspaceLifecyclePort: any SymphonyWorkspaceLifecyclePortProtocol) {
        self.workspaceLifecyclePort = workspaceLifecyclePort
    }

    public func prepareWorkspace(
        for issueIdentifier: String,
        using serviceConfig: SymphonyServiceConfigContract
    ) throws -> SymphonyWorkspaceContract {
        try workspaceLifecyclePort.prepareWorkspaceForAttempt(
            issueIdentifier: issueIdentifier,
            using: serviceConfig
        )
    }
}
