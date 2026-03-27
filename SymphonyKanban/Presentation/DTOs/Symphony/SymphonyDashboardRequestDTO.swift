import Foundation

public struct SymphonyDashboardRequestDTO {
    public let selectedIssueIdentifier: String?

    public init(selectedIssueIdentifier: String? = nil) {
        self.selectedIssueIdentifier = Self.normalizedOptionalText(selectedIssueIdentifier)
    }

    public func requestContract() -> SymphonyDashboardRequestContract {
        SymphonyDashboardRequestContract(
            selectedIssueIdentifier: selectedIssueIdentifier
        )
    }

    private static func normalizedOptionalText(_ text: String?) -> String? {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

public struct SymphonyDashboardRequestContract: Equatable, Sendable {
    public let selectedIssueIdentifier: String?

    public init(selectedIssueIdentifier: String?) {
        self.selectedIssueIdentifier = selectedIssueIdentifier
    }
}
