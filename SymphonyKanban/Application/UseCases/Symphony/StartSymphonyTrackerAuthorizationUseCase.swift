public struct StartSymphonyTrackerAuthorizationUseCase: Sendable {
    private let trackerAuthPort: any SymphonyTrackerAuthPortProtocol

    public init(
        trackerAuthPort: any SymphonyTrackerAuthPortProtocol
    ) {
        self.trackerAuthPort = trackerAuthPort
    }

    public func execute(
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) throws -> SymphonyTrackerAuthStartResultContract {
        try trackerAuthPort.startAuthorization(for: trackerConfiguration)
    }
}
