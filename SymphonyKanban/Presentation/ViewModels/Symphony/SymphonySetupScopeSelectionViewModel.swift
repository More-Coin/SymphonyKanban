public struct SymphonySetupScopeSelectionViewModel: Equatable {
    public enum State: Equatable {
        case loading
        case loaded
        case empty
        case failed
    }

    public struct Option: Equatable, Identifiable {
        public let id: String
        public let scopeKind: String
        public let scopeKindLabel: String
        public let scopeIdentifier: String
        public let scopeName: String
        public let detailText: String?

        public init(
            id: String,
            scopeKind: String,
            scopeKindLabel: String,
            scopeIdentifier: String,
            scopeName: String,
            detailText: String?
        ) {
            self.id = id
            self.scopeKind = scopeKind
            self.scopeKindLabel = scopeKindLabel
            self.scopeIdentifier = scopeIdentifier
            self.scopeName = scopeName
            self.detailText = detailText
        }
    }

    public let state: State
    public let title: String
    public let message: String
    public let options: [Option]
    public let errorMessage: String?

    public init(
        state: State,
        title: String,
        message: String,
        options: [Option] = [],
        errorMessage: String? = nil
    ) {
        self.state = state
        self.title = title
        self.message = message
        self.options = options
        self.errorMessage = errorMessage
    }
}
