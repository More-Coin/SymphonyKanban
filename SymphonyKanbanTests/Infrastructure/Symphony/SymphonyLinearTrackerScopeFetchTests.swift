import Foundation
import Testing
@testable import SymphonyKanban

struct SymphonyLinearTrackerScopeFetchTests {
    @Test
    func fetchTeamsUsesTeamsQueryAndMapsTeamIdentity() async throws {
        let executor = LinearRequestExecutorSpy(results: [
            .success(SymphonyLinearIssueTrackerGatewayTestSupport.httpResponse(statusCode: 200, body: """
            {
              "data": {
                "teams": {
                  "nodes": [
                    {
                      "id": "team-ios",
                      "name": "iOS",
                      "key": "IOS"
                    }
                  ]
                }
              }
            }
            """))
        ])
        let gateway = SymphonyLinearIssueTrackerGatewayTestSupport.makeGateway(
            executor: { request in
                try await executor.execute(request)
            }
        )

        let teams = try await gateway.fetchTeams(
            using: SymphonyServiceConfigContract.Tracker(
                kind: "linear",
                endpoint: nil,
                projectSlug: nil,
                activeStateTypes: [],
                terminalStateTypes: []
            )
        )

        let request = try #require(await executor.requests().first)
        let requestBody = try SymphonyLinearIssueTrackerGatewayTestSupport.requestBody(request)

        #expect(teams == [
            SymphonyTrackerScopeOptionContract(
                id: "team:team-ios",
                scopeKind: "team",
                scopeIdentifier: "team-ios",
                scopeName: "iOS",
                detailText: "Team key IOS"
            )
        ])
        #expect(requestBody.query.contains("query FetchTeams"))
        #expect(requestBody.query.contains("teams"))
        #expect(requestBody.variables.isEmpty)
    }

    @Test
    func fetchProjectsPaginatesAndPrefersSlugIdentifierForPersistence() async throws {
        let executor = LinearRequestExecutorSpy(results: [
            .success(SymphonyLinearIssueTrackerGatewayTestSupport.httpResponse(statusCode: 200, body: """
            {
              "data": {
                "projects": {
                  "nodes": [
                    {
                      "id": "project-1",
                      "name": "Mobile Rebuild",
                      "slugId": "mobile-rebuild",
                      "state": "planned",
                      "teams": {
                        "nodes": [
                          { "id": "team-ios", "name": "iOS", "key": "IOS" }
                        ]
                      }
                    }
                  ],
                  "pageInfo": {
                    "hasNextPage": true,
                    "endCursor": "cursor-1"
                  }
                }
              }
            }
            """)),
            .success(SymphonyLinearIssueTrackerGatewayTestSupport.httpResponse(statusCode: 200, body: """
            {
              "data": {
                "projects": {
                  "nodes": [
                    {
                      "id": "project-2",
                      "name": "Server Cleanup",
                      "slugId": null,
                      "state": "in_progress",
                      "teams": {
                        "nodes": [
                          { "id": "team-api", "name": "API", "key": "API" }
                        ]
                      }
                    }
                  ],
                  "pageInfo": {
                    "hasNextPage": false,
                    "endCursor": null
                  }
                }
              }
            }
            """))
        ])
        let gateway = SymphonyLinearIssueTrackerGatewayTestSupport.makeGateway(
            executor: { request in
                try await executor.execute(request)
            }
        )

        let projects = try await gateway.fetchProjects(
            using: SymphonyServiceConfigContract.Tracker(
                kind: "linear",
                endpoint: nil,
                projectSlug: nil,
                activeStateTypes: [],
                terminalStateTypes: []
            )
        )
        let requests = await executor.requests()
        let firstRequestBody = try SymphonyLinearIssueTrackerGatewayTestSupport.requestBody(requests[0])
        let secondRequestBody = try SymphonyLinearIssueTrackerGatewayTestSupport.requestBody(requests[1])

        #expect(projects.map(\.scopeIdentifier) == ["mobile-rebuild", "project-2"])
        #expect(projects.map(\.detailText) == ["planned • iOS", "in_progress • API"])
        #expect(firstRequestBody.query.contains("query FetchProjects"))
        #expect(firstRequestBody.variables["after"] is NSNull)
        #expect(secondRequestBody.variables["after"] as? String == "cursor-1")
    }

    @Test
    func fetchProjectsMapsGraphQLErrorsToTypedInfrastructureError() async throws {
        let executor = LinearRequestExecutorSpy(results: [
            .success(SymphonyLinearIssueTrackerGatewayTestSupport.httpResponse(statusCode: 200, body: """
            {
              "errors": [
                { "message": "Forbidden" }
              ]
            }
            """))
        ])
        let gateway = SymphonyLinearIssueTrackerGatewayTestSupport.makeGateway(
            executor: { request in
                try await executor.execute(request)
            }
        )

        await #expect(throws: SymphonyIssueTrackerInfrastructureError.self) {
            _ = try await gateway.fetchProjects(
                using: SymphonyServiceConfigContract.Tracker(
                    kind: "linear",
                    endpoint: nil,
                    projectSlug: nil,
                    activeStateTypes: [],
                    terminalStateTypes: []
                )
            )
        }
    }
}
