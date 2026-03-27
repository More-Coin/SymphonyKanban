public struct SymphonyIssueDetailViewModel: Equatable, Sendable {
    public let issueIdentifier: String
    public let title: String
    public let subtitle: String
    public let stateLabel: String
    public let priorityLabel: String?
    public let labels: [String]
    public let descriptionText: String?
    public let metadataLines: [String]
    public let attemptsLabel: String
    public let generatedAtLabel: String
    public let runtimeViewModel: SymphonyIssueRuntimeViewModel?
    public let workspaceViewModel: SymphonyWorkspaceViewModel?
    public let logsViewModel: SymphonyLogsViewModel
    public let recentEventsSectionTitle: String
    public let recentEventsEmptyState: String
    public let recentEventRows: [SymphonyRecentEventRowViewModel]
    public let lastErrorTitle: String?
    public let lastErrorMessage: String?
    public let lastErrorDetailLines: [String]
    public let trackedSectionTitle: String
    public let trackedFieldLines: [String]
    public let emptyStateTitle: String?
    public let emptyStateMessage: String?

    public var isEmptyState: Bool {
        emptyStateTitle != nil
    }

    public init(
        issueIdentifier: String,
        title: String,
        subtitle: String,
        stateLabel: String,
        priorityLabel: String?,
        labels: [String],
        descriptionText: String?,
        metadataLines: [String],
        attemptsLabel: String,
        generatedAtLabel: String,
        runtimeViewModel: SymphonyIssueRuntimeViewModel?,
        workspaceViewModel: SymphonyWorkspaceViewModel?,
        logsViewModel: SymphonyLogsViewModel,
        recentEventsSectionTitle: String,
        recentEventsEmptyState: String,
        recentEventRows: [SymphonyRecentEventRowViewModel],
        lastErrorTitle: String?,
        lastErrorMessage: String?,
        lastErrorDetailLines: [String],
        trackedSectionTitle: String,
        trackedFieldLines: [String],
        emptyStateTitle: String?,
        emptyStateMessage: String?
    ) {
        self.issueIdentifier = issueIdentifier
        self.title = title
        self.subtitle = subtitle
        self.stateLabel = stateLabel
        self.priorityLabel = priorityLabel
        self.labels = labels
        self.descriptionText = descriptionText
        self.metadataLines = metadataLines
        self.attemptsLabel = attemptsLabel
        self.generatedAtLabel = generatedAtLabel
        self.runtimeViewModel = runtimeViewModel
        self.workspaceViewModel = workspaceViewModel
        self.logsViewModel = logsViewModel
        self.recentEventsSectionTitle = recentEventsSectionTitle
        self.recentEventsEmptyState = recentEventsEmptyState
        self.recentEventRows = recentEventRows
        self.lastErrorTitle = lastErrorTitle
        self.lastErrorMessage = lastErrorMessage
        self.lastErrorDetailLines = lastErrorDetailLines
        self.trackedSectionTitle = trackedSectionTitle
        self.trackedFieldLines = trackedFieldLines
        self.emptyStateTitle = emptyStateTitle
        self.emptyStateMessage = emptyStateMessage
    }
}
