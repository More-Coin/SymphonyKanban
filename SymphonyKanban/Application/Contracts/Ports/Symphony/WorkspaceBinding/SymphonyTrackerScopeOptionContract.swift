public struct SymphonyTrackerScopeOptionContract: Equatable, Identifiable, Sendable {
    public let id: String
    public let scopeKind: String
    public let scopeIdentifier: String
    public let scopeName: String
    public let detailText: String?

    public init(
        id: String,
        scopeKind: String,
        scopeIdentifier: String,
        scopeName: String,
        detailText: String? = nil
    ) {
        self.id = id
        self.scopeKind = scopeKind
        self.scopeIdentifier = scopeIdentifier
        self.scopeName = scopeName
        self.detailText = detailText
    }
}
