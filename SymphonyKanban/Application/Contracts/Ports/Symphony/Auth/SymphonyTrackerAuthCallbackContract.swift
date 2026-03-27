public struct SymphonyTrackerAuthCallbackContract: Equatable, Sendable {
    public let trackerKind: String
    public let authorizationCode: String?
    public let state: String?
    public let errorCode: String?
    public let errorDescription: String?

    public init(
        trackerKind: String,
        authorizationCode: String?,
        state: String?,
        errorCode: String?,
        errorDescription: String?
    ) {
        self.trackerKind = trackerKind
        self.authorizationCode = authorizationCode
        self.state = state
        self.errorCode = errorCode
        self.errorDescription = errorDescription
    }
}
