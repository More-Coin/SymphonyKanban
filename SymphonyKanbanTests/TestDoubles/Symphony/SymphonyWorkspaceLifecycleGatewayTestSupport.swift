import Foundation
@testable import SymphonyKanban

struct WorkspaceLifecycleTestEnvironment {
    let baseURL: URL
    let rootURL: URL

    init() {
        let uniqueID = UUID().uuidString
        baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SymphonyWorkspaceLifecycleGatewayTests-\(uniqueID)")
        rootURL = baseURL.appendingPathComponent("workspaces")

        try? FileManager.default.removeItem(at: baseURL)
        try? FileManager.default.createDirectory(
            at: rootURL,
            withIntermediateDirectories: true
        )
    }

    func serviceConfig(
        hooks: SymphonyServiceConfigContract.Hooks = .init(
            afterCreate: nil,
            beforeRun: nil,
            afterRun: nil,
            beforeRemove: nil,
            timeoutMs: 60000
        )
    ) -> SymphonyServiceConfigContract {
        SymphonyServiceConfigContract(
            tracker: .init(
                kind: "linear",
                endpoint: "https://api.linear.app/graphql",
                projectSlug: "project-slug",
                activeStates: ["Todo", "In Progress"],
                terminalStates: ["Done", "Canceled"]
            ),
            polling: .init(intervalMs: 30000),
            workspace: .init(rootPath: rootURL.path),
            hooks: hooks,
            agent: .init(
                maxConcurrentAgents: 10,
                maxTurns: 20,
                maxRetryBackoffMs: 300000,
                maxConcurrentAgentsByState: [:]
            ),
            codex: .init(
                command: "codex app-server",
                approvalPolicy: nil,
                threadSandbox: nil,
                turnSandboxPolicy: nil,
                turnTimeoutMs: 3600000,
                readTimeoutMs: 5000,
                stallTimeoutMs: 300000
            )
        )
    }

    func makeGateway(
        hookRunner: WorkspaceLifecycleHookRunnerSpy? = nil,
        logSink: @escaping @Sendable (String) -> Void = { _ in }
    ) -> SymphonyWorkspaceLifecycleGateway {
        SymphonyWorkspaceLifecycleGateway(
            fileManager: .default,
            currentWorkingDirectoryProvider: { self.baseURL.path },
            hookRunner: { [hookRunner] script, workingDirectoryPath, timeoutMs in
                if let hookRunner {
                    return try hookRunner.run(
                        script: script,
                        workingDirectoryPath: workingDirectoryPath,
                        timeoutMs: timeoutMs
                    )
                }

                return .success(
                    HookExecutionResultModel(
                        standardOutput: "",
                        standardError: ""
                    )
                )
            },
            logSink: logSink
        )
    }

    func makeArtifactDirectory(
        workspacePath: String,
        relativePath: String
    ) throws {
        try FileManager.default.createDirectory(
            at: URL(fileURLWithPath: workspacePath).appendingPathComponent(relativePath),
            withIntermediateDirectories: true
        )
    }
}

final class WorkspaceLifecycleHookRunnerSpy: @unchecked Sendable {
    struct Call: Equatable {
        let script: String
        let workingDirectoryPath: String
        let timeoutMs: Int
    }

    private var recordedCalls: [Call] = []
    private var queuedFailures: [HookExecutionFailureModel] = []

    func run(
        script: String,
        workingDirectoryPath: String,
        timeoutMs: Int
    ) throws -> HookExecutionOutcomeModel {
        recordedCalls.append(
            Call(
                script: script,
                workingDirectoryPath: workingDirectoryPath,
                timeoutMs: timeoutMs
            )
        )

        if !queuedFailures.isEmpty {
            return .failure(queuedFailures.removeFirst())
        }

        return .success(
            HookExecutionResultModel(
                standardOutput: "",
                standardError: ""
            )
        )
    }

    func enqueueFailure(
        _ failure: HookExecutionFailureModel
    ) {
        queuedFailures.append(failure)
    }

    func calls() -> [Call] {
        recordedCalls
    }
}

final class WorkspaceLifecycleLogSinkSpy: @unchecked Sendable {
    private var recordedMessages: [String] = []

    func record(_ message: String) {
        recordedMessages.append(message)
    }

    func messages() -> [String] {
        recordedMessages
    }
}
