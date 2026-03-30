public struct SymphonyActiveWorkspaceBindingContextContract: Equatable, Sendable, Identifiable {
    public let workspaceBinding: SymphonyWorkspaceTrackerBindingContract
    public let effectiveWorkspaceLocator: SymphonyWorkspaceLocatorContract
    public let workflowConfiguration: SymphonyWorkflowConfigurationResultContract?
    public let trackerAuthStatus: SymphonyTrackerAuthStatusContract?
    public let startupFailure: SymphonyFailureSummaryContract?

    public init(
        workspaceBinding: SymphonyWorkspaceTrackerBindingContract,
        effectiveWorkspaceLocator: SymphonyWorkspaceLocatorContract,
        workflowConfiguration: SymphonyWorkflowConfigurationResultContract? = nil,
        trackerAuthStatus: SymphonyTrackerAuthStatusContract? = nil,
        startupFailure: SymphonyFailureSummaryContract? = nil
    ) {
        self.workspaceBinding = workspaceBinding
        self.effectiveWorkspaceLocator = effectiveWorkspaceLocator
        self.workflowConfiguration = workflowConfiguration
        self.trackerAuthStatus = trackerAuthStatus
        self.startupFailure = startupFailure
    }

    public var id: String {
        workspaceBinding.workspacePath
    }

    public var isReady: Bool {
        startupFailure == nil
            && workflowConfiguration != nil
            && trackerAuthStatus?.isReady == true
    }
}
