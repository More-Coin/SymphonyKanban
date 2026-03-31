import Foundation

public protocol SymphonyRuntimeDashboardReadPortProtocol: Sendable {
    func readRuntimeDashboardSnapshot(generatedAt: Date) -> SymphonyRuntimeDashboardSnapshotContract
}
