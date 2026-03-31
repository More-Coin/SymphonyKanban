public protocol SymphonyIssueTrackerPortProtocol: Sendable {
    func fetchCandidateIssues(
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue]

    func fetchIssues(
        byStateTypes stateTypes: [String],
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue]

    func fetchIssueStates(
        byIDs issueIDs: [String],
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue]

    func updateIssue(
        _ request: SymphonyIssueUpdateRequestContract,
        currentIssue: SymphonyIssue,
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> SymphonyIssueUpdateResultContract
}

public typealias SymphonyIssueTrackerReadPortProtocol = SymphonyIssueTrackerPortProtocol
