public struct SymphonyTrackerScopeReferenceContract: Equatable, Sendable {
    public let scopeKind: String
    public let scopeIdentifier: String

    public init(
        scopeKind: String,
        scopeIdentifier: String
    ) {
        self.scopeKind = scopeKind
        self.scopeIdentifier = scopeIdentifier
    }
}
