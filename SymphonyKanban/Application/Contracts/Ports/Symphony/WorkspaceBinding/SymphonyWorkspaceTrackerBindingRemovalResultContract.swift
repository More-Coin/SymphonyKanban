public struct SymphonyWorkspaceTrackerBindingRemovalResultContract: Equatable, Sendable {
    public let workspacePath: String

    public init(workspacePath: String) {
        self.workspacePath = workspacePath
    }
}
