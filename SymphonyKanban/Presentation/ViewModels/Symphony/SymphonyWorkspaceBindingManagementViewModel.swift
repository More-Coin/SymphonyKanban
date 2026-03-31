public struct SymphonyWorkspaceBindingManagementViewModel: Equatable {
    public struct Card: Equatable, Identifiable {
        public let id: String
        public let scopeName: String
        public let scopeKind: String
        public let scopeKindLabel: String
        public let scopeIdentifier: String
        public let trackerKind: String
        public let trackerKindLabel: String
        public let workspacePath: String
        public let workflowStatusLabel: String
        public let workflowStatusIsHealthy: Bool
        public let failureMessage: String?
        public let folderActionLabel: String
        public let isHealthy: Bool

        public init(
            id: String,
            scopeName: String,
            scopeKind: String,
            scopeKindLabel: String,
            scopeIdentifier: String,
            trackerKind: String,
            trackerKindLabel: String,
            workspacePath: String,
            workflowStatusLabel: String,
            workflowStatusIsHealthy: Bool,
            failureMessage: String?,
            folderActionLabel: String,
            isHealthy: Bool
        ) {
            self.id = id
            self.scopeName = scopeName
            self.scopeKind = scopeKind
            self.scopeKindLabel = scopeKindLabel
            self.scopeIdentifier = scopeIdentifier
            self.trackerKind = trackerKind
            self.trackerKindLabel = trackerKindLabel
            self.workspacePath = workspacePath
            self.workflowStatusLabel = workflowStatusLabel
            self.workflowStatusIsHealthy = workflowStatusIsHealthy
            self.failureMessage = failureMessage
            self.folderActionLabel = folderActionLabel
            self.isHealthy = isHealthy
        }
    }

    public let title: String
    public let subtitle: String
    public let bannerMessage: String?
    public let cards: [Card]

    public init(
        title: String,
        subtitle: String,
        bannerMessage: String? = nil,
        cards: [Card] = []
    ) {
        self.title = title
        self.subtitle = subtitle
        self.bannerMessage = bannerMessage
        self.cards = cards
    }
}
