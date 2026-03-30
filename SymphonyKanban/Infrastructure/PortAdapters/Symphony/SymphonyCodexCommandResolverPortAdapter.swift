import Foundation

public struct SymphonyCodexCommandResolverPortAdapter: SymphonyCodexCommandResolverPortProtocol {
    struct CommandResult: Equatable, Sendable {
        let terminationStatus: Int32
        let standardOutput: String
        let standardError: String
    }

    private struct ShellLookupAttempt: Equatable, Sendable {
        let mode: ShellLookupMode
        let result: CommandResult
    }

    private enum ShellLookupMode: CaseIterable, Equatable, Sendable {
        case login
        case interactiveLogin
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
                using: SymphonyWorkspaceLocatorContract(
                    currentWorkingDirectoryPath: currentWorkingDirectoryPath,
                    explicitWorkflowPath: explicitWorkflowPath
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

        let shellLookup = resolveExecutablePath(
            for: commandLine,
            currentWorkingDirectoryPath: currentWorkingDirectoryPath
        )
        guard let resolvedExecutable = shellLookup.path else {
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
                        lookupCommand: commandLine.shellLookupCommand,
                        attempts: shellLookup.attempts
                    )
                )
            )
        }

        return SymphonyCodexCommandResolutionContract(
            configuredCommand: configuredCommand,
            effectiveCommand: commandLine.reconstructedCommand(with: resolvedExecutable),
            executableName: commandLine.executableName,
            executablePath: resolvedExecutable,
            detailMessage: configurationDetailMessage
        )
    }

    private func unresolvedExecutableMessage(
        executableToken: String,
        shellPath: String,
        lookupCommand: String,
        attempts: [ShellLookupAttempt]
    ) -> String {
        let detail = combinedMessage(from: attempts)
        if detail.isEmpty == false {
            return "The configured executable `\(executableToken)` could not be resolved using `\(shellPath) -lc` or `\(shellPath) -ilc` with `\(lookupCommand)`. \(detail)"
        }

        return "The configured executable `\(executableToken)` could not be resolved from the login shell PATH or the interactive login shell PATH using `\(shellPath)`."
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
        from attempts: [ShellLookupAttempt]
    ) -> String {
        let details: [String] = attempts.compactMap { attempt in
            let message = [attempt.result.standardOutput, attempt.result.standardError]
                .map(sanitizedOutput)
                .filter { $0.isEmpty == false }
                .joined(separator: "\n")
            guard message.isEmpty == false else {
                return nil
            }

            switch attempt.mode {
            case .login:
                return "Login shell lookup output:\n\(message)"
            case .interactiveLogin:
                return "Interactive login shell lookup output:\n\(message)"
            }
        }
        return details.joined(separator: "\n\n")
    }

    private func sanitizedOutput(
        _ value: String
    ) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func resolveExecutablePath(
        for commandLine: SymphonyCodexCommandLineModel,
        currentWorkingDirectoryPath: String
    ) -> (path: String?, attempts: [ShellLookupAttempt]) {
        let executableURL = URL(fileURLWithPath: commandLine.shellPath)
        var attempts: [ShellLookupAttempt] = []

        for mode in ShellLookupMode.allCases {
            let attempt = ShellLookupAttempt(
                mode: mode,
                result: runCommand(
                    executableURL,
                    lookupArguments(
                        for: mode,
                        lookupCommand: commandLine.shellLookupCommand
                    )
                )
            )
            attempts.append(attempt)

            guard attempt.result.terminationStatus == 0 else {
                continue
            }

            if let resolvedPath = commandLine.normalizedResolvedExecutablePath(
                from: sanitizedOutput(attempt.result.standardOutput),
                currentWorkingDirectoryPath: currentWorkingDirectoryPath
            ) {
                return (resolvedPath, attempts)
            }
        }

        return (nil, attempts)
    }

    private func lookupArguments(
        for mode: ShellLookupMode,
        lookupCommand: String
    ) -> [String] {
        switch mode {
        case .login:
            return ["-lc", lookupCommand]
        case .interactiveLogin:
            return ["-ilc", lookupCommand]
        }
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
