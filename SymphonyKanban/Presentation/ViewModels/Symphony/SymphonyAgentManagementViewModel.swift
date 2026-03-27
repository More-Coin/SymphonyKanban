public struct SymphonyAgentManagementViewModel: Equatable, Sendable {
    public let agents: [SymphonyAgentViewModel]

    public init(agents: [SymphonyAgentViewModel]) {
        self.agents = agents
    }
}

public struct SymphonyAgentViewModel: Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let type: String
    public let statusKey: String
    public let statusLabel: String
    public let capabilities: [String]
    public let currentTaskIdentifier: String?
    public let currentTaskTitle: String?
    public let completedCount: Int
    public let tokenUsage: String?
    public let lastActiveTime: String?

    public init(
        id: String,
        name: String,
        type: String,
        statusKey: String,
        statusLabel: String,
        capabilities: [String],
        currentTaskIdentifier: String?,
        currentTaskTitle: String?,
        completedCount: Int,
        tokenUsage: String?,
        lastActiveTime: String?
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.statusKey = statusKey
        self.statusLabel = statusLabel
        self.capabilities = capabilities
        self.currentTaskIdentifier = currentTaskIdentifier
        self.currentTaskTitle = currentTaskTitle
        self.completedCount = completedCount
        self.tokenUsage = tokenUsage
        self.lastActiveTime = lastActiveTime
    }
}
