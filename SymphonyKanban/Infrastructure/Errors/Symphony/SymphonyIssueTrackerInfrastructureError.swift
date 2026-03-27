import Foundation

public enum SymphonyIssueTrackerInfrastructureError: StructuredErrorProtocol, LocalizedError {
    case unsupportedTrackerKind(actualKind: String?)
    case missingTrackerAPIKey
    case missingTrackerProjectSlug
    case linearAPIRequest(details: String)
    case linearAPIStatus(statusCode: Int, responseBody: String?)
    case linearGraphQLErrors(messages: [String])
    case linearUnknownPayload(details: String)
    case linearMissingEndCursor

    public var code: String {
        switch self {
        case .unsupportedTrackerKind:
            return "symphony.tracker.unsupported_tracker_kind"
        case .missingTrackerAPIKey:
            return "symphony.tracker.missing_tracker_api_key"
        case .missingTrackerProjectSlug:
            return "symphony.tracker.missing_tracker_project_slug"
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
        }
    }

    public var message: String {
        switch self {
        case .unsupportedTrackerKind:
            return "The configured tracker kind is not supported by the Linear read gateway."
        case .missingTrackerAPIKey:
            return "The workflow configuration is missing the tracker API key."
        case .missingTrackerProjectSlug:
            return "The workflow configuration is missing the tracker project slug."
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
        }
    }

    public var retryable: Bool {
        switch self {
        case .linearAPIRequest, .linearAPIStatus:
            return true
        case .unsupportedTrackerKind,
             .missingTrackerAPIKey,
             .missingTrackerProjectSlug,
             .linearGraphQLErrors,
             .linearUnknownPayload,
             .linearMissingEndCursor:
            return false
        }
    }

    public var details: String? {
        switch self {
        case .unsupportedTrackerKind(let actualKind):
            return actualKind.map { "Received configured tracker kind `\($0)`." }
        case .missingTrackerAPIKey:
            return "Set the tracker API key directly or through a non-empty environment variable."
        case .missingTrackerProjectSlug:
            return "Set `tracker.project_slug` in the workflow configuration."
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
        }
    }

    public var errorDescription: String? {
        message
    }
}
