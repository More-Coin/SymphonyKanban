public struct SymphonyWorkspaceLaunchValidationContract: Equatable, Sendable {
    public let workspacePath: String
    public let currentWorkingDirectoryPath: String

    public init(
        workspacePath: String,
        currentWorkingDirectoryPath: String
    ) {
        self.workspacePath = workspacePath
        self.currentWorkingDirectoryPath = currentWorkingDirectoryPath
    }
}
