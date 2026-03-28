import Foundation

public struct SymphonyCodexCommandResolverPortAdapter: SymphonyCodexCommandResolverPortProtocol {
    struct CommandResult: Equatable, Sendable {
        let terminationStatus: Int32
        let standardOutput: String
        let standardError: String
    }

    typealias CommandRunner = @Sendable (_ executableURL: URL, _ arguments: [String]) -> CommandResult
    typealias EnvironmentProvider = @Sendable () -> [String: String]

    private enum Defaults {
        static let command = "codex app-server"
        static let shellPath = "/bin/zsh"
    }

    private let workflowLoaderPort: any SymphonyWorkflowLoaderPortProtocol
    private let configResolverPort: any SymphonyConfigResolverPortProtocol
    private let environmentProvider: EnvironmentProvider
    private let runCommand: CommandRunner

    public init() {
        self.init(
            workflowLoaderPort: SymphonyWorkflowLoaderPortAdapter(),
            configResolverPort: SymphonyConfigResolverPortAdapter(),
            environmentProvider: { ProcessInfo.processInfo.environment },
            runCommand: Self.liveRunCommand
        )
    }

    init(
        workflowLoaderPort: any SymphonyWorkflowLoaderPortProtocol = SymphonyWorkflowLoaderPortAdapter(),
        configResolverPort: any SymphonyConfigResolverPortProtocol = SymphonyConfigResolverPortAdapter(),
        environmentProvider: @escaping EnvironmentProvider,
        runCommand: @escaping CommandRunner
    ) {
        self.workflowLoaderPort = workflowLoaderPort
        self.configResolverPort = configResolverPort
        self.environmentProvider = environmentProvider
        self.runCommand = runCommand
    }

    public func resolveCodexCommand(
        currentWorkingDirectoryPath: String,
        explicitWorkflowPath: String?
    ) -> SymphonyCodexCommandResolutionContract {
        let configuredCommand: String
        let configurationDetailMessage: String?

        do {
            let definition = try workflowLoaderPort.loadWorkflow(
                using: SymphonyWorkflowConfigurationRequestContract(
                    explicitWorkflowPath: explicitWorkflowPath,
                    currentWorkingDirectoryPath: currentWorkingDirectoryPath
                )
            )
            let serviceConfig = configResolverPort.resolveConfig(from: definition)
            let normalizedConfiguredCommand = SymphonyCodexCommandLineModel(
                configuredCommand: serviceConfig.codex.command,
                shellPath: nil
            )
            .configuredCommand
            if normalizedConfiguredCommand.isEmpty {
                configuredCommand = Defaults.command
                configurationDetailMessage = "Workflow config resolved an empty `codex.command`, so Symphony used the default command `\(Defaults.command)`."
            } else {
                configuredCommand = normalizedConfiguredCommand
                configurationDetailMessage = nil
            }
        } catch {
            configuredCommand = Defaults.command
            configurationDetailMessage = "Workflow config could not be resolved, so Symphony used the default command `\(Defaults.command)`."
        }

        return resolveEffectiveCommand(
            configuredCommand: configuredCommand,
            currentWorkingDirectoryPath: currentWorkingDirectoryPath,
            shellPath: environmentProvider()["SHELL"],
            configurationDetailMessage: configurationDetailMessage
        )
    }

    private func resolveEffectiveCommand(
        configuredCommand: String,
        currentWorkingDirectoryPath: String,
        shellPath: String?,
        configurationDetailMessage: String?
    ) -> SymphonyCodexCommandResolutionContract {
        let commandLine = SymphonyCodexCommandLineModel(
            configuredCommand: configuredCommand,
            shellPath: shellPath
        )

        if let absoluteExecutablePath = commandLine.absoluteExecutablePath {
            return SymphonyCodexCommandResolutionContract(
                configuredCommand: configuredCommand,
                effectiveCommand: configuredCommand,
                executableName: commandLine.executableName,
                executablePath: absoluteExecutablePath,
                detailMessage: configurationDetailMessage
            )
        }

        let lookupResult = runCommand(
            URL(fileURLWithPath: commandLine.shellPath),
            ["-lc", commandLine.shellLookupCommand]
        )
        guard lookupResult.terminationStatus == 0 else {
            return SymphonyCodexCommandResolutionContract(
                configuredCommand: configuredCommand,
                effectiveCommand: configuredCommand,
                executableName: commandLine.executableName,
                executablePath: nil,
                detailMessage: mergedDetailMessage(
                    configurationDetailMessage,
                    unresolvedExecutableMessage(
                        executableToken: commandLine.executableToken,
                        shellPath: commandLine.shellPath,
                        commandResult: lookupResult
                    )
                )
            )
        }

        let resolvedExecutablePath = commandLine.normalizedResolvedExecutablePath(
            from: sanitizedOutput(lookupResult.standardOutput),
            currentWorkingDirectoryPath: currentWorkingDirectoryPath
        )
        guard let resolvedExecutablePath else {
            return SymphonyCodexCommandResolutionContract(
                configuredCommand: configuredCommand,
                effectiveCommand: configuredCommand,
                executableName: commandLine.executableName,
                executablePath: nil,
                detailMessage: mergedDetailMessage(
                    configurationDetailMessage,
                    unresolvedExecutableMessage(
                        executableToken: commandLine.executableToken,
                        shellPath: commandLine.shellPath,
                        commandResult: lookupResult
                    )
                )
            )
        }

        return SymphonyCodexCommandResolutionContract(
            configuredCommand: configuredCommand,
            effectiveCommand: commandLine.reconstructedCommand(with: resolvedExecutablePath),
            executableName: commandLine.executableName,
            executablePath: resolvedExecutablePath,
            detailMessage: configurationDetailMessage
        )
    }

    private func unresolvedExecutableMessage(
        executableToken: String,
        shellPath: String,
        commandResult: CommandResult
    ) -> String {
        let detail = combinedMessage(from: commandResult)
        if detail.isEmpty {
            return "The configured executable `\(executableToken)` could not be resolved from the login shell PATH using `\(shellPath)`."
        }

        return "The configured executable `\(executableToken)` could not be resolved from the login shell PATH using `\(shellPath)`. \(detail)"
    }

    private func mergedDetailMessage(
        _ existing: String?,
        _ note: String
    ) -> String {
        guard let existing,
              existing.isEmpty == false else {
            return note
        }

        return "\(existing)\n\n\(note)"
    }

    private func combinedMessage(
        from result: CommandResult
    ) -> String {
        let parts = [result.standardOutput, result.standardError]
            .map(sanitizedOutput)
            .filter { $0.isEmpty == false }
        return parts.joined(separator: "\n")
    }

    private func sanitizedOutput(
        _ value: String
    ) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
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
}
