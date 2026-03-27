import Foundation

public struct SymphonyWorkspaceLifecycleGateway: SymphonyWorkspaceLifecyclePortProtocol {
    public typealias LogSink = @Sendable (String) -> Void

    public typealias HookRunner = @Sendable (
        _ script: String,
        _ workingDirectoryPath: String,
        _ timeoutMs: Int
    ) throws -> HookExecutionOutcomeModel

    private enum HookKind: String {
        case afterCreate = "after_create"
        case beforeRun = "before_run"
        case afterRun = "after_run"
        case beforeRemove = "before_remove"
    }

    private let fileManager: FileManager
    private let workspaceKeyPolicy: SymphonyWorkspaceKeyPolicy
    private let workspacePathModel: SymphonyWorkspacePathModel
    private let hookScriptModel: SymphonyHookScriptModel
    private let currentWorkingDirectoryProvider: @Sendable () -> String
    private let hookRunner: HookRunner
    private let logSink: LogSink
    private let logOutputLimit: Int

    public init(
        fileManager: FileManager = .default,
        workspaceKeyPolicy: SymphonyWorkspaceKeyPolicy = SymphonyWorkspaceKeyPolicy(),
        currentWorkingDirectoryProvider: @escaping @Sendable () -> String = {
            FileManager.default.currentDirectoryPath
        },
        hookRunner: @escaping HookRunner = { script, workingDirectoryPath, timeoutMs in
            try Self.defaultHookRunner(
                script: script,
                workingDirectoryPath: workingDirectoryPath,
                timeoutMs: timeoutMs
            )
        },
        logSink: @escaping LogSink = { _ in },
        logOutputLimit: Int = 120
    ) {
        self.fileManager = fileManager
        self.workspaceKeyPolicy = workspaceKeyPolicy
        self.workspacePathModel = SymphonyWorkspacePathModel()
        self.hookScriptModel = SymphonyHookScriptModel()
        self.currentWorkingDirectoryProvider = currentWorkingDirectoryProvider
        self.hookRunner = hookRunner
        self.logSink = logSink
        self.logOutputLimit = logOutputLimit
    }

    public func prepareWorkspaceForAttempt(
        issueIdentifier: String,
        using serviceConfig: SymphonyServiceConfigContract
    ) throws -> SymphonyWorkspaceContract {
        let rootPath = try workspacePathModel.fromContract(
            using: serviceConfig.workspace,
            currentWorkingDirectoryPath: currentWorkingDirectoryProvider()
        )
        let workspace = try createOrReuseWorkspace(
            issueIdentifier: issueIdentifier,
            rootPath: rootPath
        )

        try cleanupPreparationArtifacts(in: workspace.path)

        if workspace.createdNow {
            try runHookIfConfigured(
                script: serviceConfig.hooks.afterCreate,
                kind: .afterCreate,
                workspacePath: workspace.path,
                timeoutMs: serviceConfig.hooks.timeoutMs,
                trackerAPIKey: serviceConfig.tracker.apiKey,
                fatalOnFailure: true
            )
        }

        try runHookIfConfigured(
            script: serviceConfig.hooks.beforeRun,
            kind: .beforeRun,
            workspacePath: workspace.path,
            timeoutMs: serviceConfig.hooks.timeoutMs,
            trackerAPIKey: serviceConfig.tracker.apiKey,
            fatalOnFailure: true
        )

        return workspace
    }

    public func completeRunAttempt(
        in workspace: SymphonyWorkspaceContract,
        using serviceConfig: SymphonyServiceConfigContract
    ) -> SymphonyRunAttemptCompletionContract {
        let rootPath = try? workspacePathModel.fromContract(
            using: serviceConfig.workspace,
            currentWorkingDirectoryPath: currentWorkingDirectoryProvider()
        )
        let workspacePath = rootPath.flatMap {
            try? self.validatedWorkspacePath(
                at: workspace.path,
                under: $0
            )
        } ?? workspace.path

        logAndIgnoreHook(
            script: serviceConfig.hooks.afterRun,
            kind: .afterRun,
            workspacePath: workspacePath,
            timeoutMs: serviceConfig.hooks.timeoutMs,
            trackerAPIKey: serviceConfig.tracker.apiKey
        )

        return SymphonyRunAttemptCompletionContract(workspacePath: workspacePath)
    }

    public func cleanupWorkspace(
        for issueIdentifier: String,
        using serviceConfig: SymphonyServiceConfigContract
    ) throws -> SymphonyWorkspaceCleanupContract {
        let rootPath = try workspacePathModel.fromContract(
            using: serviceConfig.workspace,
            currentWorkingDirectoryPath: currentWorkingDirectoryProvider()
        )
        let workspaceKey = workspaceKeyPolicy.makeWorkspaceKey(from: issueIdentifier)
        let workspacePath = derivedWorkspacePath(
            rootPath: rootPath,
            workspaceKey: workspaceKey
        )

        guard fileManager.fileExists(atPath: workspacePath) else {
            return SymphonyWorkspaceCleanupContract(
                workspacePath: workspacePath,
                removed: false
            )
        }

        let validatedWorkspacePath = try validatedWorkspacePath(
            at: workspacePath,
            under: rootPath
        )

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: validatedWorkspacePath, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw SymphonyWorkspaceInfrastructureError.workspaceLocationNotDirectory(
                path: validatedWorkspacePath
            )
        }

        logAndIgnoreHook(
            script: serviceConfig.hooks.beforeRemove,
            kind: .beforeRemove,
            workspacePath: validatedWorkspacePath,
            timeoutMs: serviceConfig.hooks.timeoutMs,
            trackerAPIKey: serviceConfig.tracker.apiKey
        )

        do {
            try fileManager.removeItem(atPath: validatedWorkspacePath)
        } catch {
            throw SymphonyWorkspaceInfrastructureError.workspaceRemovalFailed(
                path: validatedWorkspacePath,
                details: error.localizedDescription
            )
        }

        return SymphonyWorkspaceCleanupContract(
            workspacePath: validatedWorkspacePath,
            removed: true
        )
    }

    public func validateCurrentWorkingDirectory(
        _ currentWorkingDirectoryPath: String,
        for workspace: SymphonyWorkspaceContract,
        using serviceConfig: SymphonyServiceConfigContract
    ) throws -> String {
        let rootPath = try workspacePathModel.fromContract(
            using: serviceConfig.workspace,
            currentWorkingDirectoryPath: currentWorkingDirectoryProvider()
        )
        let workspacePath = try validatedWorkspacePath(
            at: workspace.path,
            under: rootPath
        )
        let currentWorkingDirectory = workspacePathModel.toAbsolutePath(
            from: currentWorkingDirectoryPath,
            currentWorkingDirectoryPath: currentWorkingDirectoryProvider()
        )

        guard currentWorkingDirectory == workspacePath else {
            throw SymphonyWorkspaceInfrastructureError.invalidWorkspaceCWD(
                expected: workspacePath,
                actual: currentWorkingDirectory
            )
        }

        return workspacePath
    }

    public static func defaultHookRunner(
        script: String,
        workingDirectoryPath: String,
        timeoutMs: Int
    ) throws -> HookExecutionOutcomeModel {
        #if os(macOS)
        let process = Process()
        let standardOutputPipe = Pipe()
        let standardErrorPipe = Pipe()
        let executionGroup = DispatchGroup()

        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-lc", script]
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectoryPath, isDirectory: true)
        process.standardOutput = standardOutputPipe
        process.standardError = standardErrorPipe
        process.terminationHandler = { _ in
            executionGroup.leave()
        }

        executionGroup.enter()

        do {
            try process.run()
        } catch {
            executionGroup.leave()
            throw error
        }

        let waitResult = executionGroup.wait(timeout: .now() + .milliseconds(timeoutMs))
        if waitResult == .timedOut {
            process.terminate()
            _ = executionGroup.wait(timeout: .now() + .seconds(1))
            let result = HookExecutionResultModel.from(
                standardOutputPipe: standardOutputPipe,
                standardErrorPipe: standardErrorPipe
            )
            return .failure(.timedOut(output: result.combinedOutput))
        }

        let result = HookExecutionResultModel.from(
            standardOutputPipe: standardOutputPipe,
            standardErrorPipe: standardErrorPipe
        )

        guard process.terminationStatus == 0 else {
            return .failure(.failed(
                exitCode: process.terminationStatus,
                output: result.combinedOutput
            ))
        }

        return .success(result)
        #else
        return .failure(
            .failed(
                exitCode: -1,
                output: "Workspace lifecycle hooks require macOS process execution support."
            )
        )
        #endif
    }

    private func createOrReuseWorkspace(
        issueIdentifier: String,
        rootPath: String
    ) throws -> SymphonyWorkspaceContract {
        try ensureDirectoryExists(at: rootPath, errorBuilder: {
            SymphonyWorkspaceInfrastructureError.invalidWorkspaceRoot(path: $0)
        })

        let workspaceKey = workspaceKeyPolicy.makeWorkspaceKey(from: issueIdentifier)
        let workspacePath = derivedWorkspacePath(
            rootPath: rootPath,
            workspaceKey: workspaceKey
        )

        guard isContained(
            candidatePath: workspacePathModel.toResolvedPath(from: workspacePath),
            within: rootPath
        ) else {
            throw SymphonyWorkspaceInfrastructureError.workspacePathOutsideRoot(
                rootPath: rootPath,
                workspacePath: workspacePathModel.toResolvedPath(from: workspacePath)
            )
        }

        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: workspacePath, isDirectory: &isDirectory) {
            guard isDirectory.boolValue else {
                throw SymphonyWorkspaceInfrastructureError.workspaceLocationNotDirectory(
                    path: workspacePath
                )
            }

            return SymphonyWorkspaceContract(
                path: workspacePath,
                workspaceKey: workspaceKey,
                createdNow: false
            )
        }

        do {
            try fileManager.createDirectory(
                atPath: workspacePath,
                withIntermediateDirectories: true
            )
        } catch {
            throw SymphonyWorkspaceInfrastructureError.workspaceCreationFailed(
                path: workspacePath,
                details: error.localizedDescription
            )
        }

        return SymphonyWorkspaceContract(
            path: workspacePath,
            workspaceKey: workspaceKey,
            createdNow: true
        )
    }

    private func cleanupPreparationArtifacts(
        in workspacePath: String
    ) throws {
        for relativePath in ["tmp", ".elixir_ls"] {
            let artifactPath = URL(fileURLWithPath: workspacePath, isDirectory: true)
                .appendingPathComponent(relativePath)
                .path

            guard fileManager.fileExists(atPath: artifactPath) else {
                continue
            }

            do {
                try fileManager.removeItem(atPath: artifactPath)
            } catch {
                throw SymphonyWorkspaceInfrastructureError.workspacePreparationFailed(
                    path: workspacePath,
                    details: "Failed to remove preparation artifact `\(relativePath)`: \(error.localizedDescription)"
                )
            }
        }
    }

    private func runHookIfConfigured(
        script: String?,
        kind: HookKind,
        workspacePath: String,
        timeoutMs: Int,
        trackerAPIKey: String?,
        fatalOnFailure: Bool
    ) throws {
        guard let script = hookScriptModel.normalizedConfigHookScript(script) else {
            return
        }

        logSink(
            "symphony.workspace.hook event=start kind=\(kind.rawValue) workspace=\(workspacePath)"
        )

        do {
            let result = try hookRunner(script, workspacePath, timeoutMs)
            if case .failure(let error) = result {
                let infrastructureError = error.toInfrastructureError(
                    kind: kind.rawValue,
                    workspacePath: workspacePath,
                    timeoutMs: timeoutMs
                )
                logSink(makeHookFailureLog(
                    error: infrastructureError,
                    trackerAPIKey: trackerAPIKey,
                    output: error.output
                ))

                if fatalOnFailure {
                    throw infrastructureError
                }
            }
        } catch {
            let infrastructureError = SymphonyWorkspaceInfrastructureError.hookFailed(
                kind: kind.rawValue,
                workspacePath: workspacePath,
                details: error.localizedDescription
            )
            logSink(makeHookFailureLog(
                error: infrastructureError,
                trackerAPIKey: trackerAPIKey,
                output: nil
            ))

            if fatalOnFailure {
                throw infrastructureError
            }
        }
    }

    private func logAndIgnoreHook(
        script: String?,
        kind: HookKind,
        workspacePath: String,
        timeoutMs: Int,
        trackerAPIKey: String?
    ) {
        do {
            try runHookIfConfigured(
                script: script,
                kind: kind,
                workspacePath: workspacePath,
                timeoutMs: timeoutMs,
                trackerAPIKey: trackerAPIKey,
                fatalOnFailure: false
            )
        } catch {
            // Fatal behavior is disabled for best-effort hooks.
        }
    }

    private func makeHookFailureLog(
        error: SymphonyWorkspaceInfrastructureError,
        trackerAPIKey: String?,
        output: String?
    ) -> String {
        let redactedOutput = redactedAndTruncatedOutput(
            output,
            trackerAPIKey: trackerAPIKey
        )

        if let redactedOutput, !redactedOutput.isEmpty {
            return "symphony.workspace.hook event=failure code=\(error.code) details=\"\(error.details ?? "")\" output=\"\(redactedOutput)\""
        }

        return "symphony.workspace.hook event=failure code=\(error.code) details=\"\(error.details ?? "")\""
    }

    private func derivedWorkspacePath(
        rootPath: String,
        workspaceKey: SymphonyWorkspaceKey
    ) -> String {
        URL(fileURLWithPath: rootPath, isDirectory: true)
            .appendingPathComponent(workspaceKey.value)
            .standardizedFileURL
            .path
    }

    private func validatedWorkspacePath(
        at workspacePath: String,
        under rootPath: String
    ) throws -> String {
        let absoluteWorkspacePath = workspacePathModel.toAbsolutePath(
            from: workspacePath,
            currentWorkingDirectoryPath: currentWorkingDirectoryProvider()
        )
        let resolvedWorkspacePath = workspacePathModel.toResolvedPath(from: absoluteWorkspacePath)

        guard isContained(candidatePath: resolvedWorkspacePath, within: rootPath) else {
            throw SymphonyWorkspaceInfrastructureError.workspacePathOutsideRoot(
                rootPath: rootPath,
                workspacePath: resolvedWorkspacePath
            )
        }

        return absoluteWorkspacePath
    }

    private func isContained(candidatePath: String, within rootPath: String) -> Bool {
        candidatePath == rootPath || candidatePath.hasPrefix(rootPath + "/")
    }

    private func ensureDirectoryExists(
        at path: String,
        errorBuilder: (String) -> SymphonyWorkspaceInfrastructureError
    ) throws {
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: path, isDirectory: &isDirectory) {
            guard isDirectory.boolValue else {
                throw errorBuilder(path)
            }
            return
        }

        do {
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
        } catch {
            throw SymphonyWorkspaceInfrastructureError.workspaceCreationFailed(
                path: path,
                details: error.localizedDescription
            )
        }
    }

    private func redactedAndTruncatedOutput(
        _ output: String?,
        trackerAPIKey: String?
    ) -> String? {
        guard let output = output?
            .replacingOccurrences(of: "\n", with: "\\n")
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !output.isEmpty else {
            return nil
        }

        let redactedOutput: String
        if let trackerAPIKey, !trackerAPIKey.isEmpty {
            redactedOutput = output.replacingOccurrences(
                of: trackerAPIKey,
                with: "[REDACTED]"
            )
        } else {
            redactedOutput = output
        }

        guard redactedOutput.count > logOutputLimit else {
            return redactedOutput
        }

        let endIndex = redactedOutput.index(
            redactedOutput.startIndex,
            offsetBy: logOutputLimit
        )
        return String(redactedOutput[..<endIndex]) + "..."
    }
}
