import Foundation

public struct SymphonyIssueCatalogService {
    private let trackerConfigurationPort: any SymphonyIssueCatalogTrackerConfigurationPortProtocol
    private let fetchIssuesUseCase: FetchSymphonyIssuesUseCase

    public init(
        trackerConfigurationPort: any SymphonyIssueCatalogTrackerConfigurationPortProtocol,
        fetchIssuesUseCase: FetchSymphonyIssuesUseCase
    ) {
        self.trackerConfigurationPort = trackerConfigurationPort
        self.fetchIssuesUseCase = fetchIssuesUseCase
    }

    @MainActor
    public func queryIssues(
        currentWorkingDirectoryPath: String,
        explicitWorkflowPath: String? = nil
    ) async throws -> SymphonyIssueCollectionContract {
        let trackerConfiguration = trackerConfigurationPort.resolveTrackerConfiguration(
            currentWorkingDirectoryPath: currentWorkingDirectoryPath,
            explicitWorkflowPath: explicitWorkflowPath
        )
        let stateTypes = requestedStateTypes(using: trackerConfiguration)

        if stateTypes.isEmpty {
            return try await fetchIssuesUseCase.fetchCandidateIssues(
                using: trackerConfiguration
            )
        }

        return try await fetchIssuesUseCase.fetchIssues(
            stateTypes: stateTypes,
            using: trackerConfiguration
        )
    }

    private func requestedStateTypes(
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) -> [String] {
        var ordered: [String] = []
        var seen = Set<String>()

        for stateType in trackerConfiguration.activeStateTypes + trackerConfiguration.terminalStateTypes {
            let normalized = trackerConfiguration.normalizedStateType(stateType)
            guard normalized.isEmpty == false,
                  seen.insert(normalized).inserted else {
                continue
            }

            ordered.append(stateType)
        }

        return ordered
    }
}
