import Foundation

public struct SymphonyRefreshTriggerViewModel: Equatable, Sendable {
    public let title: String
    public let subtitle: String
    public let sourceLabel: String
    public let statusLabel: String
    public let lastRefreshLabel: String?
    public let noteLabel: String?
    public let primaryActionTitle: String
    public let primaryActionAccessibilityLabel: String
    public let isRefreshing: Bool
    public let isPrimaryActionEnabled: Bool

    public init(
        title: String,
        subtitle: String,
        sourceLabel: String,
        statusLabel: String,
        lastRefreshLabel: String?,
        noteLabel: String?,
        primaryActionTitle: String,
        primaryActionAccessibilityLabel: String,
        isRefreshing: Bool,
        isPrimaryActionEnabled: Bool
    ) {
        self.title = title
        self.subtitle = subtitle
        self.sourceLabel = sourceLabel
        self.statusLabel = statusLabel
        self.lastRefreshLabel = lastRefreshLabel
        self.noteLabel = noteLabel
        self.primaryActionTitle = primaryActionTitle
        self.primaryActionAccessibilityLabel = primaryActionAccessibilityLabel
        self.isRefreshing = isRefreshing
        self.isPrimaryActionEnabled = isPrimaryActionEnabled
    }
}
