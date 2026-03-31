public struct SymphonyFallbackIssueTrackerPortAdapter: SymphonyIssueTrackerPortProtocol, Sendable {
    private let trackerAuthPort: any SymphonyTrackerAuthPortProtocol
    private let liveGateway: any SymphonyIssueTrackerPortProtocol
    private let mockGateway: any SymphonyIssueTrackerPortProtocol
    private let sourceSelectionPolicy: SymphonyIssueTrackerSourceSelectionPolicy

    init(
        trackerAuthPort: any SymphonyTrackerAuthPortProtocol,
        liveGateway: any SymphonyIssueTrackerPortProtocol,
        mockGateway: any SymphonyIssueTrackerPortProtocol = SymphonyMockIssueTrackerPortAdapter(),
        sourceSelectionPolicy: SymphonyIssueTrackerSourceSelectionPolicy = SymphonyIssueTrackerSourceSelectionPolicy()
    ) {
        self.trackerAuthPort = trackerAuthPort
        self.liveGateway = liveGateway
        self.mockGateway = mockGateway
        self.sourceSelectionPolicy = sourceSelectionPolicy
    }

    public func fetchCandidateIssues(
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        try await selectedGateway(for: trackerConfiguration).fetchCandidateIssues(
            using: trackerConfiguration
        )
    }

    public func fetchIssues(
        byStateTypes stateTypes: [String],
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        try await selectedGateway(for: trackerConfiguration).fetchIssues(
            byStateTypes: stateTypes,
            using: trackerConfiguration
        )
    }

    public func fetchIssueStates(
        byIDs issueIDs: [String],
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        try await selectedGateway(for: trackerConfiguration).fetchIssueStates(
            byIDs: issueIDs,
            using: trackerConfiguration
        )
    }

    public func updateIssue(
        _ request: SymphonyIssueUpdateRequestContract,
        currentIssue: SymphonyIssue,
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> SymphonyIssueUpdateResultContract {
        try await selectedGateway(for: trackerConfiguration).updateIssue(
            request,
            currentIssue: currentIssue,
            using: trackerConfiguration
        )
    }

    private func selectedGateway(
        for trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) -> any SymphonyIssueTrackerPortProtocol {
        let authStatus = try? trackerAuthPort.queryStatus(for: trackerConfiguration)

        switch sourceSelectionPolicy.selectSource(
            trackerConfiguration: trackerConfiguration,
            authStatus: authStatus
        ) {
        case .live:
            return liveGateway
        case .mock:
            return mockGateway
        }
    }
}
