// MARK: - SymphonyActivityTimelineViewModel

public struct SymphonyActivityTimelineViewModel: Equatable, Sendable {
    public let entries: [SymphonyTimelineEntryViewModel]

    public init(entries: [SymphonyTimelineEntryViewModel]) {
        self.entries = entries
    }
}

// MARK: - SymphonyTimelineEntryViewModel

public struct SymphonyTimelineEntryViewModel: Equatable, Sendable, Identifiable {
    public let id: String
    public let timestamp: String
    public let issueIdentifier: String?
    public let eventType: String  // "tool_call", "build", "lint", "error", "retry", "completed"
    public let message: String
    public let detailLines: [String]
    public let agentName: String?
    public let statusKey: String  // maps to Status.color(for:)

    public init(
        id: String,
        timestamp: String,
        issueIdentifier: String?,
        eventType: String,
        message: String,
        detailLines: [String],
        agentName: String?,
        statusKey: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.issueIdentifier = issueIdentifier
        self.eventType = eventType
        self.message = message
        self.detailLines = detailLines
        self.agentName = agentName
        self.statusKey = statusKey
    }
}
