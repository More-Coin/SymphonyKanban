public struct SymphonyStartupService {
    private let resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase
    private let validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase

    public init(
        resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase,
        validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase
    ) {
        self.resolveWorkflowConfigurationUseCase = resolveWorkflowConfigurationUseCase
        self.validateStartupConfigurationUseCase = validateStartupConfigurationUseCase
    }

    public func execute(
        _ command: SymphonyStartupCommandContract
    ) throws -> SymphonyStartupResultContract {
        let configuration = try resolveWorkflowConfigurationUseCase.resolveValidated(
            SymphonyWorkflowConfigurationRequestContract(
                explicitWorkflowPath: command.explicitWorkflowPath,
                currentWorkingDirectoryPath: command.currentWorkingDirectoryPath
            ),
            validateStartupConfigurationUseCase: validateStartupConfigurationUseCase
        )

        return SymphonyStartupResultContract(
            resolvedWorkflowPath: configuration.workflowDefinition.resolvedPath
        )
    }
}
