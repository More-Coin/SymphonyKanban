@MainActor
public enum SymphonyUIDI {
    @MainActor
    public static func makeNavigationRoutes() -> SymphonyNavigationRoutes {
        let runtimeQueryService = makeRuntimeQueryService()
        return SymphonyNavigationRoutes(
            dashboardController: SymphonyDashboardController(
                runtimeQueryService: runtimeQueryService
            ),
            issueDetailController: SymphonyIssueDetailController(
                runtimeQueryService: runtimeQueryService
            ),
            refreshController: SymphonyRefreshController(),
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
}
