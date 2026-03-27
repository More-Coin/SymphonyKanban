import Foundation
import Testing
@testable import SymphonyKanban

struct SymphonyWorkspaceLifecyclePreparationTests {
    @Test
    func prepareWorkspaceCreatesDeterministicPathRunsCreationAndBeforeRunHooks() throws {
        let environment = WorkspaceLifecycleTestEnvironment()
        let hookRunner = WorkspaceLifecycleHookRunnerSpy()
        let gateway = environment.makeGateway(hookRunner: hookRunner)

        let workspace = try gateway.prepareWorkspaceForAttempt(
            issueIdentifier: "ABC-123.feature name",
            using: environment.serviceConfig(
                hooks: .init(
                    afterCreate: "echo after create",
                    beforeRun: "echo before run",
                    afterRun: nil,
                    beforeRemove: nil,
                    timeoutMs: 2500
                )
            )
        )

        #expect(workspace.workspaceKey == SymphonyWorkspaceKey(value: "ABC-123.feature_name"))
        #expect(workspace.createdNow == true)
        #expect(workspace.path == environment.rootURL.appendingPathComponent("ABC-123.feature_name").path)
        #expect(FileManager.default.fileExists(atPath: workspace.path))
        #expect(hookRunner.calls() == [
            .init(
                script: "echo after create",
                workingDirectoryPath: workspace.path,
                timeoutMs: 2500
            ),
            .init(
                script: "echo before run",
                workingDirectoryPath: workspace.path,
                timeoutMs: 2500
            )
        ])
    }

    @Test
    func prepareWorkspaceReusesExistingDirectoryCleansArtifactsAndSkipsAfterCreate() throws {
        let environment = WorkspaceLifecycleTestEnvironment()
        let hookRunner = WorkspaceLifecycleHookRunnerSpy()
        let gateway = environment.makeGateway(hookRunner: hookRunner)
        let serviceConfig = environment.serviceConfig(
            hooks: .init(
                afterCreate: "echo after create",
                beforeRun: "echo before run",
                afterRun: nil,
                beforeRemove: nil,
                timeoutMs: 1500
            )
        )

        let initialWorkspace = try gateway.prepareWorkspaceForAttempt(
            issueIdentifier: "ABC-7",
            using: serviceConfig
        )
        try environment.makeArtifactDirectory(
            workspacePath: initialWorkspace.path,
            relativePath: "tmp"
        )
        try environment.makeArtifactDirectory(
            workspacePath: initialWorkspace.path,
            relativePath: ".elixir_ls"
        )

        let reusedWorkspace = try gateway.prepareWorkspaceForAttempt(
            issueIdentifier: "ABC-7",
            using: serviceConfig
        )

        #expect(reusedWorkspace.createdNow == false)
        #expect(!FileManager.default.fileExists(atPath: reusedWorkspace.path + "/tmp"))
        #expect(!FileManager.default.fileExists(atPath: reusedWorkspace.path + "/.elixir_ls"))
        #expect(hookRunner.calls().map(\.script) == [
            "echo after create",
            "echo before run",
            "echo before run"
        ])
    }

    @Test
    func prepareWorkspaceFailsWhenLocationAlreadyExistsAsAFile() throws {
        let environment = WorkspaceLifecycleTestEnvironment()
        let gateway = environment.makeGateway()
        let workspacePath = environment.rootURL.appendingPathComponent("ABC-9").path
        try "conflict".write(
            to: URL(fileURLWithPath: workspacePath),
            atomically: true,
            encoding: .utf8
        )

        do {
            _ = try gateway.prepareWorkspaceForAttempt(
                issueIdentifier: "ABC-9",
                using: environment.serviceConfig()
            )
            Issue.record("Expected a non-directory conflict error.")
        } catch let error as SymphonyWorkspaceInfrastructureError {
            guard case .workspaceLocationNotDirectory(let path) = error else {
                Issue.record("Expected workspaceLocationNotDirectory, received \(error).")
                return
            }

            #expect(path == workspacePath)
        }
    }

    @Test
    func prepareWorkspaceRejectsSymlinkEscapeOutsideWorkspaceRoot() throws {
        let environment = WorkspaceLifecycleTestEnvironment()
        let gateway = environment.makeGateway()
        let outsideURL = environment.baseURL.appendingPathComponent("outside")
        try FileManager.default.createDirectory(
            at: outsideURL,
            withIntermediateDirectories: true
        )
        let escapeTarget = outsideURL.appendingPathComponent("ABC-11")
        try FileManager.default.createDirectory(
            at: escapeTarget,
            withIntermediateDirectories: true
        )
        let symlinkPath = environment.rootURL.appendingPathComponent("ABC-11").path
        try FileManager.default.createSymbolicLink(
            atPath: symlinkPath,
            withDestinationPath: escapeTarget.path
        )

        do {
            _ = try gateway.prepareWorkspaceForAttempt(
                issueIdentifier: "ABC-11",
                using: environment.serviceConfig()
            )
            Issue.record("Expected a path-outside-root error.")
        } catch let error as SymphonyWorkspaceInfrastructureError {
            guard case .workspacePathOutsideRoot(let rootPath, let workspacePath) = error else {
                Issue.record("Expected workspacePathOutsideRoot, received \(error).")
                return
            }

            #expect(rootPath == environment.rootURL.path)
            #expect(workspacePath == escapeTarget.path)
        }
    }
}
