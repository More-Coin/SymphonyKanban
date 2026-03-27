import Foundation

public struct SymphonyAuthPresenter {
    private let relativeDateFormatter: RelativeDateTimeFormatter

    public init(relativeDateFormatter: RelativeDateTimeFormatter = RelativeDateTimeFormatter()) {
        self.relativeDateFormatter = relativeDateFormatter
        self.relativeDateFormatter.unitsStyle = .full
    }

    public func present(
        _ status: SymphonyTrackerAuthStatusContract,
        errorMessage: String? = nil
    ) -> SymphonyAuthViewModel {
        SymphonyAuthViewModel(
            title: "Linear Connection",
            subtitle: "Authorize Linear in your browser and let Symphony manage the session-backed GraphQL connection.",
            bannerMessage: errorMessage,
            services: [
                SymphonyAuthServiceViewModel(
                    id: status.trackerKind,
                    name: "Linear",
                    icon: "rectangle.3.group",
                    description: "Connect Linear to sync issues, refresh state changes, and keep Symphony's tracker reads on OAuth-backed bearer auth.",
                    state: status.state,
                    statusLabel: statusLabel(for: status.state),
                    statusMessage: status.statusMessage,
                    actionLabel: actionLabel(for: status.state),
                    connectedAtLabel: connectedAtLabel(for: status.connectedAt),
                    expiresAtLabel: expiresAtLabel(for: status.expiresAt, state: status.state),
                    accountLabel: status.accountLabel,
                    isActionEnabled: status.state != .connecting
                )
            ]
        )
    }

    private func statusLabel(
        for state: SymphonyTrackerAuthStateContract
    ) -> String {
        switch state {
        case .disconnected:
            return "Not Connected"
        case .connecting:
            return "Awaiting Callback"
        case .connected:
            return "Connected"
        case .staleSession:
            return "Reconnect Required"
        }
    }

    private func actionLabel(
        for state: SymphonyTrackerAuthStateContract
    ) -> String {
        switch state {
        case .disconnected:
            return "Connect"
        case .connecting:
            return "Awaiting Callback"
        case .connected:
            return "Disconnect"
        case .staleSession:
            return "Reconnect"
        }
    }

    private func connectedAtLabel(
        for date: Date?
    ) -> String? {
        guard let date else {
            return nil
        }

        return "Connected \(relativeDateFormatter.localizedString(for: date, relativeTo: Date()))"
    }

    private func expiresAtLabel(
        for date: Date?,
        state: SymphonyTrackerAuthStateContract
    ) -> String? {
        guard let date else {
            return nil
        }

        let prefix = state == .staleSession ? "Expired" : "Expires"
        return "\(prefix) \(relativeDateFormatter.localizedString(for: date, relativeTo: Date()))"
    }
}
