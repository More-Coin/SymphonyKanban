import Foundation

public struct ProjectSymphonyRuntimeStatusSnapshotUseCase {
    private let clockPort: any SymphonyRuntimeClockPortProtocol
    private let runtimeStatusProjectorPort: any SymphonyRuntimeStatusProjectorPortProtocol

    public init(
        clockPort: any SymphonyRuntimeClockPortProtocol,
        runtimeStatusProjectorPort: any SymphonyRuntimeStatusProjectorPortProtocol
    ) {
        self.clockPort = clockPort
        self.runtimeStatusProjectorPort = runtimeStatusProjectorPort
    }

    public func projectStatusSnapshot<
        WorkerHandle: Equatable & Sendable,
        MonitorHandle: Equatable & Sendable,
        TimerHandle: Equatable & Sendable
    >(
        from state: SymphonyRuntimeStateContract<WorkerHandle, MonitorHandle, TimerHandle>,
        outcome: String
    ) -> SymphonyRuntimeStatusSnapshotContract {
        runtimeStatusProjectorPort.projectStatusSnapshot(
            from: state,
            outcome: outcome,
            generatedAt: clockPort.now()
        )
    }
}
