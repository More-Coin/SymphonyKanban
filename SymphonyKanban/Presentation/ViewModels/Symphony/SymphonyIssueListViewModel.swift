public struct SymphonyIssueListViewModel: Equatable, Sendable {
    public let rows: [SymphonyIssueListRowViewModel]

    public init(rows: [SymphonyIssueListRowViewModel]) {
        self.rows = rows
    }
}

public struct SymphonyIssueListRowViewModel: Equatable, Sendable, Identifiable {
    public let id: String
    public let identifier: String
    public let title: String
    public let statusKey: String
    public let statusLabel: String
    public let priorityLevel: Int
    public let agentName: String?
    public let labels: [String]
    public let lastEvent: String?
    public let lastEventTime: String?
    public let tokenCount: String?
    public let isSelected: Bool

    public init(
        id: String,
        identifier: String,
        title: String,
        statusKey: String,
        statusLabel: String,
        priorityLevel: Int,
        agentName: String?,
        labels: [String],
        lastEvent: String?,
        lastEventTime: String?,
        tokenCount: String?,
        isSelected: Bool
    ) {
        self.id = id
        self.identifier = identifier
        self.title = title
        self.statusKey = statusKey
        self.statusLabel = statusLabel
        self.priorityLevel = priorityLevel
        self.agentName = agentName
        self.labels = labels
        self.lastEvent = lastEvent
        self.lastEventTime = lastEventTime
        self.tokenCount = tokenCount
        self.isSelected = isSelected
    }
}
