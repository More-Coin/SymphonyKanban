public protocol SymphonyRuntimeStatusSinkPortProtocol: Sendable {
    func emit(_ snapshot: SymphonyRuntimeStatusSnapshotContract)
}
