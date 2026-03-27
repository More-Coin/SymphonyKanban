public struct SymphonyIssueBlockerReference: Equatable, Sendable {
    public let id: String?
    public let identifier: String?
    public let state: String?

    public init(
        id: String?,
        identifier: String?,
        state: String?
    ) {
        self.id = id
        self.identifier = identifier
        self.state = state
    }
}
