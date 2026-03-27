import Foundation

public struct SymphonyRefreshRequestDTO {
    public let requestedAt: Date
    public let source: String
    public let lastRefreshedAt: Date?
    public let isRefreshing: Bool
    public let note: String?

    public init(
        requestedAt: Date = .now,
        source: String? = nil,
        lastRefreshedAt: Date? = nil,
        isRefreshing: Bool = false,
        note: String? = nil
    ) {
        self.requestedAt = requestedAt
        self.source = Self.normalizedSource(source)
        self.lastRefreshedAt = lastRefreshedAt
        self.isRefreshing = isRefreshing
        self.note = Self.normalizedOptionalText(note)
    }

    public func requestContract() -> SymphonyRefreshRequestContract {
        SymphonyRefreshRequestContract(
            requestedAt: requestedAt,
            source: source,
            lastRefreshedAt: lastRefreshedAt,
            isRefreshing: isRefreshing,
            note: note
        )
    }

    private static func normalizedSource(_ source: String?) -> String {
        let trimmed = source?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "manual" : trimmed
    }

    private static func normalizedOptionalText(_ text: String?) -> String? {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

public struct SymphonyRefreshRequestContract: Equatable, Sendable {
    public let requestedAt: Date
    public let source: String
    public let lastRefreshedAt: Date?
    public let isRefreshing: Bool
    public let note: String?

    public init(
        requestedAt: Date,
        source: String,
        lastRefreshedAt: Date?,
        isRefreshing: Bool,
        note: String?
    ) {
        self.requestedAt = requestedAt
        self.source = source
        self.lastRefreshedAt = lastRefreshedAt
        self.isRefreshing = isRefreshing
        self.note = note
    }
}
