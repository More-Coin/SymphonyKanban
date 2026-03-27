public struct SymphonyRuntimeSummaryViewModel: Equatable, Sendable {
    public let title: String
    public let statusLabel: String
    public let generatedAtLabel: String
    public let runningCountLabel: String
    public let retryCountLabel: String
    public let claimedCountLabel: String
    public let completedCountLabel: String
    public let totalTokensLabel: String
    public let runtimeDurationLabel: String
    public let rateLimitLabel: String?

    public init(
        title: String,
        statusLabel: String,
        generatedAtLabel: String,
        runningCountLabel: String,
        retryCountLabel: String,
        claimedCountLabel: String,
        completedCountLabel: String,
        totalTokensLabel: String,
        runtimeDurationLabel: String,
        rateLimitLabel: String?
    ) {
        self.title = title
        self.statusLabel = statusLabel
        self.generatedAtLabel = generatedAtLabel
        self.runningCountLabel = runningCountLabel
        self.retryCountLabel = retryCountLabel
        self.claimedCountLabel = claimedCountLabel
        self.completedCountLabel = completedCountLabel
        self.totalTokensLabel = totalTokensLabel
        self.runtimeDurationLabel = runtimeDurationLabel
        self.rateLimitLabel = rateLimitLabel
    }
}
