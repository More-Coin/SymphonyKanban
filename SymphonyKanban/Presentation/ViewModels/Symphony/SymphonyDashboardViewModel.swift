public struct SymphonyDashboardViewModel: Equatable, Sendable {
    public let title: String
    public let subtitle: String
    public let runtimeSummary: SymphonyRuntimeSummaryViewModel
    public let runningSectionTitle: String
    public let runningEmptyState: String
    public let runningSessions: [SymphonyRunningSessionRowViewModel]
    public let retrySectionTitle: String
    public let retryEmptyState: String
    public let retryQueue: [SymphonyRetryRowViewModel]
    public let trackedSectionTitle: String
    public let trackedFieldLines: [String]

    public init(
        title: String,
        subtitle: String,
        runtimeSummary: SymphonyRuntimeSummaryViewModel,
        runningSectionTitle: String,
        runningEmptyState: String,
        runningSessions: [SymphonyRunningSessionRowViewModel],
        retrySectionTitle: String,
        retryEmptyState: String,
        retryQueue: [SymphonyRetryRowViewModel],
        trackedSectionTitle: String,
        trackedFieldLines: [String]
    ) {
        self.title = title
        self.subtitle = subtitle
        self.runtimeSummary = runtimeSummary
        self.runningSectionTitle = runningSectionTitle
        self.runningEmptyState = runningEmptyState
        self.runningSessions = runningSessions
        self.retrySectionTitle = retrySectionTitle
        self.retryEmptyState = retryEmptyState
        self.retryQueue = retryQueue
        self.trackedSectionTitle = trackedSectionTitle
        self.trackedFieldLines = trackedFieldLines
    }
}
