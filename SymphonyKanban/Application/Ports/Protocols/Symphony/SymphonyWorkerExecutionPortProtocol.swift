public protocol SymphonyWorkerExecutionPortProtocol: Sendable {
    func start(
        request: SymphonyWorkerAttemptRequestContract,
        onProgress: @escaping @Sendable (SymphonyLiveSessionContract?) async -> Void,
        onComplete: @escaping @Sendable (SymphonyWorkerAttemptResultContract) async -> Void
    ) -> SymphonyWorkerExecutionHandleContract

    func cancel(workerHandle: String)
}
