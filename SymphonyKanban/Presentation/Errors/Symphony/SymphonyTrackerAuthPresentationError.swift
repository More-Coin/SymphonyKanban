import Foundation

public enum SymphonyTrackerAuthPresentationError: StructuredErrorProtocol, LocalizedError {
    case invalidAuthorizationURL
    case invalidCallbackURL
    case callbackTimedOut
    case callbackListenerFailed(details: String)

    public var code: String {
        switch self {
        case .invalidAuthorizationURL:
            return "symphony.presentation.invalid_authorization_url"
        case .invalidCallbackURL:
            return "symphony.presentation.invalid_callback_url"
        case .callbackTimedOut:
            return "symphony.presentation.callback_timed_out"
        case .callbackListenerFailed:
            return "symphony.presentation.callback_listener_failed"
        }
    }

    public var message: String {
        switch self {
        case .invalidAuthorizationURL:
            return "The authorization URL could not be opened."
        case .invalidCallbackURL:
            return "The callback URL could not be parsed."
        case .callbackTimedOut:
            return "The Linear callback did not arrive before the timeout."
        case .callbackListenerFailed:
            return "The local Linear callback listener could not be started."
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
            return "Check the localhost callback route and callback URL format."
        case .callbackTimedOut:
            return "Leave the browser open and complete Linear authorization before trying again."
        case .callbackListenerFailed(let details):
            return details
        }
    }

    public var errorDescription: String? {
        message
    }
}
