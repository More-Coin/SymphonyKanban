public struct SymphonyCodexApprovalPostureContract: Equatable, Sendable {
    public let threadApprovalPolicy: String
    public let turnApprovalPolicy: String
    public let autoApproveCommandExecutions: Bool
    public let autoApproveFileChanges: Bool
    public let failOnInputRequired: Bool
    public let rejectUnsupportedDynamicToolCalls: Bool
    public let failOnIncompatibleRequirements: Bool

    public init(
        threadApprovalPolicy: String,
        turnApprovalPolicy: String,
        autoApproveCommandExecutions: Bool,
        autoApproveFileChanges: Bool,
        failOnInputRequired: Bool,
        rejectUnsupportedDynamicToolCalls: Bool,
        failOnIncompatibleRequirements: Bool
    ) {
        self.threadApprovalPolicy = threadApprovalPolicy
        self.turnApprovalPolicy = turnApprovalPolicy
        self.autoApproveCommandExecutions = autoApproveCommandExecutions
        self.autoApproveFileChanges = autoApproveFileChanges
        self.failOnInputRequired = failOnInputRequired
        self.rejectUnsupportedDynamicToolCalls = rejectUnsupportedDynamicToolCalls
        self.failOnIncompatibleRequirements = failOnIncompatibleRequirements
    }

    public static let trustedSingleTenantDefault = Self(
        threadApprovalPolicy: "never",
        turnApprovalPolicy: "unlessTrusted",
        autoApproveCommandExecutions: true,
        autoApproveFileChanges: true,
        failOnInputRequired: true,
        rejectUnsupportedDynamicToolCalls: true,
        failOnIncompatibleRequirements: true
    )
}
