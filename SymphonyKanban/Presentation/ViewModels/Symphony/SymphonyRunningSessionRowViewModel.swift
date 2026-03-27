public struct SymphonyRunningSessionRowViewModel: Identifiable, Equatable, Sendable {
    public let issueIdentifier: String
    public let statusLabel: String
    public let detailLabel: String
    public let timingLabel: String
    public let tokenLabel: String
    public let eventLabel: String?
    public let isSelected: Bool

    public var id: String {
        issueIdentifier
    }

    public init(
        issueIdentifier: String,
        statusLabel: String,
        detailLabel: String,
        timingLabel: String,
        tokenLabel: String,
        eventLabel: String?,
        isSelected: Bool
    ) {
        self.issueIdentifier = issueIdentifier
        self.statusLabel = statusLabel
        self.detailLabel = detailLabel
        self.timingLabel = timingLabel
        self.tokenLabel = tokenLabel
        self.eventLabel = eventLabel
        self.isSelected = isSelected
    }
}
