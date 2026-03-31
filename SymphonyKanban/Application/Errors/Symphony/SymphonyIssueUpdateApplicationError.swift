import Foundation

public enum SymphonyIssueUpdateApplicationError: StructuredErrorProtocol, LocalizedError, Equatable {
    case missingStateChange(issueIdentifier: String)
    case issueNotFound(issueIdentifier: String)
    case issueAlreadyTerminal(issueIdentifier: String, stateType: String)

    public var code: String {
        switch self {
        case .missingStateChange:
            return "symphony.issue_update.missing_state_change"
        case .issueNotFound:
            return "symphony.issue_update.issue_not_found"
        case .issueAlreadyTerminal:
            return "symphony.issue_update.issue_already_terminal"
        }
    }

    public var message: String {
        switch self {
        case .missingStateChange:
            return "The requested Symphony issue update did not include a supported state change."
        case .issueNotFound:
            return "The requested Symphony issue could not be found in the active catalog."
        case .issueAlreadyTerminal:
            return "The requested Symphony issue is already terminal and cannot be canceled."
        }
    }

    public var retryable: Bool {
        false
    }

    public var details: String? {
        switch self {
        case .missingStateChange(let issueIdentifier):
            return "Issue `\(issueIdentifier)` did not provide a supported v1 state change."
        case .issueNotFound(let issueIdentifier):
            return "Refresh the board and make sure issue `\(issueIdentifier)` is still present in the active bindings."
        case .issueAlreadyTerminal(let issueIdentifier, let stateType):
            return "Issue `\(issueIdentifier)` is already in terminal state type `\(stateType)`."
        }
    }

    public var errorDescription: String? {
        message
    }
}
