public enum SymphonyWorkerAttemptTerminalReasonContract: String, Equatable, Sendable {
    case succeeded = "Succeeded"
    case failed = "Failed"
    case timedOut = "TimedOut"
    case stalled = "Stalled"
    case canceledByReconciliation = "CanceledByReconciliation"
}
