import SwiftUI

@MainActor
public enum SymphonyUIDI {
    @MainActor
    public static func makeNavigationRoutes(
        pendingTrackerAuthCallbackURL: Binding<URL?> = .constant(nil)
    ) -> SymphonyNavigationRoutes {
        let runtimeQueryService = makeRuntimeQueryService()
        let environment = ProcessInfo.processInfo.environment
        let browserRuntime = SymphonyTrackerAuthBrowserRuntime()

        return SymphonyNavigationRoutes(
            issueDetailController: SymphonyIssueDetailController(
                runtimeQueryService: runtimeQueryService
            ),
            authController: makeAuthController(
                environment: environment
            ),
            pendingTrackerAuthCallbackURL: pendingTrackerAuthCallbackURL,
            launchTrackerAuthorizationURL: { url in
                browserRuntime.open(url)
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
}
