public struct SymphonyTrackerScopeDiscoveryResultContract: Equatable, Sendable {
    public let options: [SymphonyTrackerScopeOptionContract]

    public init(
        options: [SymphonyTrackerScopeOptionContract]
    ) {
        self.options = options
    }
}
