import Foundation
import Testing
@testable import SymphonyKanban

struct SymphonyLinearIssueTrackerCandidateFetchTests {
    @Test
    func fetchCandidateIssuesPaginatesNormalizesAndPreservesOrder() async throws {
        let executor = LinearRequestExecutorSpy(results: [
            .success(SymphonyLinearIssueTrackerGatewayTestSupport.httpResponse(statusCode: 200, body: """
            {
              "data": {
                "issues": {
                  "nodes": [
                    {
                      "id": "issue-1",
                      "identifier": "ABC-1",
                      "title": "First",
                      "description": "First issue",
                      "priority": 2,
                      "branchName": "feature/abc-1",
                      "url": "https://linear.app/ABC-1",
                      "createdAt": "2024-03-20T10:00:00Z",
                      "updatedAt": "2024-03-21T10:00:00Z",
                      "state": { "name": "Todo" },
                      "labels": { "nodes": [{ "name": "Bug" }] },
                      "inverseRelations": {
                        "nodes": [
                          {
                            "type": "blocks",
                            "relatedIssue": {
                              "id": "blocker-1",
                              "identifier": "ABC-0",
                              "state": { "name": "Done" }
                            }
                          },
                          {
                            "type": "relates_to",
                            "relatedIssue": {
                              "id": "ignored-1",
                              "identifier": "ABC-X",
                              "state": { "name": "Done" }
                            }
                          }
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
                "issues": {
                  "nodes": [
                    {
                      "id": "issue-2",
                      "identifier": "ABC-2",
                      "title": "Second",
                      "description": null,
                      "priority": "high",
                      "branchName": null,
                      "url": null,
                      "createdAt": "2024-03-22T10:00:00Z",
                      "updatedAt": null,
                      "state": { "name": "In Progress" },
                      "labels": { "nodes": [{ "name": "Needs-Review" }] },
                      "inverseRelations": { "nodes": [] }
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
        let gateway = SymphonyLinearIssueTrackerGateway(
            requestExecutor: { request in
                try await executor.execute(request)
            }
        )

        let issues = try await gateway.fetchCandidateIssues(using: SymphonyLinearIssueTrackerGatewayTestSupport.trackerConfiguration())
        let requests = await executor.requests()

        #expect(issues.map(\.identifier) == ["ABC-1", "ABC-2"])
        #expect(issues[0].labels == ["bug"])
        #expect(issues[0].blockedBy == [
            SymphonyIssueBlockerReference(id: "blocker-1", identifier: "ABC-0", state: "Done")
        ])
        #expect(issues[1].priority == nil)
        #expect(issues[1].labels == ["needs-review"])
        #expect(issues[0].createdAt == SymphonyLinearIssueTrackerGatewayTestSupport.date("2024-03-20T10:00:00Z"))
        #expect(requests.count == 2)

        let firstRequestBody = try SymphonyLinearIssueTrackerGatewayTestSupport.requestBody(requests[0])
        let secondRequestBody = try SymphonyLinearIssueTrackerGatewayTestSupport.requestBody(requests[1])
        #expect(firstRequestBody.query.contains("slugId"))
        #expect(firstRequestBody.variables["projectSlug"] as? String == "project-slug")
        #expect(firstRequestBody.variables["states"] as? [String] == ["Todo", "In Progress"])
        #expect(firstRequestBody.variables["after"] is NSNull)
        #expect(secondRequestBody.variables["after"] as? String == "cursor-1")
    }

    @Test
    func fetchCandidateIssuesUsesDefaultEndpointAuthorizationHeaderAndTimeout() async throws {
        let executor = LinearRequestExecutorSpy(results: [
            .success(SymphonyLinearIssueTrackerGatewayTestSupport.httpResponse(statusCode: 200, body: """
            {
              "data": {
                "issues": {
                  "nodes": [],
                  "pageInfo": {
                    "hasNextPage": false,
                    "endCursor": null
                  }
                }
              }
            }
            """))
        ])
        let gateway = SymphonyLinearIssueTrackerGateway(
            requestExecutor: { request in
                try await executor.execute(request)
            }
        )

        _ = try await gateway.fetchCandidateIssues(
            using: SymphonyServiceConfigContract.Tracker(
                kind: "linear",
                endpoint: nil,
                apiKey: "linear-token",
                projectSlug: "project-slug",
                activeStates: ["Todo", "In Progress"],
                terminalStates: ["Done", "Canceled"]
            )
        )

        let request = try #require(await executor.requests().first)
        let requestBody = try SymphonyLinearIssueTrackerGatewayTestSupport.requestBody(request)

        #expect(request.url?.absoluteString == "https://api.linear.app/graphql")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "linear-token")
        #expect(request.timeoutInterval == 30)
        #expect(requestBody.query.contains("first: 50"))
    }

    @Test
    func fetchCandidateIssuesMapsGraphQLErrorsToTypedInfrastructureError() async throws {
        let executor = LinearRequestExecutorSpy(results: [
            .success(SymphonyLinearIssueTrackerGatewayTestSupport.httpResponse(statusCode: 200, body: """
            {
              "errors": [
                { "message": "Forbidden" }
              ]
            }
            """))
        ])
        let gateway = SymphonyLinearIssueTrackerGateway(
            requestExecutor: { request in
                try await executor.execute(request)
            }
        )

        await #expect(throws: SymphonyIssueTrackerInfrastructureError.self) {
            _ = try await gateway.fetchCandidateIssues(using: SymphonyLinearIssueTrackerGatewayTestSupport.trackerConfiguration())
        }
    }

    @Test
    func fetchCandidateIssuesMapsNonSuccessfulStatusToTypedInfrastructureError() async throws {
        let executor = LinearRequestExecutorSpy(results: [
            .success(SymphonyLinearIssueTrackerGatewayTestSupport.httpResponse(statusCode: 503, body: """
            {
              "errors": [
                { "message": "Unavailable" }
              ]
            }
            """))
        ])
        let gateway = SymphonyLinearIssueTrackerGateway(
            requestExecutor: { request in
                try await executor.execute(request)
            }
        )

        do {
            _ = try await gateway.fetchCandidateIssues(using: SymphonyLinearIssueTrackerGatewayTestSupport.trackerConfiguration())
            Issue.record("Expected a non-200 status error.")
        } catch let error as SymphonyIssueTrackerInfrastructureError {
            guard case .linearAPIStatus(let statusCode, _) = error else {
                Issue.record("Expected linearAPIStatus, received \(error).")
                return
            }

            #expect(statusCode == 503)
        } catch {
            Issue.record("Expected SymphonyIssueTrackerInfrastructureError, received \(error).")
        }
    }

    @Test
    func fetchCandidateIssuesMapsTransportFailuresToTypedInfrastructureError() async throws {
        struct StubTransportError: Error {}

        let executor = LinearRequestExecutorSpy(results: [
            .failure(StubTransportError())
        ])
        let gateway = SymphonyLinearIssueTrackerGateway(
            requestExecutor: { request in
                try await executor.execute(request)
            }
        )

        do {
            _ = try await gateway.fetchCandidateIssues(using: SymphonyLinearIssueTrackerGatewayTestSupport.trackerConfiguration())
            Issue.record("Expected a transport failure error.")
        } catch let error as SymphonyIssueTrackerInfrastructureError {
            guard case .linearAPIRequest = error else {
                Issue.record("Expected linearAPIRequest, received \(error).")
                return
            }
        } catch {
            Issue.record("Expected SymphonyIssueTrackerInfrastructureError, received \(error).")
        }
    }

    @Test
    func fetchCandidateIssuesRequiresEndCursorWhenMorePagesRemain() async throws {
        let executor = LinearRequestExecutorSpy(results: [
            .success(SymphonyLinearIssueTrackerGatewayTestSupport.httpResponse(statusCode: 200, body: """
            {
              "data": {
                "issues": {
                  "nodes": [],
                  "pageInfo": {
                    "hasNextPage": true,
                    "endCursor": null
                  }
                }
              }
            }
            """))
        ])
        let gateway = SymphonyLinearIssueTrackerGateway(
            requestExecutor: { request in
                try await executor.execute(request)
            }
        )

        await #expect(throws: SymphonyIssueTrackerInfrastructureError.self) {
            _ = try await gateway.fetchCandidateIssues(using: SymphonyLinearIssueTrackerGatewayTestSupport.trackerConfiguration())
        }
    }
}
