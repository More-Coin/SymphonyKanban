import Foundation

public struct SymphonyIssueDetailRequestDTO {
    public let issueIdentifier: String?

    public init(issueIdentifier: String? = nil) {
        self.issueIdentifier = Self.normalizedOptionalText(issueIdentifier)
    }

    public func queryParams() -> SymphonyIssueDetailQueryParams {
        SymphonyIssueDetailQueryParams(issueIdentifier: issueIdentifier)
    }

    private static func normalizedOptionalText(_ text: String?) -> String? {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

public struct SymphonyIssueDetailQueryParams: Equatable, Sendable {
    public let issueIdentifier: String?

    public init(issueIdentifier: String?) {
        self.issueIdentifier = issueIdentifier
    }
}
