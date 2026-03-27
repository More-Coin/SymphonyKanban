public struct SymphonyStartupResultContract: Equatable, Sendable {
    public let resolvedWorkflowPath: String
    public let trackerAuthStatus: SymphonyTrackerAuthStatusContract

    public init(
        resolvedWorkflowPath: String,
        trackerAuthStatus: SymphonyTrackerAuthStatusContract
    ) {
        self.resolvedWorkflowPath = resolvedWorkflowPath
        self.trackerAuthStatus = trackerAuthStatus
    }
}
