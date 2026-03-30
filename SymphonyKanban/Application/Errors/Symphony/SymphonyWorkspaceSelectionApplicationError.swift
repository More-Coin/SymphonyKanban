import Foundation

public enum SymphonyWorkspaceSelectionApplicationError: StructuredErrorProtocol, LocalizedError {
    case missingWorkspacePath

    public var code: String {
        switch self {
        case .missingWorkspacePath:
            return "symphony.workspace_selection.missing_workspace_path"
        }
    }

    public var message: String {
        switch self {
        case .missingWorkspacePath:
            return "A workspace folder must be selected before Symphony can continue setup."
        }
    }

    public var retryable: Bool {
        false
    }

    public var details: String? {
        switch self {
        case .missingWorkspacePath:
            return "Choose one local workspace folder before confirming the tracker binding."
        }
    }

    public var errorDescription: String? {
        message
    }
}
