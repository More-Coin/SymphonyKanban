import Foundation

public struct SymphonyCodexConnectionGateway: SymphonyCodexConnectionPortProtocol {
    struct CommandResult: Equatable, Sendable {
        let terminationStatus: Int32
        let standardOutput: String
        let standardError: String
    }

    typealias CommandRunner = @Sendable (_ executableURL: URL, _ arguments: [String]) -> CommandResult

    private let runCommand: CommandRunner

    public init() {
        self.runCommand = Self.liveRunCommand
    }

    init(
        runCommand: @escaping CommandRunner
    ) {
        self.runCommand = runCommand
    }

    public func queryStatus(
        using resolution: SymphonyCodexCommandResolutionContract
    ) -> SymphonyCodexConnectionStatusContract {
        guard let executablePath = resolution.executablePath else {
            return SymphonyCodexConnectionStatusContract(
                state: .cliUnavailable,
                command: resolution.effectiveCommand,
                executableName: resolution.executableName,
                statusMessage: "Codex CLI could not be resolved from the login shell PATH.",
                detailMessage: nil
            )
        }

        let loginResult = runCommand(
            URL(fileURLWithPath: executablePath),
            ["login", "status"]
        )
        let loginMessage = combinedMessage(from: loginResult)

        guard loginResult.terminationStatus == 0,
              loginMessage.localizedCaseInsensitiveContains("logged in") else {
            return SymphonyCodexConnectionStatusContract(
                state: .notAuthenticated,
                command: resolution.effectiveCommand,
                executableName: resolution.executableName,
                executablePath: executablePath,
                statusMessage: "Codex CLI is installed, but the local Codex session is not authenticated.",
                detailMessage: loginMessage
            )
        }

        let appServerResult = runCommand(
            URL(fileURLWithPath: executablePath),
            ["app-server", "--help"]
        )

        guard appServerResult.terminationStatus == 0 else {
            return SymphonyCodexConnectionStatusContract(
                state: .appServerUnavailable,
                command: resolution.effectiveCommand,
                executableName: resolution.executableName,
                executablePath: executablePath,
                statusMessage: "Codex CLI is authenticated, but the app-server command is unavailable.",
                detailMessage: nonEmptyMessage(from: appServerResult)
            )
        }

        return SymphonyCodexConnectionStatusContract(
            state: .connected,
            command: resolution.effectiveCommand,
            executableName: resolution.executableName,
            executablePath: executablePath,
            statusMessage: "Codex is installed, authenticated, and ready for Symphony.",
            detailMessage: loginMessage
        )
    }

    private func combinedMessage(
        from result: CommandResult
    ) -> String {
        let parts = [result.standardOutput, result.standardError]
            .map(sanitizedOutput)
            .filter { $0.isEmpty == false }
        return parts.joined(separator: "\n")
    }

    private func nonEmptyMessage(
        from result: CommandResult
    ) -> String? {
        let message = combinedMessage(from: result)
        return message.isEmpty ? nil : message
    }

    private static func liveRunCommand(
        executableURL: URL,
        arguments: [String]
    ) -> CommandResult {
        let process = Process()
        let standardOutputPipe = Pipe()
        let standardErrorPipe = Pipe()

        process.executableURL = executableURL
        process.arguments = arguments
        process.standardOutput = standardOutputPipe
        process.standardError = standardErrorPipe

        do {
            try process.run()
        } catch {
            return CommandResult(
                terminationStatus: -1,
                standardOutput: "",
                standardError: error.localizedDescription
            )
        }

        process.waitUntilExit()

        let standardOutputData = standardOutputPipe.fileHandleForReading.readDataToEndOfFile()
        let standardErrorData = standardErrorPipe.fileHandleForReading.readDataToEndOfFile()

        return CommandResult(
            terminationStatus: process.terminationStatus,
            standardOutput: String(decoding: standardOutputData, as: UTF8.self),
            standardError: String(decoding: standardErrorData, as: UTF8.self)
        )
    }

    private func sanitizedOutput(
        _ value: String
    ) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
