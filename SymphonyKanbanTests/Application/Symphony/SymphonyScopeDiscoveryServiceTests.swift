import Testing
@testable import SymphonyKanban

@Suite
struct SymphonyScopeDiscoveryServiceTests {
    @Test
    func queryAvailableScopesCombinesTeamsAndProjectsIntoStableSingleBindingOptions() async throws {
        let port = SymphonyTrackerScopeReadPortSpy(
            teamsResponse: [
                SymphonyTrackerScopeOptionContract(
                    id: "team:design",
                    scopeKind: "team",
                    scopeIdentifier: "design",
                    scopeName: "Design"
                ),
                SymphonyTrackerScopeOptionContract(
                    id: "team:api",
                    scopeKind: "team",
                    scopeIdentifier: "api",
                    scopeName: "API"
                )
            ],
            projectsResponse: [
                SymphonyTrackerScopeOptionContract(
                    id: "project:mobile",
                    scopeKind: "project",
                    scopeIdentifier: "mobile",
                    scopeName: "Mobile"
                ),
                SymphonyTrackerScopeOptionContract(
                    id: "project:alpha",
                    scopeKind: "project",
                    scopeIdentifier: "alpha",
                    scopeName: "Alpha"
                )
            ]
        )
        let service = SymphonyTrackerScopeService(
            fetchTeamsUseCase: FetchSymphonyTrackerTeamsUseCase(
                trackerScopeReadPort: port
            ),
            fetchProjectsUseCase: FetchSymphonyTrackerProjectsUseCase(
                trackerScopeReadPort: port
            )
        )

        let result = try await service.queryAvailableScopes(
            using: SymphonyServiceConfigContract.Tracker(
                kind: " Linear ",
                endpoint: nil,
                projectSlug: nil,
                activeStateTypes: [],
                terminalStateTypes: []
            )
        )

        #expect(result.options.map(\.scopeName) == ["API", "Design", "Alpha", "Mobile"])
    }
}
