
public struct SymphonyWorkspaceContract: Equatable, Sendable {
    public let path: String
    public let workspaceKey: SymphonyWorkspaceKey
    public let createdNow: Bool

    public init(
        path: String,
        workspaceKey: SymphonyWorkspaceKey,
        createdNow: Bool
    ) {
        self.path = path
        self.workspaceKey = workspaceKey
        self.createdNow = createdNow
    }
}
