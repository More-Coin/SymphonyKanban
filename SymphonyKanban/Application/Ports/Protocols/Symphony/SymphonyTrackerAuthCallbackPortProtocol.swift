public protocol SymphonyTrackerAuthCallbackPortProtocol: Sendable {
    func awaitAuthorizationCallback() async throws -> SymphonyTrackerAuthCallbackContract
}
