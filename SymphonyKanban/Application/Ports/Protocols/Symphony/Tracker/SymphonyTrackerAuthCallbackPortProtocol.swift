public protocol SymphonyTrackerAuthCallbackPortProtocol: Sendable {
    func prepareAuthorizationCallbackListener() async throws
    func awaitAuthorizationCallback() async throws -> SymphonyTrackerAuthCallbackContract
    func cancelAuthorizationCallbackListener() async
}
