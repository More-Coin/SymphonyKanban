
public struct FetchSymphonyIssuesUseCase: Sendable {
    private let issueTrackerReadPort: any SymphonyIssueTrackerPortProtocol

    public init(issueTrackerReadPort: any SymphonyIssueTrackerPortProtocol) {
        self.issueTrackerReadPort = issueTrackerReadPort
    }

    public func fetchCandidateIssues(
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> SymphonyIssueCollectionContract {
        SymphonyIssueCollectionContract(
            issues: try await issueTrackerReadPort.fetchCandidateIssues(using: trackerConfiguration)
        )
    }

    public func fetchIssues(
        stateTypes: [String],
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> SymphonyIssueCollectionContract {
        SymphonyIssueCollectionContract(
            issues: try await issueTrackerReadPort.fetchIssues(
                byStateTypes: stateTypes,
                using: trackerConfiguration
            )
        )
    }

    public func fetchIssueStates(
        issueIDs: [String],
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> SymphonyIssueCollectionContract {
        SymphonyIssueCollectionContract(
            issues: try await issueTrackerReadPort.fetchIssueStates(
                byIDs: issueIDs,
                using: trackerConfiguration
            )
        )
    }
}
