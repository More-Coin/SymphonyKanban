import Foundation

public struct SymphonyIssueDispatchEligibilityPolicy: SymphonyIssueDispatchEligibilityPolicyProtocol {
    public init() {}

    public func passesBlockerRule(
        issue: SymphonyIssue,
        terminalStateTypes: [String]
    ) -> Bool {
        let normalizedStateType = issue.stateType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalizedStateType == "unstarted" || normalizedStateType == "backlog" else {
            return true
        }

        let normalizedTerminalStateTypes = Set(
            terminalStateTypes.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        )

        return issue.blockedBy.allSatisfy { blocker in
            guard let stateType = blocker.stateType?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !stateType.isEmpty else {
                return false
            }

            return normalizedTerminalStateTypes.contains(stateType.lowercased())
        }
    }
}
