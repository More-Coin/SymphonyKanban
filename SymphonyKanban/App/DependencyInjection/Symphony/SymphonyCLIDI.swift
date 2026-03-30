import Foundation
import Dispatch

struct SymphonyCLIDI {
    static func makeRuntime() -> SymphonyCLIRuntime {
        let startupComponents = makeStartupComponents()
        let controller = SymphonyStartupController(
            startupService: startupComponents.startupService,
            renderer: SymphonyStartupRenderer()
        )

        return SymphonyCLIRuntime(controller: controller)
    }

    static func makeHostRuntime() -> SymphonyServiceHostRuntime {
        let hostStartupComponents = makeStartupComponents()
        let runtimeStartupComponents = makeStartupComponents()
        let logSinkAdapter = SymphonyConsoleOrchestratorLogSinkPortAdapter()
        let environment = ProcessInfo.processInfo.environment

        let runnerGatewayFactory: @Sendable () -> SymphonyWorkerAttemptService = {
            let issueTrackerGateway = SymphonyLinearIssueTrackerGateway(
                environment: environment
            )
            let workspaceGateway = SymphonyWorkspaceLifecycleGateway()
            let runnerGateway = SymphonyCodexRunnerGateway()
            let codexCommandResolverPort = SymphonyCodexCommandResolverPortAdapter()
            return SymphonyWorkerAttemptService(
                prepareWorkspaceUseCase: PrepareSymphonyWorkspaceUseCase(
                    workspaceLifecyclePort: workspaceGateway
                ),
                validateWorkspaceLaunchContextUseCase: ValidateSymphonyWorkspaceLaunchContextUseCase(
                    workspaceLifecyclePort: workspaceGateway
                ),
                completeRunAttemptUseCase: CompleteSymphonyRunAttemptUseCase(
                    workspaceLifecyclePort: workspaceGateway
                ),
                cancelActiveTurnUseCase: CancelSymphonyActiveTurnUseCase(
                    runnerPort: runnerGateway
                ),
                renderPromptUseCase: RenderSymphonyPromptUseCase(
                    promptRendererPort: SymphonyPromptRendererPortAdapter()
                ),
                fetchIssuesUseCase: FetchSymphonyIssuesUseCase(
                    issueTrackerReadPort: issueTrackerGateway
                ),
                resolveCodexCommandUseCase: ResolveSymphonyCodexCommandUseCase(
                    codexCommandResolverPort: codexCommandResolverPort
                ),
                requestFactoryPort: SymphonyCodexRequestFactoryPortAdapter(),
                runnerPort: runnerGateway,
                telemetryPort: SymphonyWorkerAttemptTelemetryPortAdapter(logSink: logSinkAdapter)
            )
        }

        let runtimeService = SymphonyOrchestratorRuntimeService(
            dispatchPreflightValidationService: runtimeStartupComponents.dispatchPreflightValidationService,
            fetchIssuesUseCase: FetchSymphonyIssuesUseCase(
                issueTrackerReadPort: SymphonyLinearIssueTrackerGateway(
                    environment: environment
                )
            ),
            cleanupWorkspaceUseCase: CleanupSymphonyWorkspaceUseCase(
                workspaceLifecyclePort: SymphonyWorkspaceLifecycleGateway()
            ),
            projectRuntimeStatusSnapshotUseCase: ProjectSymphonyRuntimeStatusSnapshotUseCase(
                clockPort: SymphonyRuntimeClockGateway(),
                runtimeStatusProjectorPort: SymphonyRuntimeStatusProjectorPortAdapter()
            ),
            workerExecutionPort: SymphonyWorkerExecutionGateway(
                makeService: runnerGatewayFactory
            ),
            schedulerPort: SymphonyRuntimeSchedulerGateway(),
            clockPort: SymphonyRuntimeClockGateway(),
            logSinkPort: logSinkAdapter,
            runtimeStatusSinkPort: logSinkAdapter,
            workflowReloadMonitorPort: SymphonyWorkflowReloadMonitorGateway()
        )

        return SymphonyServiceHostRuntime(
            startupService: hostStartupComponents.startupService,
            renderer: SymphonyStartupRenderer(),
            startRuntime: { bindingContext in
                guard let workflowConfiguration = bindingContext.workflowConfiguration else {
                    return
                }
                Task {
                    await runtimeService.start(
                        workspaceLocator: bindingContext.effectiveWorkspaceLocator,
                        initialConfiguration: workflowConfiguration
                    )
                }
            },
            keepRunning: {
                dispatchMain()
            }
        )
    }

    private static func makeStartupComponents() -> (
        resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase,
        validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase,
        validateTrackerConnectionUseCase: ValidateSymphonyTrackerConnectionReadinessUseCase,
        workspaceBindingResolutionService: SymphonyWorkspaceBindingResolutionService,
        startupStateTransition: SymphonyStartupStateTransition,
        dispatchPreflightValidationService: SymphonyDispatchPreflightValidationService,
        startupService: SymphonyStartupService
    ) {
        let environment = ProcessInfo.processInfo.environment
        let trackerAuthPortAdapter = SymphonyLinearTrackerAuthPortAdapter(
            environment: environment
        )
        let workspaceTrackerBindingRepository = SymphonyWorkspaceTrackerBindingRepository()
        let resolveWorkflowConfigurationUseCase = ResolveSymphonyWorkflowConfigurationUseCase(
            workflowLoaderPort: SymphonyWorkflowLoaderPortAdapter(),
            configResolverPort: SymphonyConfigResolverPortAdapter()
        )
        let workspaceBindingResolutionService = SymphonyWorkspaceBindingResolutionService(
            queryWorkspaceTrackerBindingsUseCase: QuerySymphonyWorkspaceTrackerBindingsUseCase(
                workspaceTrackerBindingPort: workspaceTrackerBindingRepository
            )
        )
        let validateStartupConfigurationUseCase = ValidateSymphonyStartupConfigurationUseCase(
            startupConfigurationValidatorPort: ValidateSymphonyStartupConfigurationPortAdapter()
        )
        let validateTrackerConnectionUseCase = ValidateSymphonyTrackerConnectionReadinessUseCase(
            trackerAuthPort: trackerAuthPortAdapter
        )
        let dispatchPreflightValidationService = SymphonyDispatchPreflightValidationService(
            resolveWorkflowConfigurationUseCase: resolveWorkflowConfigurationUseCase,
            validateStartupConfigurationUseCase: validateStartupConfigurationUseCase,
            validateTrackerConnectionUseCase: validateTrackerConnectionUseCase
        )
        let startupStateTransition = SymphonyStartupStateTransition()
        let startupService = SymphonyStartupService(
            workspaceBindingResolutionService: workspaceBindingResolutionService,
            resolveWorkflowConfigurationUseCase: resolveWorkflowConfigurationUseCase,
            validateStartupConfigurationUseCase: validateStartupConfigurationUseCase,
            validateTrackerConnectionUseCase: validateTrackerConnectionUseCase,
            startupStateTransition: startupStateTransition
        )
        return (
            resolveWorkflowConfigurationUseCase,
            validateStartupConfigurationUseCase,
            validateTrackerConnectionUseCase,
            workspaceBindingResolutionService,
            startupStateTransition,
            dispatchPreflightValidationService,
            startupService
        )
    }
}
