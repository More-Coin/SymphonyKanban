public struct SymphonyCodexSessionStartupContract: Equatable, Sendable {
    public struct InitializeRequest: Equatable, Sendable {
        public let clientInfo: SymphonyCodexClientInfoContract
        public let capabilities: SymphonyCodexCapabilitiesContract

        public init(
            clientInfo: SymphonyCodexClientInfoContract,
            capabilities: SymphonyCodexCapabilitiesContract
        ) {
            self.clientInfo = clientInfo
            self.capabilities = capabilities
        }
    }

    public struct ThreadStartRequest: Equatable, Sendable {
        public let currentWorkingDirectoryPath: String
        public let approvalPolicy: String
        public let sandbox: String
        public let serviceName: String?

        public init(
            currentWorkingDirectoryPath: String,
            approvalPolicy: String,
            sandbox: String,
            serviceName: String? = nil
        ) {
            self.currentWorkingDirectoryPath = currentWorkingDirectoryPath
            self.approvalPolicy = approvalPolicy
            self.sandbox = sandbox
            self.serviceName = serviceName
        }
    }

    public struct InitialTurnRequest: Equatable, Sendable {
        public let inputText: String
        public let currentWorkingDirectoryPath: String
        public let title: String
        public let approvalPolicy: String
        public let sandboxPolicy: SymphonyCodexTurnSandboxPolicyContract

        public init(
            inputText: String,
            currentWorkingDirectoryPath: String,
            title: String,
            approvalPolicy: String,
            sandboxPolicy: SymphonyCodexTurnSandboxPolicyContract
        ) {
            self.inputText = inputText
            self.currentWorkingDirectoryPath = currentWorkingDirectoryPath
            self.title = title
            self.approvalPolicy = approvalPolicy
            self.sandboxPolicy = sandboxPolicy
        }
    }

    public let initializeRequest: InitializeRequest
    public let threadStartRequest: ThreadStartRequest
    public let initialTurnRequest: InitialTurnRequest
    public let approvalPosture: SymphonyCodexApprovalPostureContract
    public let command: String
    public let readTimeoutMs: Int
    public let turnTimeoutMs: Int

    public init(
        initializeRequest: InitializeRequest,
        threadStartRequest: ThreadStartRequest,
        initialTurnRequest: InitialTurnRequest,
        approvalPosture: SymphonyCodexApprovalPostureContract,
        command: String,
        readTimeoutMs: Int,
        turnTimeoutMs: Int
    ) {
        self.initializeRequest = initializeRequest
        self.threadStartRequest = threadStartRequest
        self.initialTurnRequest = initialTurnRequest
        self.approvalPosture = approvalPosture
        self.command = command
        self.readTimeoutMs = readTimeoutMs
        self.turnTimeoutMs = turnTimeoutMs
    }
}
