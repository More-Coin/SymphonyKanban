import Foundation

public struct SymphonyRefreshPresenter {
    private let relativeDateFormatter: RelativeDateTimeFormatter

    public init(relativeDateFormatter: RelativeDateTimeFormatter = RelativeDateTimeFormatter()) {
        self.relativeDateFormatter = relativeDateFormatter
        self.relativeDateFormatter.unitsStyle = .full
    }

    public func present(_ request: SymphonyRefreshRequestContract) -> SymphonyRefreshTriggerViewModel {
        let isRefreshing = request.isRefreshing
        let sourceLabel = displaySourceLabel(from: request.source)
        let subtitle = isRefreshing
            ? "Refreshing Symphony runtime data."
            : "Refresh the Symphony runtime data before reviewing the next change."
        let primaryActionTitle = isRefreshing ? "Refreshing..." : "Refresh now"
        let primaryActionAccessibilityLabel = isRefreshing
            ? "Refresh Symphony runtime data in progress"
            : "Refresh Symphony runtime data"
        let statusLabel = isRefreshing ? "Refreshing" : "Ready"
        let lastRefreshLabel = request.lastRefreshedAt.map {
            "Last refreshed \(relativeDateFormatter.localizedString(for: $0, relativeTo: request.requestedAt))"
        }

        return SymphonyRefreshTriggerViewModel(
            title: "Symphony Refresh",
            subtitle: subtitle,
            sourceLabel: sourceLabel,
            statusLabel: statusLabel,
            lastRefreshLabel: lastRefreshLabel,
            noteLabel: request.note.map { "Note: \($0)" },
            primaryActionTitle: primaryActionTitle,
            primaryActionAccessibilityLabel: primaryActionAccessibilityLabel,
            isRefreshing: isRefreshing,
            isPrimaryActionEnabled: !isRefreshing
        )
    }

    private func displaySourceLabel(from source: String) -> String {
        let normalized = source.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? "Triggered manually" : "Triggered from \(normalized)"
    }
}
