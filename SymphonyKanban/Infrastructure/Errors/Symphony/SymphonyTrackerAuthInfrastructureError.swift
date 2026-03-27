import Foundation

public enum SymphonyTrackerAuthInfrastructureError: StructuredErrorProtocol, LocalizedError {
    case unsupportedTrackerKind(actualKind: String?)
    case missingOAuthClientID
    case missingOAuthRedirectURI
    case invalidOAuthRedirectURI(value: String)
    case authorizationURLBuildFailed
    case authorizationDenied(errorCode: String, errorDescription: String?)
    case missingAuthorizationCode
    case missingAuthorizationState
    case missingPendingAuthorization
    case authorizationStateMismatch
    case tokenExchangeRequestFailed(details: String)
    case tokenExchangeStatus(statusCode: Int, responseBody: String?)
    case tokenExchangePayloadInvalid(details: String)
    case secureStoreFailure(details: String)

    public var code: String {
        switch self {
        case .unsupportedTrackerKind:
            return "symphony.tracker_auth.unsupported_tracker_kind"
        case .missingOAuthClientID:
            return "symphony.tracker_auth.missing_oauth_client_id"
        case .missingOAuthRedirectURI:
            return "symphony.tracker_auth.missing_oauth_redirect_uri"
        case .invalidOAuthRedirectURI:
            return "symphony.tracker_auth.invalid_oauth_redirect_uri"
        case .authorizationURLBuildFailed:
            return "symphony.tracker_auth.authorization_url_build_failed"
        case .authorizationDenied:
            return "symphony.tracker_auth.authorization_denied"
        case .missingAuthorizationCode:
            return "symphony.tracker_auth.missing_authorization_code"
        case .missingAuthorizationState:
            return "symphony.tracker_auth.missing_authorization_state"
        case .missingPendingAuthorization:
            return "symphony.tracker_auth.missing_pending_authorization"
        case .authorizationStateMismatch:
            return "symphony.tracker_auth.authorization_state_mismatch"
        case .tokenExchangeRequestFailed:
            return "symphony.tracker_auth.token_exchange_request_failed"
        case .tokenExchangeStatus:
            return "symphony.tracker_auth.token_exchange_status"
        case .tokenExchangePayloadInvalid:
            return "symphony.tracker_auth.token_exchange_payload_invalid"
        case .secureStoreFailure:
            return "symphony.tracker_auth.secure_store_failure"
        }
    }

    public var message: String {
        switch self {
        case .unsupportedTrackerKind:
            return "The configured tracker kind is not supported by the tracker auth adapter."
        case .missingOAuthClientID:
            return "The Linear OAuth client ID is missing."
        case .missingOAuthRedirectURI:
            return "The Linear OAuth redirect URI is missing."
        case .invalidOAuthRedirectURI:
            return "The Linear OAuth redirect URI is invalid."
        case .authorizationURLBuildFailed:
            return "The Linear authorization URL could not be created."
        case .authorizationDenied:
            return "Linear denied the authorization request."
        case .missingAuthorizationCode:
            return "The callback did not include an authorization code."
        case .missingAuthorizationState:
            return "The callback did not include an authorization state."
        case .missingPendingAuthorization:
            return "No pending authorization flow was found for the callback."
        case .authorizationStateMismatch:
            return "The callback state did not match the pending authorization flow."
        case .tokenExchangeRequestFailed:
            return "The Linear token request failed before a valid response was received."
        case .tokenExchangeStatus:
            return "The Linear token endpoint returned an unsuccessful HTTP status."
        case .tokenExchangePayloadInvalid:
            return "The Linear token response payload could not be decoded."
        case .secureStoreFailure:
            return "The tracker auth session could not be persisted."
        }
    }

    public var retryable: Bool {
        switch self {
        case .tokenExchangeRequestFailed, .tokenExchangeStatus, .secureStoreFailure:
            return true
        case .unsupportedTrackerKind,
             .missingOAuthClientID,
             .missingOAuthRedirectURI,
             .invalidOAuthRedirectURI,
             .authorizationURLBuildFailed,
             .authorizationDenied,
             .missingAuthorizationCode,
             .missingAuthorizationState,
             .missingPendingAuthorization,
             .authorizationStateMismatch,
             .tokenExchangePayloadInvalid:
            return false
        }
    }

    public var details: String? {
        switch self {
        case .unsupportedTrackerKind(let actualKind):
            return actualKind.map { "Received tracker kind `\($0)`." }
        case .missingOAuthClientID:
            return "Set `LINEAR_OAUTH_CLIENT_ID` in the host environment."
        case .missingOAuthRedirectURI:
            return "Set `LINEAR_OAUTH_REDIRECT_URI` in the host environment."
        case .invalidOAuthRedirectURI(let value):
            return "Received redirect URI `\(value)`."
        case .authorizationURLBuildFailed:
            return "Check the configured client ID, redirect URI, and scope values."
        case .authorizationDenied(let errorCode, let errorDescription):
            if let errorDescription, !errorDescription.isEmpty {
                return "Code: \(errorCode). Description: \(errorDescription)"
            }
            return "Code: \(errorCode)."
        case .missingAuthorizationCode:
            return "The callback must include a non-empty `code` query parameter."
        case .missingAuthorizationState:
            return "The callback must include a non-empty `state` query parameter."
        case .missingPendingAuthorization:
            return "Start a new authorization flow before completing the callback."
        case .authorizationStateMismatch:
            return "Discard the callback and start a fresh authorization flow."
        case .tokenExchangeRequestFailed(let details):
            return details
        case .tokenExchangeStatus(let statusCode, let responseBody):
            if let responseBody, !responseBody.isEmpty {
                return "Status: \(statusCode). Body: \(responseBody)"
            }
            return "Status: \(statusCode)."
        case .tokenExchangePayloadInvalid(let details):
            return details
        case .secureStoreFailure(let details):
            return details
        }
    }

    public var errorDescription: String? {
        message
    }
}
