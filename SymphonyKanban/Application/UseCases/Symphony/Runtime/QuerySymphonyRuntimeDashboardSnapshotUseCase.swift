import Foundation

public struct QuerySymphonyRuntimeDashboardSnapshotUseCase {
    private let clockPort: any SymphonyRuntimeClockPortProtocol
    private let runtimeDashboardReadPort: any SymphonyRuntimeDashboardReadPortProtocol

    public init(
        clockPort: any SymphonyRuntimeClockPortProtocol,
        runtimeDashboardReadPort: any SymphonyRuntimeDashboardReadPortProtocol
    ) {
        self.clockPort = clockPort
        self.runtimeDashboardReadPort = runtimeDashboardReadPort
    }

    public func query() -> SymphonyRuntimeDashboardSnapshotContract {
        runtimeDashboardReadPort.readRuntimeDashboardSnapshot(
            generatedAt: clockPort.now()
        )
    }
}
