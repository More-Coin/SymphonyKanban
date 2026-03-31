public protocol SymphonyWorkflowReloadMonitorPortProtocol: Sendable {
    func startMonitoring(
        path: String,
        onChange: @escaping @Sendable () async -> Void
    ) throws -> SymphonyWorkflowReloadHandleContract

    func cancel(handle: SymphonyWorkflowReloadHandleContract)
}
