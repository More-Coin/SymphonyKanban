
public protocol SymphonyIssueTrackerReadPortProtocol: Sendable {
    func fetchCandidateIssues(
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue]

    func fetchIssues(
        byStates stateNames: [String],
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue]

    func fetchIssueStates(
        byIDs issueIDs: [String],
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue]
}
