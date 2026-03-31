import Foundation

public enum SymphonyWorkspaceSelectionApplicationError: StructuredErrorProtocol, LocalizedError, Equatable {
    case missingWorkspacePath
    case missingScopeSelection
    case unsupportedScopeKind(actualKind: String)
    case workflowScopeMismatch(
        expectedScopeKind: String,
        expectedScopeIdentifier: String,
        actualScopeKind: String,
        actualScopeIdentifier: String
    )

    public var code: String {
        switch self {
        case .missingWorkspacePath:
            return "symphony.workspace_selection.missing_workspace_path"
        case .missingScopeSelection:
            return "symphony.workspace_selection.missing_scope_selection"
        case .unsupportedScopeKind:
            return "symphony.workspace_selection.unsupported_scope_kind"
        case .workflowScopeMismatch:
            return "symphony.workspace_selection.workflow_scope_mismatch"
        }
    }

    public var message: String {
        switch self {
        case .missingWorkspacePath:
            return "A workspace folder must be selected before Symphony can continue setup."
        case .missingScopeSelection:
            return "Choose one team or project before Symphony creates a workflow file."
        case .unsupportedScopeKind:
            return "The selected tracker scope could not be mapped to a workflow file."
        case .workflowScopeMismatch:
            return "The selected folder already contains a workflow file for a different tracker scope."
        }
    }

    public var retryable: Bool {
        false
    }

    public var details: String? {
        switch self {
        case .missingWorkspacePath:
            return "Choose one local workspace folder before confirming the tracker binding."
        case .missingScopeSelection:
            return "Select exactly one tracker scope before choosing a workspace folder."
        case .unsupportedScopeKind(let actualKind):
            return "Received scope kind `\(actualKind)` but only `team` and `project` are supported."
        case .workflowScopeMismatch(
            let expectedScopeKind,
            let expectedScopeIdentifier,
            let actualScopeKind,
            let actualScopeIdentifier
        ):
            return "Selected `\(expectedScopeKind)` `\(expectedScopeIdentifier)` but the existing workflow config points to `\(actualScopeKind)` `\(actualScopeIdentifier)`."
        }
    }

    public var errorDescription: String? {
        message
    }
}
