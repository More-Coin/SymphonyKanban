import Foundation

public struct SymphonyStartupService {
    private let workspaceBindingResolutionService: SymphonyWorkspaceBindingResolutionService
    private let resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase
    private let validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase
    private let validateTrackerConnectionUseCase: ValidateSymphonyTrackerConnectionReadinessUseCase
    private let startupStateTransition: SymphonyStartupStateTransition

    public init(
        workspaceBindingResolutionService: SymphonyWorkspaceBindingResolutionService,
        resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase,
        validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase,
        validateTrackerConnectionUseCase: ValidateSymphonyTrackerConnectionReadinessUseCase,
        startupStateTransition: SymphonyStartupStateTransition
    ) {
        self.workspaceBindingResolutionService = workspaceBindingResolutionService
        self.resolveWorkflowConfigurationUseCase = resolveWorkflowConfigurationUseCase
        self.validateStartupConfigurationUseCase = validateStartupConfigurationUseCase
        self.validateTrackerConnectionUseCase = validateTrackerConnectionUseCase
        self.startupStateTransition = startupStateTransition
    }

    public func execute(
        _ workspaceLocator: SymphonyWorkspaceLocatorContract
    ) throws -> SymphonyStartupExecutionResultContract {
        let bindingResolution = try workspaceBindingResolutionService.resolveStartupContext(
            for: workspaceLocator
        )

        switch bindingResolution {
        case .setupRequired(let unresolvedWorkspaceLocator):
            return startupStateTransition.setupRequired(workspaceLocator: unresolvedWorkspaceLocator)
        case .ready(let activeBindings):
            let resolvedActiveBindings = try activeBindings.map(resolveStartupContext(for:))
            return startupStateTransition.ready(
                workspaceLocator: workspaceLocator,
                activeBindings: resolvedActiveBindings
            )
        }
    }

    private func resolveStartupContext(
        for activeBinding: SymphonyActiveWorkspaceBindingContextContract
    ) throws -> SymphonyActiveWorkspaceBindingContextContract {
        do {
            let configuration = try resolveWorkflowConfigurationUseCase.resolveValidated(
                activeBinding.effectiveWorkspaceLocator,
                validateStartupConfigurationUseCase: validateStartupConfigurationUseCase
            )
            let trackerAuthStatus = try validateTrackerConnectionUseCase.validate(
                configuration.serviceConfig.tracker
            )

            return SymphonyActiveWorkspaceBindingContextContract(
                workspaceBinding: activeBinding.workspaceBinding,
                effectiveWorkspaceLocator: activeBinding.effectiveWorkspaceLocator,
                workflowConfiguration: configuration,
                trackerAuthStatus: trackerAuthStatus
            )
        } catch {
            return SymphonyActiveWorkspaceBindingContextContract(
                workspaceBinding: activeBinding.workspaceBinding,
                effectiveWorkspaceLocator: activeBinding.effectiveWorkspaceLocator,
                workflowConfiguration: nil,
                trackerAuthStatus: nil,
                startupFailure: failureSummary(from: error)
            )
        }
    }

    private func failureSummary(
        from error: any Error
    ) -> SymphonyFailureSummaryContract {
        if let structuredError = error as? any StructuredErrorProtocol {
            return SymphonyFailureSummaryContract(
                message: structuredError.message,
                details: structuredError.details
            )
        }

        return SymphonyFailureSummaryContract(message: error.localizedDescription)
    }
}
