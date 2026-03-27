public struct SymphonyRecentEventRowViewModel: Identifiable, Equatable, Sendable {
    public let title: String
    public let subtitle: String
    public let detailLines: [String]

    public var id: String {
        "\(title)|\(subtitle)"
    }

    public init(
        title: String,
        subtitle: String,
        detailLines: [String]
    ) {
        self.title = title
        self.subtitle = subtitle
        self.detailLines = detailLines
    }
}
