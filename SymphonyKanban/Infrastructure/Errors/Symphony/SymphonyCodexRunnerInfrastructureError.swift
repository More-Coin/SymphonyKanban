import Foundation

public enum SymphonyCodexRunnerInfrastructureError: StructuredErrorProtocol, LocalizedError {
    case codexNotFound(command: String, details: String?)
    case invalidWorkspaceCWD(details: String)
    case responseTimeout(stage: String, timeoutMs: Int)
    case turnTimeout(timeoutMs: Int)
    case portExit(exitCode: Int32, details: String?)
    case responseError(details: String)
    case policyIncompatible(details: String)

    public var code: String {
        switch self {
        case .codexNotFound:
            return "symphony.codex_runner.codex_not_found"
        case .invalidWorkspaceCWD:
            return "symphony.codex_runner.invalid_workspace_cwd"
        case .responseTimeout:
            return "symphony.codex_runner.response_timeout"
        case .turnTimeout:
            return "symphony.codex_runner.turn_timeout"
        case .portExit:
            return "symphony.codex_runner.port_exit"
        case .responseError:
            return "symphony.codex_runner.response_error"
        case .policyIncompatible:
            return "symphony.codex_runner.policy_incompatible"
        }
    }

    public var message: String {
        switch self {
        case .codexNotFound:
            return "The configured Codex app-server command could not be launched."
        case .invalidWorkspaceCWD:
            return "The launch directory does not match the validated workspace path."
        case .responseTimeout:
            return "The Codex app-server did not respond before the configured read timeout."
        case .turnTimeout:
            return "The Codex turn did not finish before the configured turn timeout."
        case .portExit:
            return "The Codex app-server exited before the gateway finished processing the turn."
        case .responseError:
            return "The Codex app-server returned an invalid or failed protocol response."
        case .policyIncompatible:
            return "The Codex app-server requirements are incompatible with the documented Symphony posture."
        }
    }

    public var retryable: Bool {
        switch self {
        case .codexNotFound,
             .invalidWorkspaceCWD,
             .policyIncompatible:
            return false
        case .responseTimeout,
             .turnTimeout,
             .portExit,
             .responseError:
            return true
        }
    }

    public var details: String? {
        switch self {
        case .codexNotFound(let command, let details):
            return "Command: \(command)." + (details.map { " \($0)" } ?? "")
        case .invalidWorkspaceCWD(let details),
             .responseError(let details),
             .policyIncompatible(let details):
            return details
        case .responseTimeout(let stage, let timeoutMs):
            return "Stage: \(stage). Timeout: \(timeoutMs) ms."
        case .turnTimeout(let timeoutMs):
            return "Timeout: \(timeoutMs) ms."
        case .portExit(let exitCode, let details):
            return "Exit code: \(exitCode)." + (details.map { " \($0)" } ?? "")
        }
    }

    public var errorDescription: String? {
        message
    }

    var applicationError: SymphonyAgentRuntimeApplicationError {
        switch self {
        case .codexNotFound(let command, let details):
            return .runtimeUnavailable(command: command, details: details)
        case .invalidWorkspaceCWD(let details):
            return .invalidWorkspacePath(details: details)
        case .responseTimeout(let stage, let timeoutMs):
            return .responseTimeout(stage: stage, timeoutMs: timeoutMs)
        case .turnTimeout(let timeoutMs):
            return .turnTimeout(timeoutMs: timeoutMs)
        case .portExit(let exitCode, let details):
            return .processExit(exitCode: exitCode, details: details)
        case .responseError(let details):
            return .protocolViolation(details: details)
        case .policyIncompatible(let details):
            return .requirementsMismatch(details: details)
        }
    }
}
