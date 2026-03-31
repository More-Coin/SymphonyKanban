public struct ValidateSymphonyWorkspaceLaunchContextUseCase {
    private let workspaceLifecyclePort: any SymphonyWorkspaceLifecyclePortProtocol

    public init(workspaceLifecyclePort: any SymphonyWorkspaceLifecyclePortProtocol) {
        self.workspaceLifecyclePort = workspaceLifecyclePort
    }

    public func validate(
        currentWorkingDirectoryPath: String,
        for workspace: SymphonyWorkspaceContract,
        using serviceConfig: SymphonyServiceConfigContract
    ) throws -> SymphonyWorkspaceLaunchValidationContract {
        let validatedWorkspacePath = try workspaceLifecyclePort.validateCurrentWorkingDirectory(
            currentWorkingDirectoryPath,
            for: workspace,
            using: serviceConfig
        )

        return SymphonyWorkspaceLaunchValidationContract(
            workspacePath: validatedWorkspacePath,
            currentWorkingDirectoryPath: validatedWorkspacePath
        )
    }
}
