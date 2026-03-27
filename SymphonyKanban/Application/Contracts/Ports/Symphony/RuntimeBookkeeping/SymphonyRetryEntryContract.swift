public struct SymphonyRetryEntryContract<TimerHandle: Equatable & Sendable>: Equatable, Sendable {
    public let issueID: String
    public let identifier: String
    public let attempt: Int
    public let dueAtMs: Int64
    public let timerHandle: TimerHandle
    public let error: String?

    public init(
        issueID: String,
        identifier: String,
        attempt: Int,
        dueAtMs: Int64,
        timerHandle: TimerHandle,
        error: String?
    ) {
        self.issueID = issueID
        self.identifier = identifier
        self.attempt = attempt
        self.dueAtMs = dueAtMs
        self.timerHandle = timerHandle
        self.error = error
    }
}
