import Foundation

enum SymphonyStartupPresentationError: StructuredErrorProtocol, LocalizedError {
    case invalidArguments

    var code: String {
        switch self {
        case .invalidArguments:
            return "symphony.presentation.invalid_arguments"
        }
    }

    var message: String {
        switch self {
        case .invalidArguments:
            return "Usage: symphony [path-to-WORKFLOW.md]"
        }
    }

    var retryable: Bool {
        false
    }

    var details: String? {
        switch self {
        case .invalidArguments:
            return "Provide zero or one positional workflow path argument."
        }
    }

    var errorDescription: String? {
        message
    }
}
