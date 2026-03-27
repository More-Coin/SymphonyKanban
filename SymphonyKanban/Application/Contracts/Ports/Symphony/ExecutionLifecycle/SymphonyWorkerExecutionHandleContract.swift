public struct SymphonyWorkerExecutionHandleContract: Equatable, Sendable {
    public let workerHandle: String
    public let monitorHandle: String

    public init(
        workerHandle: String,
        monitorHandle: String
    ) {
        self.workerHandle = workerHandle
        self.monitorHandle = monitorHandle
    }
}
