public struct SymphonyIssueListViewModel: Equatable, Sendable {
    public let sections: [SymphonyIssueListSectionViewModel]

    public var rows: [SymphonyIssueListRowViewModel] {
        sections.flatMap(\.rows)
    }

    public init(rows: [SymphonyIssueListRowViewModel]) {
        self.sections = [
            SymphonyIssueListSectionViewModel(
                id: "default",
                title: nil,
                subtitle: nil,
                errorMessage: nil,
                rows: rows
            )
        ]
    }

    public init(sections: [SymphonyIssueListSectionViewModel]) {
        self.sections = sections
    }
}

public struct SymphonyIssueListSectionViewModel: Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String?
    public let subtitle: String?
    public let errorMessage: String?
    public let rows: [SymphonyIssueListRowViewModel]

    public init(
        id: String,
        title: String?,
        subtitle: String?,
        errorMessage: String?,
        rows: [SymphonyIssueListRowViewModel]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.errorMessage = errorMessage
        self.rows = rows
    }
}

public struct SymphonyIssueListRowViewModel: Equatable, Sendable, Identifiable {
    public let id: String
    public let identifier: String
    public let title: String
    public let scopeName: String?
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
        scopeName: String? = nil,
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
        self.scopeName = scopeName
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
