public struct SymphonyWorkspaceLocatorContract: Equatable, Sendable {
    public let currentWorkingDirectoryPath: String
    public let explicitWorkflowPath: String?

    public init(
        currentWorkingDirectoryPath: String,
        explicitWorkflowPath: String?
    ) {
        self.currentWorkingDirectoryPath = currentWorkingDirectoryPath
        self.explicitWorkflowPath = explicitWorkflowPath
    }
}
