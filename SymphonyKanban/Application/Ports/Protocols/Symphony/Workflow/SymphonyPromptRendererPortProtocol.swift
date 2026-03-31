
public protocol SymphonyPromptRendererPortProtocol {
    func renderPromptTemplate(
        _ promptTemplate: String,
        issue: SymphonyIssue,
        attempt: Int?
    ) throws -> String
}
