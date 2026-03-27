
public protocol SymphonyCodexRequestFactoryPortProtocol {
    func makeSessionStartup(
        issue: SymphonyIssue,
        prompt: String,
        workspacePath: String,
        using serviceConfig: SymphonyServiceConfigContract
    ) -> SymphonyCodexSessionStartupContract

    func makeContinuationTurnRequest(
        issue: SymphonyIssue,
        threadID: String,
        inputText: String,
        workspacePath: String,
        using serviceConfig: SymphonyServiceConfigContract
    ) -> SymphonyCodexTurnStartContract
}
