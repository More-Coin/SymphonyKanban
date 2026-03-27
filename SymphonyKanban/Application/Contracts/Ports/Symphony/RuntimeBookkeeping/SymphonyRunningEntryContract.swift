import Foundation

public struct SymphonyRunningEntryContract<
    WorkerHandle: Equatable & Sendable,
    MonitorHandle: Equatable & Sendable
>: Equatable, Sendable {
    public let workerHandle: WorkerHandle
    public let monitorHandle: MonitorHandle
    public let identifier: String
    public let issue: SymphonyIssue
    public let liveSession: SymphonyLiveSessionContract?
    public let retryAttempt: Int?
    public let startedAt: Date

    public init(
        workerHandle: WorkerHandle,
        monitorHandle: MonitorHandle,
        identifier: String,
        issue: SymphonyIssue,
        liveSession: SymphonyLiveSessionContract?,
        retryAttempt: Int?,
        startedAt: Date
    ) {
        self.workerHandle = workerHandle
        self.monitorHandle = monitorHandle
        self.identifier = identifier
        self.issue = issue
        self.liveSession = liveSession
        self.retryAttempt = retryAttempt
        self.startedAt = startedAt
    }
}
