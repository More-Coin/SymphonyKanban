import Foundation

public struct SymphonyIssueDispatchEligibilityPolicy: SymphonyIssueDispatchEligibilityPolicyProtocol {
    public init() {}

    public func passesBlockerRule(
        issue: SymphonyIssue,
        terminalStates: [String]
    ) -> Bool {
        guard issue.state.caseInsensitiveCompare("Todo") == .orderedSame else {
            return true
        }

        let normalizedTerminalStates = Set(
            terminalStates.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        )

        return issue.blockedBy.allSatisfy { blocker in
            guard let state = blocker.state?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !state.isEmpty else {
                return false
            }

            return normalizedTerminalStates.contains(state.lowercased())
        }
    }
}
