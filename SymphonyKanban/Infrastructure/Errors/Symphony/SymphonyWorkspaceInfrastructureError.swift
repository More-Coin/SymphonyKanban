import Foundation

public enum SymphonyWorkspaceInfrastructureError: StructuredErrorProtocol, LocalizedError {
    case invalidWorkspaceRoot(path: String)
    case workspacePathOutsideRoot(rootPath: String, workspacePath: String)
    case workspaceLocationNotDirectory(path: String)
    case workspaceCreationFailed(path: String, details: String)
    case workspacePreparationFailed(path: String, details: String)
    case workspaceRemovalFailed(path: String, details: String)
    case hookFailed(kind: String, workspacePath: String, details: String)
    case hookTimedOut(kind: String, workspacePath: String, timeoutMs: Int)
    case invalidWorkspaceCWD(expected: String, actual: String)
    case bindingStorageUnavailable(details: String)
    case bindingLoadFailed(path: String, details: String)
    case bindingSaveFailed(path: String, details: String)
    case bindingRemovalFailed(path: String, details: String)

    public var code: String {
        switch self {
        case .invalidWorkspaceRoot:
            return "symphony.workspace.invalid_workspace_root"
        case .workspacePathOutsideRoot:
            return "symphony.workspace.path_outside_root"
        case .workspaceLocationNotDirectory:
            return "symphony.workspace.location_not_directory"
        case .workspaceCreationFailed:
            return "symphony.workspace.creation_failed"
        case .workspacePreparationFailed:
            return "symphony.workspace.preparation_failed"
        case .workspaceRemovalFailed:
            return "symphony.workspace.removal_failed"
        case .hookFailed:
            return "symphony.workspace.hook_failed"
        case .hookTimedOut:
            return "symphony.workspace.hook_timed_out"
        case .invalidWorkspaceCWD:
            return "symphony.workspace.invalid_workspace_cwd"
        case .bindingStorageUnavailable:
            return "symphony.workspace.binding_storage_unavailable"
        case .bindingLoadFailed:
            return "symphony.workspace.binding_load_failed"
        case .bindingSaveFailed:
            return "symphony.workspace.binding_save_failed"
        case .bindingRemovalFailed:
            return "symphony.workspace.binding_removal_failed"
        }
    }

    public var message: String {
        switch self {
        case .invalidWorkspaceRoot:
            return "The configured workspace root is not a readable directory."
        case .workspacePathOutsideRoot:
            return "The resolved workspace path is outside the configured workspace root."
        case .workspaceLocationNotDirectory:
            return "The workspace location already exists but is not a directory."
        case .workspaceCreationFailed:
            return "The workspace directory could not be created."
        case .workspacePreparationFailed:
            return "The workspace could not be prepared for the current run attempt."
        case .workspaceRemovalFailed:
            return "The workspace could not be removed."
        case .hookFailed:
            return "A workspace lifecycle hook failed."
        case .hookTimedOut:
            return "A workspace lifecycle hook timed out."
        case .invalidWorkspaceCWD:
            return "The coding-agent launch directory does not match the validated workspace path."
        case .bindingStorageUnavailable:
            return "The workspace-binding storage location is unavailable."
        case .bindingLoadFailed:
            return "Saved workspace bindings could not be loaded."
        case .bindingSaveFailed:
            return "The workspace binding could not be saved."
        case .bindingRemovalFailed:
            return "The workspace binding could not be removed."
        }
    }

    public var retryable: Bool {
        switch self {
        case .invalidWorkspaceRoot,
             .workspacePathOutsideRoot,
             .workspaceLocationNotDirectory,
             .invalidWorkspaceCWD,
             .bindingStorageUnavailable:
            return false
        case .workspaceCreationFailed,
             .workspacePreparationFailed,
             .workspaceRemovalFailed,
             .hookFailed,
             .hookTimedOut,
             .bindingLoadFailed,
             .bindingSaveFailed,
             .bindingRemovalFailed:
            return true
        }
    }

    public var details: String? {
        switch self {
        case .invalidWorkspaceRoot(let path):
            return "Path: \(path)"
        case .workspacePathOutsideRoot(let rootPath, let workspacePath):
            return "Root: \(rootPath). Workspace: \(workspacePath)"
        case .workspaceLocationNotDirectory(let path):
            return "Path: \(path)"
        case .workspaceCreationFailed(let path, let details),
             .workspacePreparationFailed(let path, let details),
             .workspaceRemovalFailed(let path, let details):
            return "Path: \(path). \(details)"
        case .hookFailed(let kind, let workspacePath, let details):
            return "Hook: \(kind). Workspace: \(workspacePath). \(details)"
        case .hookTimedOut(let kind, let workspacePath, let timeoutMs):
            return "Hook: \(kind). Workspace: \(workspacePath). Timeout: \(timeoutMs) ms."
        case .invalidWorkspaceCWD(let expected, let actual):
            return "Expected: \(expected). Actual: \(actual)"
        case .bindingStorageUnavailable(let details):
            return details
        case .bindingLoadFailed(let path, let details),
             .bindingSaveFailed(let path, let details),
             .bindingRemovalFailed(let path, let details):
            return "Path: \(path). \(details)"
        }
    }

    public var errorDescription: String? {
        message
    }
}
