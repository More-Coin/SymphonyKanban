import SwiftUI

@MainActor
public enum SymphonyUIDI {
    @MainActor
    public static func makeNavigationRoutes() -> SymphonyNavigationRoutes {
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
            initialSelectedIssueIdentifier: "KAN-142"
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
        let resolveWorkflowConfigurationUseCase = ResolveSymphonyWorkflowConfigurationUseCase(
            workflowLoaderPort: SymphonyWorkflowLoaderPortAdapter(
                environment: environment
            ),
            configResolverPort: SymphonyConfigResolverPortAdapter(
                environment: environment
            )
        )

        return SymphonyIssueCatalogController(
            issueCatalogService: SymphonyIssueCatalogService(
                trackerConfigurationPort: SymphonyIssueCatalogTrackerConfigurationPortAdapter(
                    resolveWorkflowConfigurationUseCase: resolveWorkflowConfigurationUseCase
                ),
                fetchIssuesUseCase: FetchSymphonyIssuesUseCase(
                    issueTrackerReadPort: SymphonyFallbackIssueTrackerPortAdapter(
                        trackerAuthPort: trackerAuthPortAdapter,
                        liveGateway: SymphonyLinearIssueTrackerGateway(
                            environment: environment
                        )
                    )
                )
            )
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
}
