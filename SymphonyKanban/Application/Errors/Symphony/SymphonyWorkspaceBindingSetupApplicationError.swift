import Foundation

public enum SymphonyWorkspaceBindingSetupApplicationError: StructuredErrorProtocol, LocalizedError {
    case missingWorkspaceSelection
    case missingScopeSelection

    public var code: String {
        switch self {
        case .missingWorkspaceSelection:
            return "symphony.workspace_binding_setup.missing_workspace_selection"
        case .missingScopeSelection:
            return "symphony.workspace_binding_setup.missing_scope_selection"
        }
    }

    public var message: String {
        switch self {
        case .missingWorkspaceSelection:
            return "A workspace folder must be selected before Symphony can finish setup."
        case .missingScopeSelection:
            return "A tracker scope must be selected before Symphony can finish setup."
        }
    }

    public var retryable: Bool {
        false
    }

    public var details: String? {
        switch self {
        case .missingWorkspaceSelection:
            return "Choose one local workspace folder before saving this tracker binding."
        case .missingScopeSelection:
            return "Choose exactly one team or project to save for this workspace."
        }
    }

    public var errorDescription: String? {
        message
    }
}
