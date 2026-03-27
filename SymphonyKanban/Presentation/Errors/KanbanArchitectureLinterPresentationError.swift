import Foundation

enum KanbanArchitectureLinterPresentationError: StructuredErrorProtocol, LocalizedError {
    case invalidArguments

    var code: String {
        switch self {
        case .invalidArguments:
            return "kanban_architecture_linter.invalid_arguments"
        }
    }

    var message: String {
        switch self {
        case .invalidArguments:
            return "Usage: kanban-architecture-linter [repo-root]"
        }
    }

    var retryable: Bool {
        false
    }

    var details: String? {
        switch self {
        case .invalidArguments:
            return "Provide zero or one repo-root argument."
        }
    }

    var errorDescription: String? {
        message
    }
}
