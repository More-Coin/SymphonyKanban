public protocol SymphonyWorkspaceLifecyclePortProtocol {
    func prepareWorkspaceForAttempt(
        issueIdentifier: String,
        using serviceConfig: SymphonyServiceConfigContract
    ) throws -> SymphonyWorkspaceContract

    func completeRunAttempt(
        in workspace: SymphonyWorkspaceContract,
        using serviceConfig: SymphonyServiceConfigContract
    ) -> SymphonyRunAttemptCompletionContract

    func cleanupWorkspace(
        for issueIdentifier: String,
        using serviceConfig: SymphonyServiceConfigContract
    ) throws -> SymphonyWorkspaceCleanupContract

    func validateCurrentWorkingDirectory(
        _ currentWorkingDirectoryPath: String,
        for workspace: SymphonyWorkspaceContract,
        using serviceConfig: SymphonyServiceConfigContract
    ) throws -> String
}
