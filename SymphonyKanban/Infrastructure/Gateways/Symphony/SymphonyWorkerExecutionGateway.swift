import Foundation

public final class SymphonyWorkerExecutionGateway: SymphonyWorkerExecutionPortProtocol, @unchecked Sendable {
    public typealias ServiceFactory = @Sendable () -> SymphonyWorkerAttemptService

    private let makeService: ServiceFactory
    private let lock = NSLock()
    private var activeServices: [String: SymphonyWorkerAttemptService] = [:]

    public init(makeService: @escaping ServiceFactory) {
        self.makeService = makeService
    }

    public func start(
        request: SymphonyWorkerAttemptRequestContract,
        onProgress: @escaping @Sendable (SymphonyLiveSessionContract?) async -> Void,
        onComplete: @escaping @Sendable (SymphonyWorkerAttemptResultContract) async -> Void
    ) -> SymphonyWorkerExecutionHandleContract {
        let handle = UUID().uuidString
        let service = makeService()

        lock.lock()
        activeServices[handle] = service
        lock.unlock()

        Task { [weak self] in
            let result = await service.execute(request, onProgress: onProgress)
            await onComplete(result)
            self?.removeService(handle: handle)
        }

        return SymphonyWorkerExecutionHandleContract(
            workerHandle: handle,
            monitorHandle: handle
        )
    }

    public func cancel(workerHandle: String) {
        lock.lock()
        let service = activeServices[workerHandle]
        lock.unlock()
        service?.cancelActiveAttempt()
    }

    private func removeService(handle: String) {
        lock.lock()
        activeServices.removeValue(forKey: handle)
        lock.unlock()
    }
}
