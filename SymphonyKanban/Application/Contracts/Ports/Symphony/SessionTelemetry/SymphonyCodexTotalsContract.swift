public struct SymphonyCodexTotalsContract: Equatable, Sendable {
    public let inputTokens: Int
    public let outputTokens: Int
    public let totalTokens: Int
    public let secondsRunning: Double

    public init(
        inputTokens: Int,
        outputTokens: Int,
        totalTokens: Int,
        secondsRunning: Double
    ) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.totalTokens = totalTokens
        self.secondsRunning = secondsRunning
    }
}
