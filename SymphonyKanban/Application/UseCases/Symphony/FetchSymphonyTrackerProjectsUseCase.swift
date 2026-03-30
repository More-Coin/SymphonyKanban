public struct FetchSymphonyTrackerProjectsUseCase: Sendable {
    private let trackerScopeReadPort: any SymphonyTrackerScopeReadPortProtocol

    public init(
        trackerScopeReadPort: any SymphonyTrackerScopeReadPortProtocol
    ) {
        self.trackerScopeReadPort = trackerScopeReadPort
    }

    public func fetch(
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyTrackerScopeOptionContract] {
        try await trackerScopeReadPort.fetchProjects(using: trackerConfiguration)
    }
}
