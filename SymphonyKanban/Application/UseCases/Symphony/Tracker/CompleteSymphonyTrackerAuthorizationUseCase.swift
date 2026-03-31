public struct CompleteSymphonyTrackerAuthorizationUseCase: Sendable {
    private let trackerAuthPort: any SymphonyTrackerAuthPortProtocol

    public init(
        trackerAuthPort: any SymphonyTrackerAuthPortProtocol
    ) {
        self.trackerAuthPort = trackerAuthPort
    }

    public func execute(
        _ callback: SymphonyTrackerAuthCallbackContract,
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> SymphonyTrackerAuthStatusContract {
        try await trackerAuthPort.completeAuthorization(
            callback,
            for: trackerConfiguration
        )
    }
}
