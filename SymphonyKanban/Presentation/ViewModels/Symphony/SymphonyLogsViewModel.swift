public struct SymphonyLogsViewModel: Equatable, Sendable {
    public struct Entry: Identifiable, Equatable, Sendable {
        public let label: String
        public let subtitle: String
        public let destination: String?

        public var id: String {
            "\(label)|\(subtitle)"
        }

        public init(
            label: String,
            subtitle: String,
            destination: String?
        ) {
            self.label = label
            self.subtitle = subtitle
            self.destination = destination
        }
    }

    public let title: String
    public let subtitle: String
    public let emptyState: String
    public let entries: [Entry]

    public init(
        title: String,
        subtitle: String,
        emptyState: String,
        entries: [Entry]
    ) {
        self.title = title
        self.subtitle = subtitle
        self.emptyState = emptyState
        self.entries = entries
    }
}
