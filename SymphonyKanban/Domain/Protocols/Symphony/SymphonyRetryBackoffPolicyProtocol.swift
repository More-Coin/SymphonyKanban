public protocol SymphonyRetryBackoffPolicyProtocol {
    func continuationDelayMs() -> Int

    func failureDelayMs(
        forAttempt attempt: Int,
        maxRetryBackoffMs: Int
    ) -> Int
}
