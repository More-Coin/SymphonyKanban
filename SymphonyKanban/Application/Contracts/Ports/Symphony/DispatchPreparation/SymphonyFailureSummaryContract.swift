public struct SymphonyFailureSummaryContract: Equatable, Sendable {
    public let message: String
    public let details: String?

    public init(
        message: String,
        details: String? = nil
    ) {
        self.message = message
        self.details = details
    }
}
