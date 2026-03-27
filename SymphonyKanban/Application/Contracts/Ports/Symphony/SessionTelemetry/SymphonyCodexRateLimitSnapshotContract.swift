public struct SymphonyCodexRateLimitSnapshotContract: Equatable, Sendable {
    public let payload: SymphonyConfigValueContract

    public init(payload: SymphonyConfigValueContract) {
        self.payload = payload
    }
}
