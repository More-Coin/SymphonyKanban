public protocol SymphonyIssueCatalogTrackerConfigurationPortProtocol {
    func resolveTrackerConfiguration(
        currentWorkingDirectoryPath: String,
        explicitWorkflowPath: String?
    ) -> SymphonyServiceConfigContract.Tracker
}
