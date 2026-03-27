public struct SymphonyRuntimeStopRequestContract: Equatable, Sendable {
    public let pollHandle: String?
    public let workflowReloadHandle: SymphonyWorkflowReloadHandleContract?
    public let retryTimerHandles: [String]
    public let workerHandles: [String]

    public init(
        pollHandle: String?,
        workflowReloadHandle: SymphonyWorkflowReloadHandleContract?,
        retryTimerHandles: [String],
        workerHandles: [String]
    ) {
        self.pollHandle = pollHandle
        self.workflowReloadHandle = workflowReloadHandle
        self.retryTimerHandles = retryTimerHandles
        self.workerHandles = workerHandles
    }
}
