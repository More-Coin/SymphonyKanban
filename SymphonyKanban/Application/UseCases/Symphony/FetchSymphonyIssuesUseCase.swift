
public struct FetchSymphonyIssuesUseCase: Sendable {
    private let issueTrackerReadPort: any SymphonyIssueTrackerReadPortProtocol

    public init(issueTrackerReadPort: any SymphonyIssueTrackerReadPortProtocol) {
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
        stateNames: [String],
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> SymphonyIssueCollectionContract {
        SymphonyIssueCollectionContract(
            issues: try await issueTrackerReadPort.fetchIssues(
                byStates: stateNames,
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
