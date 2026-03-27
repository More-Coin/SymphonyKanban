public struct SymphonyAuthViewModel: Equatable, Sendable {
    public let services: [SymphonyAuthServiceViewModel]

    public init(services: [SymphonyAuthServiceViewModel]) {
        self.services = services
    }
}

public struct SymphonyAuthServiceViewModel: Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let icon: String
    public let description: String
    public let isConnected: Bool
    public let statusLabel: String
    public let lastSyncTime: String?

    public init(
        id: String,
        name: String,
        icon: String,
        description: String,
        isConnected: Bool,
        statusLabel: String,
        lastSyncTime: String?
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.isConnected = isConnected
        self.statusLabel = statusLabel
        self.lastSyncTime = lastSyncTime
    }
}
