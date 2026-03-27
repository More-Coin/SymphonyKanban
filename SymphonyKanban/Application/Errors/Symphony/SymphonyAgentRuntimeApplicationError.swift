import Foundation

public enum SymphonyAgentRuntimeApplicationError: StructuredErrorProtocol, LocalizedError {
    case runtimeUnavailable(command: String, details: String?)
    case invalidWorkspacePath(details: String)
    case responseTimeout(stage: String, timeoutMs: Int)
    case turnTimeout(timeoutMs: Int)
    case processExit(exitCode: Int32, details: String?)
    case protocolViolation(details: String)
    case turnFailed(details: String?)
    case turnCancelled(details: String?)
    case inputRequired(details: String?)
    case requirementsMismatch(details: String)

    public var code: String {
        switch self {
        case .runtimeUnavailable:
            return "symphony.agent_runtime.runtime_unavailable"
        case .invalidWorkspacePath:
            return "symphony.agent_runtime.invalid_workspace_path"
        case .responseTimeout:
            return "symphony.agent_runtime.response_timeout"
        case .turnTimeout:
            return "symphony.agent_runtime.turn_timeout"
        case .processExit:
            return "symphony.agent_runtime.process_exit"
        case .protocolViolation:
            return "symphony.agent_runtime.protocol_violation"
        case .turnFailed:
            return "symphony.agent_runtime.turn_failed"
        case .turnCancelled:
            return "symphony.agent_runtime.turn_cancelled"
        case .inputRequired:
            return "symphony.agent_runtime.input_required"
        case .requirementsMismatch:
            return "symphony.agent_runtime.requirements_mismatch"
        }
    }

    public var message: String {
        switch self {
        case .runtimeUnavailable:
            return "The configured agent runtime could not be launched."
        case .invalidWorkspacePath:
            return "The launch directory does not match the validated workspace path."
        case .responseTimeout:
            return "The agent runtime did not respond before the configured read timeout."
        case .turnTimeout:
            return "The agent turn did not finish before the configured timeout."
        case .processExit:
            return "The agent runtime exited before the gateway finished processing the turn."
        case .protocolViolation:
            return "The agent runtime returned an invalid or failed protocol response."
        case .turnFailed:
            return "The agent turn failed."
        case .turnCancelled:
            return "The agent turn was cancelled."
        case .inputRequired:
            return "The agent runtime requested unsupported interactive user input."
        case .requirementsMismatch:
            return "The agent runtime requirements are incompatible with the accepted Symphony posture."
        }
    }

    public var retryable: Bool {
        switch self {
        case .runtimeUnavailable,
             .invalidWorkspacePath,
             .turnCancelled,
             .inputRequired,
             .requirementsMismatch:
            return false
        case .responseTimeout,
             .turnTimeout,
             .processExit,
             .protocolViolation,
             .turnFailed:
            return true
        }
    }

    public var details: String? {
        switch self {
        case .runtimeUnavailable(let command, let details):
            return "Launch command: \(command)." + (details.map { " \($0)" } ?? "")
        case .invalidWorkspacePath(let details),
             .protocolViolation(let details),
             .requirementsMismatch(let details):
            return details
        case .responseTimeout(let stage, let timeoutMs):
            return "Stage: \(stage). Timeout: \(timeoutMs) ms."
        case .turnTimeout(let timeoutMs):
            return "Timeout: \(timeoutMs) ms."
        case .processExit(let exitCode, let details):
            return "Exit code: \(exitCode)." + (details.map { " \($0)" } ?? "")
        case .turnFailed(let details),
             .turnCancelled(let details),
             .inputRequired(let details):
            return details
        }
    }

    public var errorDescription: String? {
        message
    }
}
