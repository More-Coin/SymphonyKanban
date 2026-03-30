public protocol SymphonyTrackerScopeReadPortProtocol: Sendable {
    func fetchTeams(
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyTrackerScopeOptionContract]

    func fetchProjects(
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyTrackerScopeOptionContract]
}
