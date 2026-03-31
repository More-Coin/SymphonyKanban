public struct UpdateSymphonyIssueUseCase: Sendable {
    private let issueTrackerPort: any SymphonyIssueTrackerPortProtocol

    public init(issueTrackerPort: any SymphonyIssueTrackerPortProtocol) {
        self.issueTrackerPort = issueTrackerPort
    }

    public func updateIssue(
        _ request: SymphonyIssueUpdateRequestContract,
        currentIssue: SymphonyIssue,
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> SymphonyIssueUpdateResultContract {
        try await issueTrackerPort.updateIssue(
            request,
            currentIssue: currentIssue,
            using: trackerConfiguration
        )
    }
}
