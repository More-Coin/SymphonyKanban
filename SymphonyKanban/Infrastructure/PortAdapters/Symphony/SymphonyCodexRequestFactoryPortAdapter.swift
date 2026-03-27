
public struct SymphonyCodexRequestFactoryPortAdapter: SymphonyCodexRequestFactoryPortProtocol {
    private enum Defaults {
        static let clientName = "symphony"
        static let clientTitle = "Symphony"
        static let clientVersion = "1.0"
    }

    private let approvalPosture: SymphonyCodexApprovalPostureContract
    private let configurationModel: SymphonyCodexConfigurationModel

    public init(
        approvalPosture: SymphonyCodexApprovalPostureContract = .trustedSingleTenantDefault
    ) {
        self.approvalPosture = approvalPosture
        self.configurationModel = SymphonyCodexConfigurationModel()
    }

    public func makeSessionStartup(
        issue: SymphonyIssue,
        prompt: String,
        workspacePath: String,
        using serviceConfig: SymphonyServiceConfigContract
    ) -> SymphonyCodexSessionStartupContract {
        let normalizedConfiguration = configurationModel.fromContract(
            from: serviceConfig.codex,
            approvalPosture: approvalPosture,
            workspacePath: workspacePath
        )

        return SymphonyCodexSessionStartupContract(
            initializeRequest: .init(
                clientInfo: .init(
                    name: Defaults.clientName,
                    title: Defaults.clientTitle,
                    version: Defaults.clientVersion
                ),
                capabilities: .init(
                    experimentalAPI: true,
                    optOutNotificationMethods: ["item/agentMessage/delta"]
                )
            ),
            threadStartRequest: .init(
                currentWorkingDirectoryPath: workspacePath,
                approvalPolicy: normalizedConfiguration.threadApprovalPolicy,
                sandbox: normalizedConfiguration.threadSandbox,
                serviceName: Defaults.clientName
            ),
            initialTurnRequest: .init(
                inputText: prompt,
                currentWorkingDirectoryPath: workspacePath,
                title: "\(issue.identifier): \(issue.title)",
                approvalPolicy: normalizedConfiguration.turnApprovalPolicy,
                sandboxPolicy: normalizedConfiguration.turnSandboxPolicy
            ),
            approvalPosture: approvalPosture,
            command: serviceConfig.codex.command,
            readTimeoutMs: serviceConfig.codex.readTimeoutMs,
            turnTimeoutMs: serviceConfig.codex.turnTimeoutMs
        )
    }

    public func makeContinuationTurnRequest(
        issue: SymphonyIssue,
        threadID: String,
        inputText: String,
        workspacePath: String,
        using serviceConfig: SymphonyServiceConfigContract
    ) -> SymphonyCodexTurnStartContract {
        let normalizedConfiguration = configurationModel.fromContract(
            from: serviceConfig.codex,
            approvalPosture: approvalPosture,
            workspacePath: workspacePath
        )

        return SymphonyCodexTurnStartContract(
            threadID: threadID,
            inputText: inputText,
            currentWorkingDirectoryPath: workspacePath,
            title: "\(issue.identifier): \(issue.title)",
            approvalPolicy: normalizedConfiguration.turnApprovalPolicy,
            sandboxPolicy: normalizedConfiguration.turnSandboxPolicy
        )
    }
}
