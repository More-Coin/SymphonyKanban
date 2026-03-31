import Foundation

public enum SymphonyIssueTrackerInfrastructureError: StructuredErrorProtocol, LocalizedError {
    case unsupportedTrackerKind(actualKind: String?)
    case missingTrackerScope
    case ambiguousTrackerScope
    case missingTrackerSession
    case staleTrackerSession(details: String?)
    case linearAPIRequest(details: String)
    case linearAPIStatus(statusCode: Int, responseBody: String?)
    case linearGraphQLErrors(messages: [String])
    case linearUnknownPayload(details: String)
    case linearMissingEndCursor
    case missingIssueTeam(issueIdentifier: String)
    case missingWorkflowState(teamID: String, stateType: String)
    case linearIssueUpdateFailed(issueIdentifier: String)

    public var code: String {
        switch self {
        case .unsupportedTrackerKind:
            return "symphony.tracker.unsupported_tracker_kind"
        case .missingTrackerScope:
            return "symphony.tracker.missing_tracker_scope"
        case .ambiguousTrackerScope:
            return "symphony.tracker.ambiguous_tracker_scope"
        case .missingTrackerSession:
            return "symphony.tracker.missing_tracker_session"
        case .staleTrackerSession:
            return "symphony.tracker.stale_tracker_session"
        case .linearAPIRequest:
            return "symphony.tracker.linear_api_request"
        case .linearAPIStatus:
            return "symphony.tracker.linear_api_status"
        case .linearGraphQLErrors:
            return "symphony.tracker.linear_graphql_errors"
        case .linearUnknownPayload:
            return "symphony.tracker.linear_unknown_payload"
        case .linearMissingEndCursor:
            return "symphony.tracker.linear_missing_end_cursor"
        case .missingIssueTeam:
            return "symphony.tracker.missing_issue_team"
        case .missingWorkflowState:
            return "symphony.tracker.missing_workflow_state"
        case .linearIssueUpdateFailed:
            return "symphony.tracker.linear_issue_update_failed"
        }
    }

    public var message: String {
        switch self {
        case .unsupportedTrackerKind:
            return "The configured tracker kind is not supported by the Linear read gateway."
        case .missingTrackerScope:
            return "The workflow configuration is missing the Linear team or project scope."
        case .ambiguousTrackerScope:
            return "The workflow configuration must define exactly one Linear team or project scope."
        case .missingTrackerSession:
            return "No stored tracker session is available for Linear."
        case .staleTrackerSession:
            return "The stored Linear tracker session is stale."
        case .linearAPIRequest:
            return "The Linear API request failed before a valid HTTP response was received."
        case .linearAPIStatus:
            return "The Linear API returned an unsuccessful HTTP status."
        case .linearGraphQLErrors:
            return "The Linear GraphQL API returned top-level errors."
        case .linearUnknownPayload:
            return "The Linear API returned a payload that could not be normalized."
        case .linearMissingEndCursor:
            return "The Linear API reported more pages but did not return an end cursor."
        case .missingIssueTeam:
            return "The selected Linear issue did not include the owning team needed for a state update."
        case .missingWorkflowState:
            return "Linear did not return a matching workflow state for the requested transition."
        case .linearIssueUpdateFailed:
            return "The Linear issue update mutation did not succeed."
        }
    }

    public var retryable: Bool {
        switch self {
        case .linearAPIRequest, .linearAPIStatus:
            return true
        case .unsupportedTrackerKind,
             .missingTrackerScope,
             .ambiguousTrackerScope,
             .missingTrackerSession,
             .staleTrackerSession,
             .linearGraphQLErrors,
             .linearUnknownPayload,
             .linearMissingEndCursor,
             .missingIssueTeam,
             .missingWorkflowState,
             .linearIssueUpdateFailed:
            return false
        }
    }

    public var details: String? {
        switch self {
        case .unsupportedTrackerKind(let actualKind):
            return actualKind.map { "Received configured tracker kind `\($0)`." }
        case .missingTrackerScope:
            return "Set either `tracker.project_slug` or `tracker.team_id` in the workflow configuration."
        case .ambiguousTrackerScope:
            return "Remove one of `tracker.project_slug` or `tracker.team_id` so the workflow points at exactly one Linear scope."
        case .missingTrackerSession:
            return "Connect Linear through the OAuth flow before fetching issues."
        case .staleTrackerSession(let details):
            return details ?? "Reconnect Linear to replace the stale stored session."
        case .linearAPIRequest(let details):
            return details
        case .linearAPIStatus(let statusCode, let responseBody):
            if let responseBody, !responseBody.isEmpty {
                return "Status: \(statusCode). Body: \(responseBody)"
            }
            return "Status: \(statusCode)."
        case .linearGraphQLErrors(let messages):
            return messages.joined(separator: " | ")
        case .linearUnknownPayload(let details):
            return details
        case .linearMissingEndCursor:
            return "The GraphQL pageInfo block returned `hasNextPage=true` without a non-empty `endCursor`."
        case .missingIssueTeam(let issueIdentifier):
            return "Issue `\(issueIdentifier)` must include `team.id` in the Linear payload before Symphony can update its state."
        case .missingWorkflowState(let teamID, let stateType):
            return "Team `\(teamID)` did not expose a workflow state for type `\(stateType)`."
        case .linearIssueUpdateFailed(let issueIdentifier):
            return "Linear returned `success=false` for issue `\(issueIdentifier)`."
        }
    }

    public var errorDescription: String? {
        message
    }
}
