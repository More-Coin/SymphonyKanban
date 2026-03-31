public struct CompleteSymphonyRunAttemptUseCase {
    private let workspaceLifecyclePort: any SymphonyWorkspaceLifecyclePortProtocol

    public init(workspaceLifecyclePort: any SymphonyWorkspaceLifecyclePortProtocol) {
        self.workspaceLifecyclePort = workspaceLifecyclePort
    }

    public func completeRunAttempt(
        in workspace: SymphonyWorkspaceContract,
        using serviceConfig: SymphonyServiceConfigContract
    ) -> SymphonyRunAttemptCompletionContract {
        workspaceLifecyclePort.completeRunAttempt(
            in: workspace,
            using: serviceConfig
        )
    }
}
