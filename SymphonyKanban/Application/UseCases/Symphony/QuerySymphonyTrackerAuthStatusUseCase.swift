public struct QuerySymphonyTrackerAuthStatusUseCase: Sendable {
    private let trackerAuthPort: any SymphonyTrackerAuthPortProtocol

    public init(
        trackerAuthPort: any SymphonyTrackerAuthPortProtocol
    ) {
        self.trackerAuthPort = trackerAuthPort
    }

    public func execute(
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) throws -> SymphonyTrackerAuthStatusContract {
        try trackerAuthPort.queryStatus(for: trackerConfiguration)
    }
}
