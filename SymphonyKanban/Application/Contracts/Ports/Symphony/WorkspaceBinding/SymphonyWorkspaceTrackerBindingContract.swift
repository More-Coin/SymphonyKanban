public struct SymphonyWorkspaceTrackerBindingContract: Equatable, Sendable {
    public let workspacePath: String
    public let explicitWorkflowPath: String?
    public let trackerKind: String
    public let scopeKind: String
    public let scopeIdentifier: String
    public let scopeName: String

    public init(
        workspacePath: String,
        explicitWorkflowPath: String?,
        trackerKind: String,
        scopeKind: String,
        scopeIdentifier: String,
        scopeName: String
    ) {
        self.workspacePath = workspacePath
        self.explicitWorkflowPath = explicitWorkflowPath
        self.trackerKind = trackerKind
        self.scopeKind = scopeKind
        self.scopeIdentifier = scopeIdentifier
        self.scopeName = scopeName
    }
}
