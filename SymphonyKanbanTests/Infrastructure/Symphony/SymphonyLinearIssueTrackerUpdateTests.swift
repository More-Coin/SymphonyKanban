import Foundation
import Testing
@testable import SymphonyKanban

struct SymphonyLinearIssueTrackerUpdateTests {
    @Test
    func updateIssueResolvesCanceledWorkflowStateByTeamAndUsesStateIdMutation() async throws {
        let executor = LinearRequestExecutorSpy(results: [
            .success(SymphonyLinearIssueTrackerGatewayTestSupport.httpResponse(statusCode: 200, body: """
            {
              "data": {
                "team": {
                  "id": "team-ios",
                  "states": {
                    "nodes": [
                      {
                        "id": "state-canceled-later",
                        "name": "Canceled Later",
                        "type": "canceled",
                        "position": 9
                      },
                      {
                        "id": "state-canceled-first",
                        "name": "Canceled",
                        "type": "canceled",
                        "position": 4
                      }
                    ]
                  }
                }
              }
            }
            """)),
            .success(SymphonyLinearIssueTrackerGatewayTestSupport.httpResponse(statusCode: 200, body: """
            {
              "data": {
                "issueUpdate": {
                  "success": true,
                  "issue": {
                    "id": "issue-1",
                    "identifier": "ABC-1",
                    "title": "Cancelable issue",
                    "state": { "id": "state-canceled-first", "name": "Canceled", "type": "canceled" },
                    "team": { "id": "team-ios" }
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

        let result = try await gateway.updateIssue(
            SymphonyIssueUpdateRequestContract(
                issueIdentifier: "ABC-1",
                stateChange: SymphonyIssueStateChangeContract(targetStateType: "canceled")
            ),
            currentIssue: makeIssue(teamID: "team-ios"),
            using: SymphonyLinearIssueTrackerGatewayTestSupport.trackerConfiguration()
        )

        let requests = await executor.requests()
        let lookupRequest = try SymphonyLinearIssueTrackerGatewayTestSupport.requestBody(requests[0])
        let updateRequest = try SymphonyLinearIssueTrackerGatewayTestSupport.requestBody(requests[1])

        #expect(result.issueIdentifier == "ABC-1")
        #expect(result.appliedStateID == "state-canceled-first")
        #expect(lookupRequest.query.contains("query FetchTeamWorkflowStatesByType"))
        #expect(lookupRequest.variables["teamId"] as? String == "team-ios")
        #expect(lookupRequest.variables["stateType"] as? String == "canceled")
        #expect(updateRequest.query.contains("mutation UpdateIssueState"))
        #expect(updateRequest.variables["issueId"] as? String == "issue-1")
        #expect(updateRequest.variables["stateId"] as? String == "state-canceled-first")
    }

    @Test
    func updateIssueFailsWhenCanceledWorkflowStateIsMissing() async throws {
        let executor = LinearRequestExecutorSpy(results: [
            .success(SymphonyLinearIssueTrackerGatewayTestSupport.httpResponse(statusCode: 200, body: """
            {
              "data": {
                "team": {
                  "id": "team-ios",
                  "states": {
                    "nodes": []
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

        await #expect(throws: SymphonyIssueTrackerInfrastructureError.self) {
            _ = try await gateway.updateIssue(
                SymphonyIssueUpdateRequestContract(
                    issueIdentifier: "ABC-1",
                    stateChange: SymphonyIssueStateChangeContract(targetStateType: "canceled")
                ),
                currentIssue: makeIssue(teamID: "team-ios"),
                using: SymphonyLinearIssueTrackerGatewayTestSupport.trackerConfiguration()
            )
        }
    }

    @Test
    func updateIssueFailsWhenIssueTeamMetadataIsMissing() async throws {
        let gateway = SymphonyLinearIssueTrackerGatewayTestSupport.makeGateway(
            executor: { _ in
                try IssueTrackerUnexpectedRequestError.raise()
            }
        )

        await #expect(throws: SymphonyIssueTrackerInfrastructureError.self) {
            _ = try await gateway.updateIssue(
                SymphonyIssueUpdateRequestContract(
                    issueIdentifier: "ABC-1",
                    stateChange: SymphonyIssueStateChangeContract(targetStateType: "canceled")
                ),
                currentIssue: makeIssue(teamID: nil),
                using: SymphonyLinearIssueTrackerGatewayTestSupport.trackerConfiguration()
            )
        }
    }

    private func makeIssue(teamID: String?) -> SymphonyIssue {
        SymphonyIssue(
            id: "issue-1",
            identifier: "ABC-1",
            title: "Cancelable issue",
            description: nil,
            priority: 1,
            state: "Todo",
            stateType: "unstarted",
            currentStateID: "state-todo",
            teamID: teamID,
            branchName: nil,
            url: nil,
            labels: [],
            blockedBy: [],
            createdAt: nil,
            updatedAt: nil
        )
    }
}

private enum IssueTrackerUnexpectedRequestError: Error {
    case unexpectedRequest

    static func raise() throws -> (Data, HTTPURLResponse) {
        throw unexpectedRequest
    }
}
