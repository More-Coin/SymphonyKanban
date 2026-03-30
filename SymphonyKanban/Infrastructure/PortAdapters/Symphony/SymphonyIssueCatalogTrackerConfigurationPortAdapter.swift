public struct SymphonyIssueCatalogTrackerConfigurationPortAdapter: SymphonyIssueCatalogTrackerConfigurationPortProtocol {
    private let resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase

    public init(
        resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase
    ) {
        self.resolveWorkflowConfigurationUseCase = resolveWorkflowConfigurationUseCase
    }

    public func resolveTrackerConfiguration(
        currentWorkingDirectoryPath: String,
        explicitWorkflowPath: String?
    ) -> SymphonyServiceConfigContract.Tracker {
        do {
            return try resolveWorkflowConfigurationUseCase.resolve(
                SymphonyWorkspaceLocatorContract(
                    currentWorkingDirectoryPath: currentWorkingDirectoryPath,
                    explicitWorkflowPath: explicitWorkflowPath
                )
            ).serviceConfig.tracker
        } catch {
            return SymphonyServiceConfigContract.Tracker(
                kind: "linear",
                endpoint: nil,
                projectSlug: nil,
                activeStateTypes: [],
                terminalStateTypes: []
            )
        }
    }
}
