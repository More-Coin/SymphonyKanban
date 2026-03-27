import Foundation

// MARK: - SymphonyKanbanBoardViewModel

public struct SymphonyKanbanBoardViewModel: Equatable, Sendable {
    public let columns: [SymphonyKanbanColumnViewModel]

    public init(columns: [SymphonyKanbanColumnViewModel]) {
        self.columns = columns
    }
}

// MARK: - SymphonyKanbanColumnViewModel

public struct SymphonyKanbanColumnViewModel: Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let statusKey: String
    public let cards: [SymphonyKanbanCardViewModel]

    public var count: Int { cards.count }

    public init(
        id: String,
        title: String,
        statusKey: String,
        cards: [SymphonyKanbanCardViewModel]
    ) {
        self.id = id
        self.title = title
        self.statusKey = statusKey
        self.cards = cards
    }
}

// MARK: - SymphonyKanbanCardViewModel

public struct SymphonyKanbanCardViewModel: Equatable, Sendable, Identifiable {
    public let id: String
    public let identifier: String
    public let title: String
    public let priorityLevel: Int
    public let statusKey: String
    public let agentName: String?
    public let labels: [String]
    public let tokenCount: String?
    public let lastEvent: String?
    public let lastEventTime: String?
    public let isRunning: Bool

    public init(
        id: String,
        identifier: String,
        title: String,
        priorityLevel: Int,
        statusKey: String,
        agentName: String? = nil,
        labels: [String] = [],
        tokenCount: String? = nil,
        lastEvent: String? = nil,
        lastEventTime: String? = nil,
        isRunning: Bool = false
    ) {
        self.id = id
        self.identifier = identifier
        self.title = title
        self.priorityLevel = priorityLevel
        self.statusKey = statusKey
        self.agentName = agentName
        self.labels = labels
        self.tokenCount = tokenCount
        self.lastEvent = lastEvent
        self.lastEventTime = lastEventTime
        self.isRunning = isRunning
    }
}
