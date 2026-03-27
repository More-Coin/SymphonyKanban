public struct SymphonyAuthViewModel: Equatable, Sendable {
    public let title: String
    public let subtitle: String
    public let bannerMessage: String?
    public let services: [SymphonyAuthServiceViewModel]

    public init(
        title: String,
        subtitle: String,
        bannerMessage: String? = nil,
        services: [SymphonyAuthServiceViewModel]
    ) {
        self.title = title
        self.subtitle = subtitle
        self.bannerMessage = bannerMessage
        self.services = services
    }

    public var linearService: SymphonyAuthServiceViewModel? {
        services.first { $0.id == "linear" }
    }
}

public struct SymphonyAuthServiceViewModel: Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let icon: String
    public let description: String
    public let state: SymphonyTrackerAuthStateContract
    public let statusLabel: String
    public let statusMessage: String
    public let actionLabel: String
    public let connectedAtLabel: String?
    public let expiresAtLabel: String?
    public let accountLabel: String?
    public let isActionEnabled: Bool

    public init(
        id: String,
        name: String,
        icon: String,
        description: String,
        state: SymphonyTrackerAuthStateContract,
        statusLabel: String,
        statusMessage: String,
        actionLabel: String,
        connectedAtLabel: String?,
        expiresAtLabel: String?,
        accountLabel: String?,
        isActionEnabled: Bool
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.state = state
        self.statusLabel = statusLabel
        self.statusMessage = statusMessage
        self.actionLabel = actionLabel
        self.connectedAtLabel = connectedAtLabel
        self.expiresAtLabel = expiresAtLabel
        self.accountLabel = accountLabel
        self.isActionEnabled = isActionEnabled
    }

    public var isConnected: Bool {
        state == .connected
    }

    public var requiresAttention: Bool {
        state == .staleSession
    }
}
