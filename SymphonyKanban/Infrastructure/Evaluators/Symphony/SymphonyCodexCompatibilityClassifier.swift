struct SymphonyCodexCompatibilityClassifier {
    enum Failure: Equatable, Sendable {
        case approvalPolicyDisallowed
        case sandboxModeDisallowed
        case networkAccessRequired
        case adminAccessRequired

        var details: String {
            switch self {
            case .approvalPolicyDisallowed:
                "The server did not allow the documented approval policies."
            case .sandboxModeDisallowed:
                "The server did not allow the documented sandbox modes."
            case .networkAccessRequired:
                "The server required network access, but the documented turn posture forbids it."
            case .adminAccessRequired:
                "The server required administrative access, but the documented posture does not allow it."
            }
        }
    }

    func classify(
        startup: SymphonyCodexSessionStartupContract,
        requirements: SymphonyCodexCompatibilityRequirementsModel
    ) -> Failure? {
        if let allowedApprovalPolicies = requirements.allowedApprovalPolicies,
           (!allowedApprovalPolicies.contains(startup.threadStartRequest.approvalPolicy) ||
            !allowedApprovalPolicies.contains(startup.initialTurnRequest.approvalPolicy)) {
            return .approvalPolicyDisallowed
        }

        if let allowedSandboxModes = requirements.allowedSandboxModes,
           (!allowedSandboxModes.contains(startup.threadStartRequest.sandbox) ||
            !allowedSandboxModes.contains(startup.initialTurnRequest.sandboxPolicy.type)) {
            return .sandboxModeDisallowed
        }

        if requirements.requiresNetworkAccess && !startup.initialTurnRequest.sandboxPolicy.networkAccess {
            return .networkAccessRequired
        }

        if requirements.requiresAdminAccess {
            return .adminAccessRequired
        }

        return nil
    }
}
