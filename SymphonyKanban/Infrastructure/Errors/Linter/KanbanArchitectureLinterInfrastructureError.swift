import Foundation

public enum KanbanArchitectureLinterInfrastructureError: StructuredErrorProtocol, LocalizedError {
    case invalidRootDirectory(path: String)
    case unreadableSourceFile(path: String)

    public var code: String {
        switch self {
        case .invalidRootDirectory:
            return "kanban_architecture_linter.infrastructure.invalid_root_directory"
        case .unreadableSourceFile:
            return "kanban_architecture_linter.infrastructure.unreadable_source_file"
        }
    }

    public var message: String {
        switch self {
        case .invalidRootDirectory:
            return "The provided root directory is invalid or unreadable."
        case .unreadableSourceFile:
            return "A discovered Swift source file could not be read."
        }
    }

    public var retryable: Bool {
        switch self {
        case .invalidRootDirectory:
            return false
        case .unreadableSourceFile:
            return true
        }
    }

    public var details: String? {
        switch self {
        case .invalidRootDirectory(let path):
            return "Root path: \(path)"
        case .unreadableSourceFile(let path):
            return "Source path: \(path)"
        }
    }

    public var errorDescription: String? {
        message
    }
}
