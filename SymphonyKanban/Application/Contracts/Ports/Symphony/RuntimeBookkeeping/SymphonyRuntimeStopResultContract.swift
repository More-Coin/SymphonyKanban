public struct SymphonyRuntimeStopResultContract: Equatable, Sendable {
    public let cancelledPoll: Bool
    public let cancelledWorkflowReloadMonitor: Bool
    public let cancelledRetryCount: Int
    public let cancelledWorkerCount: Int

    public init(
        cancelledPoll: Bool,
        cancelledWorkflowReloadMonitor: Bool,
        cancelledRetryCount: Int,
        cancelledWorkerCount: Int
    ) {
        self.cancelledPoll = cancelledPoll
        self.cancelledWorkflowReloadMonitor = cancelledWorkflowReloadMonitor
        self.cancelledRetryCount = cancelledRetryCount
        self.cancelledWorkerCount = cancelledWorkerCount
    }
}
