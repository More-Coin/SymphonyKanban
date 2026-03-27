public struct SymphonyIssueBlockerReference: Equatable, Sendable {
    public let id: String?
    public let identifier: String?
    public let state: String?
    public let stateType: String?

    public init(
        id: String?,
        identifier: String?,
        state: String?,
        stateType: String? = nil
    ) {
        self.id = id
        self.identifier = identifier
        self.state = state
        self.stateType = stateType
    }
}
