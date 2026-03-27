import Foundation

public enum HookExecutionFailureModel: Sendable {
    case failed(exitCode: Int32, output: String)
    case timedOut(output: String)

    public var output: String? {
        switch self {
        case .failed(_, let output), .timedOut(let output):
            return output
        }
    }

    public func toInfrastructureError(
        kind: String,
        workspacePath: String,
        timeoutMs: Int
    ) -> SymphonyWorkspaceInfrastructureError {
        switch self {
        case .failed(let exitCode, let output):
            let details = output.isEmpty
                ? "Exit code: \(exitCode)."
                : "Exit code: \(exitCode). Output captured."
            return SymphonyWorkspaceInfrastructureError.hookFailed(
                kind: kind,
                workspacePath: workspacePath,
                details: details
            )
        case .timedOut:
            return SymphonyWorkspaceInfrastructureError.hookTimedOut(
                kind: kind,
                workspacePath: workspacePath,
                timeoutMs: timeoutMs
            )
        }
    }
}

public enum HookExecutionOutcomeModel: Sendable {
    case success(HookExecutionResultModel)
    case failure(HookExecutionFailureModel)
}

public struct HookExecutionResultModel: Sendable {
    public let standardOutput: String
    public let standardError: String

    public init(
        standardOutput: String,
        standardError: String
    ) {
        self.standardOutput = standardOutput
        self.standardError = standardError
    }

    public var combinedOutput: String {
        [standardOutput, standardError]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}

extension HookExecutionResultModel {
    static func from(
        standardOutputPipe: Pipe,
        standardErrorPipe: Pipe
    ) -> Self {
        let standardOutput = String(
            data: standardOutputPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        let standardError = String(
            data: standardErrorPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""

        return Self(
            standardOutput: standardOutput,
            standardError: standardError
        )
    }
}
