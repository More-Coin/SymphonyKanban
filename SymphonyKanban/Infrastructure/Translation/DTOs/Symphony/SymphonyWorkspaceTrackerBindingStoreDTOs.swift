import Foundation

struct SymphonyWorkspaceTrackerBindingStoreDTO: Codable, Sendable {
    let bindings: [SymphonyWorkspaceTrackerBindingRecordDTO]
}

struct SymphonyWorkspaceTrackerBindingRecordDTO: Codable, Sendable {
    let workspacePath: String
    let explicitWorkflowPath: String?
    let trackerKind: String
    let scopeKind: String
    let scopeIdentifier: String
    let scopeName: String
}
