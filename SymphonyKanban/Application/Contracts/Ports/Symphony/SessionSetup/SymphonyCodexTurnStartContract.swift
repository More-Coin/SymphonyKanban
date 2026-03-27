public struct SymphonyCodexTurnStartContract: Equatable, Sendable {
    public let threadID: String
    public let inputText: String
    public let currentWorkingDirectoryPath: String
    public let title: String
    public let approvalPolicy: String
    public let sandboxPolicy: SymphonyCodexTurnSandboxPolicyContract

    public init(
        threadID: String,
        inputText: String,
        currentWorkingDirectoryPath: String,
        title: String,
        approvalPolicy: String,
        sandboxPolicy: SymphonyCodexTurnSandboxPolicyContract
    ) {
        self.threadID = threadID
        self.inputText = inputText
        self.currentWorkingDirectoryPath = currentWorkingDirectoryPath
        self.title = title
        self.approvalPolicy = approvalPolicy
        self.sandboxPolicy = sandboxPolicy
    }
}
