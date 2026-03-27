
public struct SymphonyPromptRenderRequestContract: Equatable, Sendable {
    public let workflowDefinition: SymphonyWorkflowDefinitionContract
    public let issue: SymphonyIssue
    public let attempt: Int?

    public init(
        workflowDefinition: SymphonyWorkflowDefinitionContract,
        issue: SymphonyIssue,
        attempt: Int?
    ) {
        self.workflowDefinition = workflowDefinition
        self.issue = issue
        self.attempt = attempt
    }
}
