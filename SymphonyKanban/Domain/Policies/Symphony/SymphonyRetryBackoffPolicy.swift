public struct SymphonyRetryBackoffPolicy: SymphonyRetryBackoffPolicyProtocol {
    public init() {}

    public func continuationDelayMs() -> Int {
        1_000
    }

    public func failureDelayMs(
        forAttempt attempt: Int,
        maxRetryBackoffMs: Int
    ) -> Int {
        let cappedMaximumDelay = max(maxRetryBackoffMs, 0)
        guard cappedMaximumDelay > 0 else {
            return 0
        }

        let normalizedAttempt = max(attempt, 1)
        var delay = 10_000

        guard normalizedAttempt > 1 else {
            return min(delay, cappedMaximumDelay)
        }

        for _ in 2...normalizedAttempt {
            if delay >= cappedMaximumDelay || delay > (Int.max / 2) {
                return cappedMaximumDelay
            }

            delay *= 2
        }

        return min(delay, cappedMaximumDelay)
    }
}
