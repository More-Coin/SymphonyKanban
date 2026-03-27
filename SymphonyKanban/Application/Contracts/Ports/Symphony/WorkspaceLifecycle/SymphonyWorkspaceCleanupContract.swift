public struct SymphonyWorkspaceCleanupContract: Equatable, Sendable {
    public let workspacePath: String
    public let removed: Bool

    public init(
        workspacePath: String,
        removed: Bool
    ) {
        self.workspacePath = workspacePath
        self.removed = removed
    }
}
