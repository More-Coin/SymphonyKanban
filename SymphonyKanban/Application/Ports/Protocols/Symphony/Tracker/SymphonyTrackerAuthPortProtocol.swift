public protocol SymphonyTrackerAuthPortProtocol: Sendable {
    func queryStatus(
        for trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) throws -> SymphonyTrackerAuthStatusContract

    func startAuthorization(
        for trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) throws -> SymphonyTrackerAuthStartResultContract

    func completeAuthorization(
        _ callback: SymphonyTrackerAuthCallbackContract,
        for trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> SymphonyTrackerAuthStatusContract

    func disconnect(
        for trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> SymphonyTrackerAuthStatusContract
}
