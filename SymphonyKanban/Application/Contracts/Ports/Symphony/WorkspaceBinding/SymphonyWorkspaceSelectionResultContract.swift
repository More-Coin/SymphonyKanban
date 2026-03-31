public struct SymphonyWorkspaceSelectionResultContract: Equatable, Sendable {
    public enum WorkflowProvisioningStatus: Equatable, Sendable {
        case created
        case existing
    }

    public let workspaceLocator: SymphonyWorkspaceLocatorContract
    public let resolvedWorkflowPath: String
    public let workflowProvisioningStatus: WorkflowProvisioningStatus

    public init(
        workspaceLocator: SymphonyWorkspaceLocatorContract,
        resolvedWorkflowPath: String,
        workflowProvisioningStatus: WorkflowProvisioningStatus
    ) {
        self.workspaceLocator = workspaceLocator
        self.resolvedWorkflowPath = resolvedWorkflowPath
        self.workflowProvisioningStatus = workflowProvisioningStatus
    }
}
