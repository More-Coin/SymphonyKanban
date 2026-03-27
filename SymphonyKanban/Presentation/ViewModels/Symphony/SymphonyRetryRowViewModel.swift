public struct SymphonyRetryRowViewModel: Identifiable, Equatable, Sendable {
    public let issueIdentifier: String
    public let attemptLabel: String
    public let dueLabel: String
    public let errorLabel: String?
    public let isSelected: Bool

    public var id: String {
        issueIdentifier
    }

    public init(
        issueIdentifier: String,
        attemptLabel: String,
        dueLabel: String,
        errorLabel: String?,
        isSelected: Bool
    ) {
        self.issueIdentifier = issueIdentifier
        self.attemptLabel = attemptLabel
        self.dueLabel = dueLabel
        self.errorLabel = errorLabel
        self.isSelected = isSelected
    }
}
