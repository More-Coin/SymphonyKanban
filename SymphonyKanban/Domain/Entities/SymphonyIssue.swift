import Foundation

public struct SymphonyIssue: Equatable, Sendable {
    public let id: String
    public let identifier: String
    public let title: String
    public let description: String?
    public let priority: Int?
    public let state: String
    public let stateType: String
    public let branchName: String?
    public let url: String?
    public let labels: [String]
    public let blockedBy: [SymphonyIssueBlockerReference]
    public let createdAt: Date?
    public let updatedAt: Date?

    public init(
        id: String,
        identifier: String,
        title: String,
        description: String?,
        priority: Int?,
        state: String,
        stateType: String,
        branchName: String?,
        url: String?,
        labels: [String],
        blockedBy: [SymphonyIssueBlockerReference],
        createdAt: Date?,
        updatedAt: Date?
    ) {
        self.id = id
        self.identifier = identifier
        self.title = title
        self.description = description
        self.priority = priority
        self.state = state
        self.stateType = stateType
        self.branchName = branchName
        self.url = url
        self.labels = labels.map { $0.lowercased() }
        self.blockedBy = blockedBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
