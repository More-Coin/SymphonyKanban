import Foundation

public final class SymphonyRuntimeSchedulerGateway: SymphonyRuntimeSchedulerPortProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var tasks: [String: Task<Void, Never>] = [:]

    public init() {}

    public func schedule(
        after delayMs: Int,
        operation: @escaping @Sendable () async -> Void
    ) -> String {
        let handle = UUID().uuidString
        let task = Task { [weak self] in
            if delayMs > 0 {
                let sleepNs = UInt64(delayMs) * 1_000_000
                try? await Task.sleep(nanoseconds: sleepNs)
            }

            guard !Task.isCancelled else {
                self?.removeTask(handle: handle)
                return
            }

            await operation()
            self?.removeTask(handle: handle)
        }

        lock.lock()
        tasks[handle] = task
        lock.unlock()
        return handle
    }

    public func cancel(handle: String) {
        lock.lock()
        let task = tasks.removeValue(forKey: handle)
        lock.unlock()
        task?.cancel()
    }

    private func removeTask(handle: String) {
        lock.lock()
        tasks.removeValue(forKey: handle)
        lock.unlock()
    }
}
