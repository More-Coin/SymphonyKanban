public struct SymphonyWorkflowConfigurationRequestContract: Equatable, Sendable {
    public let explicitWorkflowPath: String?
    public let currentWorkingDirectoryPath: String

    public init(
        explicitWorkflowPath: String?,
        currentWorkingDirectoryPath: String
    ) {
        self.explicitWorkflowPath = explicitWorkflowPath
        self.currentWorkingDirectoryPath = currentWorkingDirectoryPath
    }
}
