
public struct SymphonyWorkerAttemptRequestContract: Equatable, Sendable {
    public let issue: SymphonyIssue
    public let attempt: Int?
    public let workflowConfiguration: SymphonyWorkflowConfigurationResultContract

    public init(
        issue: SymphonyIssue,
        attempt: Int?,
        workflowConfiguration: SymphonyWorkflowConfigurationResultContract
    ) {
        self.issue = issue
        self.attempt = attempt
        self.workflowConfiguration = workflowConfiguration
    }
}
