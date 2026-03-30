@testable import SymphonyKanban

actor SymphonyTrackerScopeReadPortSpy: SymphonyTrackerScopeReadPortProtocol {
    private let teamsResponse: [SymphonyTrackerScopeOptionContract]
    private let projectsResponse: [SymphonyTrackerScopeOptionContract]
    private let teamsError: (any Error)?
    private let projectsError: (any Error)?

    init(
        teamsResponse: [SymphonyTrackerScopeOptionContract] = [],
        projectsResponse: [SymphonyTrackerScopeOptionContract] = [],
        teamsError: (any Error)? = nil,
        projectsError: (any Error)? = nil
    ) {
        self.teamsResponse = teamsResponse
        self.projectsResponse = projectsResponse
        self.teamsError = teamsError
        self.projectsError = projectsError
    }

    func fetchTeams(
        using _: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyTrackerScopeOptionContract] {
        if let teamsError {
            throw teamsError
        }

        return teamsResponse
    }

    func fetchProjects(
        using _: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyTrackerScopeOptionContract] {
        if let projectsError {
            throw projectsError
        }

        return projectsResponse
    }
}
