import Foundation

public struct SymphonyStartupService {
    private let resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase
    private let validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase
    private let validateTrackerConnectionUseCase: ValidateSymphonyTrackerConnectionReadinessUseCase

    public init(
        resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase,
        validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase,
        validateTrackerConnectionUseCase: ValidateSymphonyTrackerConnectionReadinessUseCase
    ) {
        self.resolveWorkflowConfigurationUseCase = resolveWorkflowConfigurationUseCase
        self.validateStartupConfigurationUseCase = validateStartupConfigurationUseCase
        self.validateTrackerConnectionUseCase = validateTrackerConnectionUseCase
    }

    public func execute(
        _ workspaceLocator: SymphonyWorkspaceLocatorContract
    ) throws -> SymphonyStartupResultContract {
        let configuration = try resolveWorkflowConfigurationUseCase.resolveValidated(
            workspaceLocator,
            validateStartupConfigurationUseCase: validateStartupConfigurationUseCase
        )
        let trackerAuthStatus = try validateTrackerConnectionUseCase.validate(
            configuration.serviceConfig.tracker
        )

        return SymphonyStartupResultContract(
            resolvedWorkflowPath: configuration.workflowDefinition.resolvedPath,
            trackerAuthStatus: trackerAuthStatus
        )
    }
}
