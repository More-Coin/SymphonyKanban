import Dispatch
import Foundation
import Darwin

public final class SymphonyWorkflowReloadMonitorGateway:
    SymphonyWorkflowReloadMonitorPortProtocol,
    @unchecked Sendable {
    private final class WatchState {
        let source: DispatchSourceFileSystemObject
        let fileDescriptor: Int32
        let targetPath: String
        var snapshot: FileSnapshot

        init(
            source: DispatchSourceFileSystemObject,
            fileDescriptor: Int32,
            targetPath: String,
            snapshot: FileSnapshot
        ) {
            self.source = source
            self.fileDescriptor = fileDescriptor
            self.targetPath = targetPath
            self.snapshot = snapshot
        }
    }

    private struct FileSnapshot: Equatable {
        let exists: Bool
        let fileNumber: NSNumber?
        let modificationDate: Date?
        let size: NSNumber?
    }

    private let queue: DispatchQueue
    private let lock = NSLock()
    private var watches: [String: WatchState] = [:]

    public init(
        queue: DispatchQueue = DispatchQueue(label: "symphony.workflow.reload.monitor")
    ) {
        self.queue = queue
    }

    public func startMonitoring(
        path: String,
        onChange: @escaping @Sendable () async -> Void
    ) throws -> SymphonyWorkflowReloadHandleContract {
        let normalizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        let directoryPath = URL(fileURLWithPath: normalizedPath)
            .deletingLastPathComponent()
            .standardizedFileURL
            .path
        let fileDescriptor = open(directoryPath, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            throw SymphonyWorkflowInfrastructureError.missingWorkflowFile(path: directoryPath)
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename, .extend, .attrib],
            queue: queue
        )
        let handle = SymphonyWorkflowReloadHandleContract(value: UUID().uuidString)
        let state = WatchState(
            source: source,
            fileDescriptor: fileDescriptor,
            targetPath: normalizedPath,
            snapshot: makeSnapshot(for: normalizedPath)
        )

        source.setEventHandler {
            let nextSnapshot = self.makeSnapshot(for: state.targetPath)
            guard nextSnapshot != state.snapshot else {
                return
            }

            state.snapshot = nextSnapshot
            Task {
                await onChange()
            }
        }
        source.setCancelHandler {
            close(fileDescriptor)
        }

        lock.lock()
        watches[handle.value] = state
        lock.unlock()

        source.resume()
        return handle
    }

    public func cancel(handle: SymphonyWorkflowReloadHandleContract) {
        lock.lock()
        let state = watches.removeValue(forKey: handle.value)
        lock.unlock()
        state?.source.cancel()
    }

    deinit {
        lock.lock()
        let states = Array(watches.values)
        watches.removeAll()
        lock.unlock()

        for state in states {
            state.source.cancel()
        }
    }

    private func makeSnapshot(for path: String) -> FileSnapshot {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return FileSnapshot(
                exists: true,
                fileNumber: attributes[.systemFileNumber] as? NSNumber,
                modificationDate: attributes[.modificationDate] as? Date,
                size: attributes[.size] as? NSNumber
            )
        } catch {
            return FileSnapshot(
                exists: false,
                fileNumber: nil,
                modificationDate: nil,
                size: nil
            )
        }
    }
}
