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
        let runnerGatewayFactory: @Sendable () -> SymphonyWorkerAttemptService = {
            let issueTrackerGateway = SymphonyLinearIssueTrackerGateway()
            let workspaceGateway = SymphonyWorkspaceLifecycleGateway()
            let runnerGateway = SymphonyCodexRunnerGateway()
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
                requestFactoryPort: SymphonyCodexRequestFactoryPortAdapter(),
                runnerPort: runnerGateway,
                telemetryPort: SymphonyWorkerAttemptTelemetryPortAdapter(logSink: logSinkAdapter)
            )
        }
        let runtimeService = SymphonyOrchestratorRuntimeService(
            dispatchPreflightValidationService: runtimeStartupComponents.dispatchPreflightValidationService,
            fetchIssuesUseCase: FetchSymphonyIssuesUseCase(
                issueTrackerReadPort: SymphonyLinearIssueTrackerGateway()
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
            resolveWorkflowConfigurationUseCase: hostStartupComponents.resolveWorkflowConfigurationUseCase,
            validateStartupConfigurationUseCase: hostStartupComponents.validateStartupConfigurationUseCase,
            renderer: SymphonyStartupRenderer(),
            startRuntime: { command, workflowConfiguration in
                Task {
                    await runtimeService.start(
                        command: command,
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
        dispatchPreflightValidationService: SymphonyDispatchPreflightValidationService,
        startupService: SymphonyStartupService
    ) {
        let resolveWorkflowConfigurationUseCase = ResolveSymphonyWorkflowConfigurationUseCase(
            workflowLoaderPort: SymphonyWorkflowLoaderPortAdapter(),
            configResolverPort: SymphonyConfigResolverPortAdapter()
        )
        let validateStartupConfigurationUseCase = ValidateSymphonyStartupConfigurationUseCase(
            startupConfigurationValidatorPort: ValidateSymphonyStartupConfigurationPortAdapter()
        )
        let dispatchPreflightValidationService = SymphonyDispatchPreflightValidationService(
            resolveWorkflowConfigurationUseCase: resolveWorkflowConfigurationUseCase,
            validateStartupConfigurationUseCase: validateStartupConfigurationUseCase
        )
        let startupService = SymphonyStartupService(
            resolveWorkflowConfigurationUseCase: resolveWorkflowConfigurationUseCase,
            validateStartupConfigurationUseCase: validateStartupConfigurationUseCase
        )
        return (
            resolveWorkflowConfigurationUseCase,
            validateStartupConfigurationUseCase,
            dispatchPreflightValidationService,
            startupService
        )
    }
}
