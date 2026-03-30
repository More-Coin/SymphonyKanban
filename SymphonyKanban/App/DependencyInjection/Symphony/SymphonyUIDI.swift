import SwiftUI

@MainActor
public enum SymphonyUIDI {
    @MainActor
    public static func makeStartupGate() -> SymphonyStartupGateView {
        let startupStatusController = makeStartupStatusController()

        return SymphonyStartupGateView(
            startupStatusController: startupStatusController,
            navigationRoutesBuilder: { viewModel in
                AnyView(
                    makeNavigationRoutes(
                        failedBindingCount: viewModel.failedBindingCount,
                        activeBindingCount: viewModel.activeBindingCount
                    )
                )
            },
            setupViewBuilder: { viewModel, onComplete in
                AnyView(
                    makeWorkspaceBindingSetupView(
                        mode: viewModel.activeBindingCount > 0 || viewModel.failedBindingCount > 0 ? .repair : .firstRun,
                        onComplete: onComplete
                    )
                )
            }
        )
    }

    @MainActor
    public static func makeStartupStatusController(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        currentWorkingDirectoryPath: String = FileManager.default.currentDirectoryPath,
        explicitWorkflowPath: String? = nil
    ) -> SymphonyStartupStatusController {
        SymphonyStartupStatusController(
            startupService: makeStartupService(
                environment: environment
            ),
            currentWorkingDirectoryPath: currentWorkingDirectoryPath,
            explicitWorkflowPath: explicitWorkflowPath
        )
    }

    @MainActor
    public static func makeNavigationRoutes(
        failedBindingCount: Int = 0,
        activeBindingCount: Int = 0
    ) -> SymphonyNavigationRoutes {
        let runtimeQueryService = makeRuntimeQueryService()
        let environment = ProcessInfo.processInfo.environment
        let browserRuntime = SymphonyTrackerAuthBrowserRuntime()
        let callbackPort: any SymphonyTrackerAuthCallbackPortProtocol = SymphonyLinearOAuthLoopbackGateway()

        return SymphonyNavigationRoutes(
            issueDetailController: SymphonyIssueDetailController(
                runtimeQueryService: runtimeQueryService
            ),
            issueCatalogController: makeIssueCatalogController(
                environment: environment
            ),
            authController: makeAuthController(
                environment: environment
            ),
            codexConnectionController: makeCodexConnectionController(),
            launchTrackerAuthorizationURL: { url in
                browserRuntime.open(url)
            },
            prepareTrackerAuthorizationCallbackListener: {
                try await callbackPort.prepareAuthorizationCallbackListener()
            },
            awaitTrackerAuthorizationCallback: {
                try await callbackPort.awaitAuthorizationCallback()
            },
            cancelTrackerAuthorizationCallbackListener: {
                await callbackPort.cancelAuthorizationCallbackListener()
            },
            initialSelectedIssueIdentifier: "KAN-142",
            failedBindingCount: failedBindingCount,
            activeBindingCount: activeBindingCount
        )
    }

    @MainActor
    public static func makeWorkspaceBindingSetupView(
        mode: SymphonyWorkspaceBindingSetupView.Mode = .firstRun,
        onComplete: @escaping (SymphonyWorkspaceLocatorContract) -> Void
    ) -> SymphonyWorkspaceBindingSetupView {
        let environment = ProcessInfo.processInfo.environment
        let browserRuntime = SymphonyTrackerAuthBrowserRuntime()
        let callbackPort: any SymphonyTrackerAuthCallbackPortProtocol = SymphonyLinearOAuthLoopbackGateway()

        return SymphonyWorkspaceBindingSetupView(
            mode: mode,
            authController: makeAuthController(
                environment: environment
            ),
            scopeSelectionController: makeSetupScopeSelectionController(
                environment: environment
            ),
            workspaceSelectionController: makeWorkspaceSelectionController(
                environment: environment
            ),
            chooseWorkspaceDirectory: { startingDirectoryPath in
                makeWorkspaceFolderPickerRuntime().chooseWorkspaceDirectory(
                    startingDirectoryPath: startingDirectoryPath
                )
            },
            workspaceBindingSetupController: makeWorkspaceBindingSetupController(),
            launchTrackerAuthorizationURL: { url in
                browserRuntime.open(url)
            },
            prepareTrackerAuthorizationCallbackListener: {
                try await callbackPort.prepareAuthorizationCallbackListener()
            },
            awaitTrackerAuthorizationCallback: {
                try await callbackPort.awaitAuthorizationCallback()
            },
            cancelTrackerAuthorizationCallbackListener: {
                await callbackPort.cancelAuthorizationCallbackListener()
            },
            onComplete: onComplete
        )
    }

    public static func makeWorkspaceSelectionController(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> SymphonyWorkspaceSelectionController {
        SymphonyWorkspaceSelectionController(
            workspaceSelectionService: SymphonyWorkspaceSelectionService(
                resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase(
                    workflowLoaderPort: SymphonyWorkflowLoaderPortAdapter(
                        environment: environment
                    ),
                    configResolverPort: SymphonyConfigResolverPortAdapter(
                        environment: environment
                    )
                )
            )
        )
    }

    public static func makeWorkspaceFolderPickerRuntime() -> SymphonyWorkspaceFolderPickerRuntime {
        SymphonyWorkspaceFolderPickerRuntime()
    }

    public static func makeSetupScopeSelectionController(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> SymphonySetupScopeSelectionController {
        let liveGateway = SymphonyLinearIssueTrackerGateway(
            environment: environment
        )
        return SymphonySetupScopeSelectionController(
            trackerScopeService: SymphonyTrackerScopeService(
                fetchTeamsUseCase: FetchSymphonyTrackerTeamsUseCase(
                    trackerScopeReadPort: liveGateway
                ),
                fetchProjectsUseCase: FetchSymphonyTrackerProjectsUseCase(
                    trackerScopeReadPort: liveGateway
                )
            )
        )
    }

    public static func makeWorkspaceBindingSetupController() -> SymphonyWorkspaceBindingSetupController {
        let workspaceTrackerBindingRepository = SymphonyWorkspaceTrackerBindingRepository()
        return SymphonyWorkspaceBindingSetupController(
            setupService: SymphonyWorkspaceBindingSetupService(
                saveWorkspaceTrackerBindingUseCase: SaveSymphonyWorkspaceTrackerBindingUseCase(
                    workspaceTrackerBindingPort: workspaceTrackerBindingRepository
                )
            )
        )
    }

    public static func makeRuntimeQueryService() -> SymphonyRuntimeQueryService {
        let readPortAdapter = SymphonyStaticRuntimeReadPortAdapter()
        return SymphonyRuntimeQueryService(
            dashboardSnapshotUseCase: QuerySymphonyRuntimeDashboardSnapshotUseCase(
                clockPort: SymphonyRuntimeClockGateway(),
                runtimeDashboardReadPort: readPortAdapter
            ),
            issueDetailSnapshotUseCase: QuerySymphonyRuntimeIssueDetailSnapshotUseCase(
                clockPort: SymphonyRuntimeClockGateway(),
                runtimeIssueDetailReadPort: readPortAdapter
            )
        )
    }

    public static func makeAuthController(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> SymphonyAuthController {
        let authPortAdapter = SymphonyLinearTrackerAuthPortAdapter(
            environment: environment
        )
        return SymphonyAuthController(
            trackerAuthService: SymphonyTrackerAuthService(
                startTrackerAuthUseCase: StartSymphonyTrackerAuthorizationUseCase(
                    trackerAuthPort: authPortAdapter
                ),
                completeTrackerAuthUseCase: CompleteSymphonyTrackerAuthorizationUseCase(
                    trackerAuthPort: authPortAdapter
                ),
                queryTrackerAuthStatusUseCase: QuerySymphonyTrackerAuthStatusUseCase(
                    trackerAuthPort: authPortAdapter
                ),
                disconnectTrackerAuthUseCase: DisconnectSymphonyTrackerUseCase(
                    trackerAuthPort: authPortAdapter
                )
            )
        )
    }

    public static func makeIssueCatalogController(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> SymphonyIssueCatalogController {
        let trackerAuthPortAdapter = SymphonyLinearTrackerAuthPortAdapter(
            environment: environment
        )
        let displayModePreferenceRepository = SymphonyIssueCatalogDisplayPreferenceRepository()
        let displayPreferenceService = SymphonyIssueCatalogDisplayPreferenceService(
            queryDisplayModeUseCase: QuerySymphonyIssueCatalogDisplayModeUseCase(
                preferencePort: displayModePreferenceRepository
            ),
            saveDisplayModeUseCase: SaveSymphonyIssueCatalogDisplayModeUseCase(
                preferencePort: displayModePreferenceRepository
            )
        )

        return SymphonyIssueCatalogController(
            startupService: makeStartupService(
                environment: environment
            ),
            issueCatalogService: SymphonyIssueCatalogService(
                fetchIssuesUseCase: FetchSymphonyIssuesUseCase(
                    issueTrackerReadPort: SymphonyFallbackIssueTrackerPortAdapter(
                        trackerAuthPort: trackerAuthPortAdapter,
                        liveGateway: SymphonyLinearIssueTrackerGateway(
                            environment: environment
                        )
                    )
                )
            ),
            displayPreferenceService: displayPreferenceService
        )
    }

    public static func makeCodexConnectionController() -> SymphonyCodexConnectionController {
        let codexCommandResolverPort = SymphonyCodexCommandResolverPortAdapter()
        return SymphonyCodexConnectionController(
            codexConnectionService: SymphonyCodexConnectionService(
                resolveCodexCommandUseCase: ResolveSymphonyCodexCommandUseCase(
                    codexCommandResolverPort: codexCommandResolverPort
                ),
                queryCodexConnectionStatusUseCase: QuerySymphonyCodexConnectionStatusUseCase(
                    codexConnectionPort: SymphonyCodexConnectionGateway()
                )
            )
        )
    }

    private static func makeStartupService(
        environment: [String: String]
    ) -> SymphonyStartupService {
        let trackerAuthPortAdapter = SymphonyLinearTrackerAuthPortAdapter(
            environment: environment
        )
        let workspaceTrackerBindingRepository = SymphonyWorkspaceTrackerBindingRepository()
        let resolveWorkflowConfigurationUseCase = ResolveSymphonyWorkflowConfigurationUseCase(
            workflowLoaderPort: SymphonyWorkflowLoaderPortAdapter(
                environment: environment
            ),
            configResolverPort: SymphonyConfigResolverPortAdapter(
                environment: environment
            )
        )
        let workspaceBindingResolutionService = SymphonyWorkspaceBindingResolutionService(
            queryWorkspaceTrackerBindingsUseCase: QuerySymphonyWorkspaceTrackerBindingsUseCase(
                workspaceTrackerBindingPort: workspaceTrackerBindingRepository
            )
        )

        return SymphonyStartupService(
            workspaceBindingResolutionService: workspaceBindingResolutionService,
            resolveWorkflowConfigurationUseCase: resolveWorkflowConfigurationUseCase,
            validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase(
                startupConfigurationValidatorPort: ValidateSymphonyStartupConfigurationPortAdapter()
            ),
            validateTrackerConnectionUseCase: ValidateSymphonyTrackerConnectionReadinessUseCase(
                trackerAuthPort: trackerAuthPortAdapter
            ),
            startupStateTransition: SymphonyStartupStateTransition()
        )
    }
}
