import Foundation

struct SymphonyCodexNormalizedConfiguration {
    let threadApprovalPolicy: String
    let turnApprovalPolicy: String
    let threadSandbox: String
    let turnSandboxPolicy: SymphonyCodexTurnSandboxPolicyContract
}

struct SymphonyCodexConfigurationModel {
    private enum Defaults {
        static let threadSandbox = "workspaceWrite"
    }

    func fromContract(
        from codex: SymphonyServiceConfigContract.Codex,
        approvalPosture: SymphonyCodexApprovalPostureContract,
        workspacePath: String
    ) -> SymphonyCodexNormalizedConfiguration {
        SymphonyCodexNormalizedConfiguration(
            threadApprovalPolicy: normalizedString(from: codex.approvalPolicy)
                ?? approvalPosture.threadApprovalPolicy,
            turnApprovalPolicy: normalizedString(from: codex.approvalPolicy)
                ?? approvalPosture.turnApprovalPolicy,
            threadSandbox: normalizedString(from: codex.threadSandbox)
                ?? Defaults.threadSandbox,
            turnSandboxPolicy: fromContract(
                codex.turnSandboxPolicy,
                workspacePath: workspacePath
            )
        )
    }

    private func fromContract(
        _ value: SymphonyConfigValueContract?,
        workspacePath: String
    ) -> SymphonyCodexTurnSandboxPolicyContract {
        guard let object = value?.dictionaryValue else {
            return SymphonyCodexTurnSandboxPolicyContract(
                type: Defaults.threadSandbox,
                writableRoots: [workspacePath],
                networkAccess: false
            )
        }

        let configuredRoots = object["writableRoots"]?.arrayValue?
            .compactMap(\.stringValue)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        return SymphonyCodexTurnSandboxPolicyContract(
            type: object["type"]?.stringValue ?? Defaults.threadSandbox,
            writableRoots: configuredRoots?.isEmpty == false ? configuredRoots ?? [] : [workspacePath],
            networkAccess: fromContract(object["networkAccess"]) ?? false,
            access: object["access"],
            readOnlyAccess: object["readOnlyAccess"]
        )
    }

    private func normalizedString(from value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func fromContract(_ value: SymphonyConfigValueContract?) -> Bool? {
        guard let value else {
            return nil
        }

        switch value {
        case .bool(let bool):
            return bool
        case .string(let string):
            return Bool(string)
        default:
            return nil
        }
    }
}
