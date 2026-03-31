public struct DisconnectSymphonyTrackerUseCase: Sendable {
    private let trackerAuthPort: any SymphonyTrackerAuthPortProtocol

    public init(
        trackerAuthPort: any SymphonyTrackerAuthPortProtocol
    ) {
        self.trackerAuthPort = trackerAuthPort
    }

    public func execute(
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> SymphonyTrackerAuthStatusContract {
        try await trackerAuthPort.disconnect(for: trackerConfiguration)
    }
}
