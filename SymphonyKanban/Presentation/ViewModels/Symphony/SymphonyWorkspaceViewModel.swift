public struct SymphonyWorkspaceViewModel: Equatable, Sendable {
    public let title: String
    public let pathLabel: String
    public let branchLabel: String?
    public let statusLabel: String

    public init(
        title: String,
        pathLabel: String,
        branchLabel: String?,
        statusLabel: String
    ) {
        self.title = title
        self.pathLabel = pathLabel
        self.branchLabel = branchLabel
        self.statusLabel = statusLabel
    }
}
