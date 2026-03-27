import Foundation

public protocol SymphonyRuntimeStatusProjectorPortProtocol: Sendable {
    func projectStatusSnapshot<
        WorkerHandle: Equatable & Sendable,
        MonitorHandle: Equatable & Sendable,
        TimerHandle: Equatable & Sendable
    >(
        from state: SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle>,
        outcome: String,
        generatedAt: Date
    ) -> SymphonyRuntimeStatusSnapshotContract
}
