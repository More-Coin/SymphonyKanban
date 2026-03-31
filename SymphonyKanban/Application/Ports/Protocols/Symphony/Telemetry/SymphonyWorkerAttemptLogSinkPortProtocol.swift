public protocol SymphonyWorkerAttemptLogSinkPortProtocol: Sendable {
    func emit(_ event: SymphonyWorkerAttemptLogEventContract)
}
