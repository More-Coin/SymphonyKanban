import Foundation

// MARK: - SymphonyNavigationViewModel

public struct SymphonyNavigationViewModel: Equatable, Sendable {
    public let tabs: [SymphonyTabViewModel]
    public let integrations: [SymphonyIntegrationStateViewModel]

    public init(
        tabs: [SymphonyTabViewModel] = SymphonyTabViewModel.allCases,
        integrations: [SymphonyIntegrationStateViewModel] = []
    ) {
        self.tabs = tabs
        self.integrations = integrations
    }
}

// MARK: - Navigation Tab Model

public enum SymphonyTabViewModel: String, CaseIterable, Identifiable, Sendable {
    case board = "Board"
    case list = "Issues"
    case timeline = "Activity"
    case agents = "Agents"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .board: return "rectangle.split.3x1"
        case .list: return "list.bullet.rectangle"
        case .timeline: return "chart.line.text.clipboard"
        case .agents: return "cpu"
        }
    }
}

// MARK: - Integration State

public struct SymphonyIntegrationStateViewModel: Equatable, Sendable {
    public let service: String
    public let icon: String
    public let isConnected: Bool

    public init(service: String, icon: String, isConnected: Bool) {
        self.service = service
        self.icon = icon
        self.isConnected = isConnected
    }
}
