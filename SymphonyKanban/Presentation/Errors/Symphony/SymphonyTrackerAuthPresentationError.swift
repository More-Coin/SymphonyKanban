import Foundation

public enum SymphonyTrackerAuthPresentationError: StructuredErrorProtocol, LocalizedError {
    case invalidAuthorizationURL
    case invalidCallbackURL

    public var code: String {
        switch self {
        case .invalidAuthorizationURL:
            return "symphony.presentation.invalid_authorization_url"
        case .invalidCallbackURL:
            return "symphony.presentation.invalid_callback_url"
        }
    }

    public var message: String {
        switch self {
        case .invalidAuthorizationURL:
            return "The authorization URL could not be opened."
        case .invalidCallbackURL:
            return "The callback URL could not be parsed."
        }
    }

    public var retryable: Bool {
        false
    }

    public var details: String? {
        switch self {
        case .invalidAuthorizationURL:
            return "Reconnect Linear and try opening the browser again."
        case .invalidCallbackURL:
            return "Check the configured redirect URI and callback URL format."
        }
    }

    public var errorDescription: String? {
        message
    }
}
