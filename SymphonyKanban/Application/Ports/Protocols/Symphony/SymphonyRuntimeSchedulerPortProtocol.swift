public protocol SymphonyRuntimeSchedulerPortProtocol: Sendable {
    func schedule(
        after delayMs: Int,
        operation: @escaping @Sendable () async -> Void
    ) -> String

    func cancel(handle: String)
}
