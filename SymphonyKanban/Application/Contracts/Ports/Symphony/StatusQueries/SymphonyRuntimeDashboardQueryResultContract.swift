public struct SymphonyRuntimeDashboardQueryResultContract: Equatable, Sendable {
    public let snapshot: SymphonyRuntimeDashboardSnapshotContract
    public let hasRunningSessions: Bool
    public let hasRetryQueue: Bool
    public let hasTrackedFields: Bool
    public let isEmpty: Bool

    public init(
        snapshot: SymphonyRuntimeDashboardSnapshotContract,
        hasRunningSessions: Bool,
        hasRetryQueue: Bool,
        hasTrackedFields: Bool,
        isEmpty: Bool
    ) {
        self.snapshot = snapshot
        self.hasRunningSessions = hasRunningSessions
        self.hasRetryQueue = hasRetryQueue
        self.hasTrackedFields = hasTrackedFields
        self.isEmpty = isEmpty
    }
}
