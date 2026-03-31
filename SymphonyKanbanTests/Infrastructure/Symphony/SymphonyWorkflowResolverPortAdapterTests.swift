import Foundation
import Testing
@testable import SymphonyKanban

struct SymphonyWorkflowResolverPortAdapterTests {
    @Test
    func missingWorkflowFileReturnsTypedError() {
        let useCase = SymphonyWorkflowConfigurationTestSupport.makeUseCase()
        let request = SymphonyWorkspaceLocatorContract(
            currentWorkingDirectoryPath: SymphonyWorkflowConfigurationTestSupport.temporaryDirectory().path,
            explicitWorkflowPath: "/path/that/does/not/exist/WORKFLOW.md"
        )

        do {
            _ = try useCase.resolve(request)
            Issue.record("Expected missing workflow file error.")
        } catch let error as SymphonyWorkflowInfrastructureError {
            switch error {
            case .missingWorkflowFile(let path):
                #expect(path == "/path/that/does/not/exist/WORKFLOW.md")
                #expect(error.code == "symphony.workflow.missing_workflow_file")
            default:
                Issue.record("Unexpected workflow error: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func invalidYAMLReturnsTypedError() throws {
        let fileURL = try SymphonyWorkflowConfigurationTestSupport.makeWorkflowFile(
            named: "InvalidYAML.md",
            contents: """
            ---
            tracker:
              kind: [linear
            ---
            Broken YAML.
            """
        )

        let useCase = SymphonyWorkflowConfigurationTestSupport.makeUseCase()
        let request = SymphonyWorkspaceLocatorContract(
            currentWorkingDirectoryPath: SymphonyWorkflowConfigurationTestSupport.temporaryDirectory().path,
            explicitWorkflowPath: fileURL.path
        )

        do {
            _ = try useCase.resolve(request)
            Issue.record("Expected workflow parse error.")
        } catch let error as SymphonyWorkflowInfrastructureError {
            switch error {
            case .workflowParseError(let details):
                #expect(!details.isEmpty)
                #expect(error.code == "symphony.workflow.workflow_parse_error")
            default:
                Issue.record("Unexpected workflow error: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func nonMapFrontMatterReturnsTypedError() throws {
        let fileURL = try SymphonyWorkflowConfigurationTestSupport.makeWorkflowFile(
            named: "ArrayFrontMatter.md",
            contents: """
            ---
            - linear
            - todo
            ---
            Prompt body.
            """
        )

        let useCase = SymphonyWorkflowConfigurationTestSupport.makeUseCase()
        let request = SymphonyWorkspaceLocatorContract(
            currentWorkingDirectoryPath: SymphonyWorkflowConfigurationTestSupport.temporaryDirectory().path,
            explicitWorkflowPath: fileURL.path
        )

        do {
            _ = try useCase.resolve(request)
            Issue.record("Expected non-map front matter error.")
        } catch let error as SymphonyWorkflowInfrastructureError {
            switch error {
            case .workflowFrontMatterNotAMap:
                #expect(error.code == "symphony.workflow.workflow_front_matter_not_a_map")
            default:
                Issue.record("Unexpected workflow error: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func resolverAppliesBuiltInDefaultsAcrossTheCoreSurface() throws {
        let fileURL = try SymphonyWorkflowConfigurationTestSupport.makeWorkflowFile(
            named: "DefaultConfig.md",
            contents: """
            ---
            tracker:
              kind: linear
            ---
            Prompt body.
            """
        )

        let useCase = SymphonyWorkflowConfigurationTestSupport.makeUseCase()
        let result = try useCase.resolve(
            SymphonyWorkspaceLocatorContract(
            currentWorkingDirectoryPath: SymphonyWorkflowConfigurationTestSupport.temporaryDirectory().path,
            explicitWorkflowPath: fileURL.path
        )
        )

        let defaultWorkspaceRoot = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("symphony_workspaces")
            .standardizedFileURL
            .path

        #expect(result.serviceConfig.tracker.kind == "linear")
        #expect(result.serviceConfig.tracker.endpoint == "https://api.linear.app/graphql")
        #expect(result.serviceConfig.tracker.projectSlug == nil)
        #expect(result.serviceConfig.tracker.teamID == nil)
        #expect(result.serviceConfig.tracker.activeStateTypes == ["backlog", "unstarted", "started"])
        #expect(result.serviceConfig.tracker.terminalStateTypes == ["completed", "canceled"])
        #expect(result.serviceConfig.polling.intervalMs == 30000)
        #expect(result.serviceConfig.workspace.rootPath == defaultWorkspaceRoot)
        #expect(result.serviceConfig.hooks.afterCreate == nil)
        #expect(result.serviceConfig.hooks.beforeRun == nil)
        #expect(result.serviceConfig.hooks.afterRun == nil)
        #expect(result.serviceConfig.hooks.beforeRemove == nil)
        #expect(result.serviceConfig.hooks.timeoutMs == 60000)
        #expect(result.serviceConfig.agent.maxConcurrentAgents == 10)
        #expect(result.serviceConfig.agent.maxTurns == 20)
        #expect(result.serviceConfig.agent.maxRetryBackoffMs == 300000)
        #expect(result.serviceConfig.agent.maxConcurrentAgentsByState.isEmpty)
        #expect(result.serviceConfig.codex.command == "codex app-server")
        #expect(result.serviceConfig.codex.approvalPolicy == nil)
        #expect(result.serviceConfig.codex.threadSandbox == nil)
        #expect(result.serviceConfig.codex.turnSandboxPolicy == nil)
        #expect(result.serviceConfig.codex.turnTimeoutMs == 3600000)
        #expect(result.serviceConfig.codex.readTimeoutMs == 5000)
        #expect(result.serviceConfig.codex.stallTimeoutMs == 300000)
    }

    @Test
    func trackerEndpointDefaultsOnlyWhenTrackerKindIsLinear() throws {
        let fileURL = try SymphonyWorkflowConfigurationTestSupport.makeWorkflowFile(
            named: "NonLinearEndpointDefault.md",
            contents: """
            ---
            tracker:
              kind: jira
            ---
            Prompt body.
            """
        )

        let useCase = SymphonyWorkflowConfigurationTestSupport.makeUseCase()
        let result = try useCase.resolve(
            SymphonyWorkspaceLocatorContract(
            currentWorkingDirectoryPath: SymphonyWorkflowConfigurationTestSupport.temporaryDirectory().path,
            explicitWorkflowPath: fileURL.path
        )
        )

        #expect(result.serviceConfig.tracker.kind == "jira")
        #expect(result.serviceConfig.tracker.endpoint == nil)
        #expect(result.serviceConfig.tracker.teamID == nil)
    }

    @Test
    func resolverMapsTeamIDFromWorkflowFrontMatter() throws {
        let fileURL = try SymphonyWorkflowConfigurationTestSupport.makeWorkflowFile(
            named: "TeamScopeConfig.md",
            contents: """
            ---
            tracker:
              kind: linear
              team_id: team-ios
            ---
            Prompt body.
            """
        )

        let useCase = SymphonyWorkflowConfigurationTestSupport.makeUseCase()
        let result = try useCase.resolve(
            SymphonyWorkspaceLocatorContract(
                currentWorkingDirectoryPath: SymphonyWorkflowConfigurationTestSupport.temporaryDirectory().path,
                explicitWorkflowPath: fileURL.path
            )
        )

        #expect(result.serviceConfig.tracker.projectSlug == nil)
        #expect(result.serviceConfig.tracker.teamID == "team-ios")
    }

    @Test
    func resolverCoversTheFullCoreSurfaceAndPassThroughFields() throws {
        let fileURL = try SymphonyWorkflowConfigurationTestSupport.makeWorkflowFile(
            named: "FullTypedConfig.md",
            contents: """
            ---
            tracker:
              kind: linear
              endpoint: https://example.invalid/graphql
              project_slug: symphony
              active_state_types:
                - backlog
                - started
              terminal_state_types:
                - completed
                - canceled
            polling:
              interval_ms: "45000"
            workspace:
              root: $WORKSPACE_ROOT
            hooks:
              after_create: |
                echo after create
              before_run: |
                echo before run
              after_run: |
                echo after run
              before_remove: |
                echo before remove
              timeout_ms: -1
            agent:
              max_concurrent_agents: "12"
              max_turns: "25"
              max_retry_backoff_ms: "900000"
              max_concurrent_agents_by_state:
                Todo: "3"
                In Progress: 2
                InvalidZero: "0"
                InvalidText: nope
            codex:
              command: "$CODEX_COMMAND"
              approval_policy: on-request
              thread_sandbox: workspace-write
              turn_sandbox_policy:
                mode: workspace-write
                network_access: restricted
              turn_timeout_ms: "7200000"
              read_timeout_ms: "7000"
              stall_timeout_ms: 0
            server:
              port: 4000
            ---
            Prompt body.
            """
        )

        let workspaceRoot = SymphonyWorkflowConfigurationTestSupport.temporaryDirectory().appendingPathComponent("workspace-root").path
        let useCase = SymphonyWorkflowConfigurationTestSupport.makeUseCase(
            environment: [
                "WORKSPACE_ROOT": workspaceRoot,
                "CODEX_COMMAND": "codex app-server --profile dev"
            ]
        )
        let result = try useCase.resolve(
            SymphonyWorkspaceLocatorContract(
            currentWorkingDirectoryPath: SymphonyWorkflowConfigurationTestSupport.temporaryDirectory().path,
            explicitWorkflowPath: fileURL.path
        )
        )

        #expect(result.serviceConfig.tracker.kind == "linear")
        #expect(result.serviceConfig.tracker.endpoint == "https://example.invalid/graphql")
        #expect(result.serviceConfig.tracker.projectSlug == "symphony")
        #expect(result.serviceConfig.tracker.teamID == nil)
        #expect(result.serviceConfig.tracker.activeStateTypes == ["backlog", "started"])
        #expect(result.serviceConfig.tracker.terminalStateTypes == ["completed", "canceled"])
        #expect(result.serviceConfig.polling.intervalMs == 45000)
        #expect(
            result.serviceConfig.workspace.rootPath ==
                URL(fileURLWithPath: workspaceRoot).standardizedFileURL.path
        )
        #expect(result.serviceConfig.hooks.afterCreate?.contains("echo after create") == true)
        #expect(result.serviceConfig.hooks.beforeRun?.contains("echo before run") == true)
        #expect(result.serviceConfig.hooks.afterRun?.contains("echo after run") == true)
        #expect(result.serviceConfig.hooks.beforeRemove?.contains("echo before remove") == true)
        #expect(result.serviceConfig.hooks.timeoutMs == 60000)
        #expect(result.serviceConfig.agent.maxConcurrentAgents == 12)
        #expect(result.serviceConfig.agent.maxTurns == 25)
        #expect(result.serviceConfig.agent.maxRetryBackoffMs == 900000)
        #expect(
            result.serviceConfig.agent.maxConcurrentAgentsByState == [
                "todo": 3,
                "in progress": 2
            ]
        )
        #expect(result.serviceConfig.codex.command == "$CODEX_COMMAND")
        #expect(result.serviceConfig.codex.approvalPolicy == "on-request")
        #expect(result.serviceConfig.codex.threadSandbox == "workspace-write")
        #expect(
            result.serviceConfig.codex.turnSandboxPolicy ==
                SymphonyConfigValueContract.object([
                    "mode": .string("workspace-write"),
                    "network_access": .string("restricted")
                ])
        )
        #expect(result.serviceConfig.codex.turnTimeoutMs == 7200000)
        #expect(result.serviceConfig.codex.readTimeoutMs == 7000)
        #expect(result.serviceConfig.codex.stallTimeoutMs == 0)
    }

    @Test
    func resolverAppliesPathExpansionOnlyToFilesystemPathValues() throws {
        let fileURL = try SymphonyWorkflowConfigurationTestSupport.makeWorkflowFile(
            named: "PathExpansionBoundaries.md",
            contents: """
            ---
            tracker:
              kind: linear
              endpoint: $LINEAR_ENDPOINT
              project_slug: project
            workspace:
              root: $WORKSPACE_ROOT
            codex:
              command: $CODEX_COMMAND
            ---
            Prompt body.
            """
        )

        let workspaceRoot = SymphonyWorkflowConfigurationTestSupport.temporaryDirectory().appendingPathComponent("expanded-root").path
        let useCase = SymphonyWorkflowConfigurationTestSupport.makeUseCase(
            environment: [
                "LINEAR_ENDPOINT": "https://env.invalid/graphql",
                "WORKSPACE_ROOT": workspaceRoot,
                "CODEX_COMMAND": "codex app-server --profile env"
            ]
        )
        let result = try useCase.resolve(
            SymphonyWorkspaceLocatorContract(
            currentWorkingDirectoryPath: SymphonyWorkflowConfigurationTestSupport.temporaryDirectory().path,
            explicitWorkflowPath: fileURL.path
        )
        )

        #expect(result.serviceConfig.tracker.endpoint == "$LINEAR_ENDPOINT")
        #expect(
            result.serviceConfig.workspace.rootPath ==
                URL(fileURLWithPath: workspaceRoot).standardizedFileURL.path
        )
        #expect(result.serviceConfig.codex.command == "$CODEX_COMMAND")
    }

    @Test
    func workspaceRootPreservesBareRelativeNamesWithoutPathSeparators() throws {
        let fileURL = try SymphonyWorkflowConfigurationTestSupport.makeWorkflowFile(
            named: "BareRelativeWorkspaceRoot.md",
            contents: """
            ---
            tracker:
              kind: linear
            workspace:
              root: symphony_workspaces
            ---
            Prompt body.
            """
        )

        let useCase = SymphonyWorkflowConfigurationTestSupport.makeUseCase()
        let result = try useCase.resolve(
            SymphonyWorkspaceLocatorContract(
            currentWorkingDirectoryPath: SymphonyWorkflowConfigurationTestSupport.temporaryDirectory().path,
            explicitWorkflowPath: fileURL.path
        )
        )

        #expect(result.serviceConfig.workspace.rootPath == "symphony_workspaces")
    }

    @Test
    func workspaceRootExpandsTildeToTheHomeDirectory() throws {
        let fileURL = try SymphonyWorkflowConfigurationTestSupport.makeWorkflowFile(
            named: "TildeWorkspaceRoot.md",
            contents: """
            ---
            tracker:
              kind: linear
            workspace:
              root: ~/symphony-workspaces
            ---
            Prompt body.
            """
        )

        let useCase = SymphonyWorkflowConfigurationTestSupport.makeUseCase()
        let result = try useCase.resolve(
            SymphonyWorkspaceLocatorContract(
            currentWorkingDirectoryPath: SymphonyWorkflowConfigurationTestSupport.temporaryDirectory().path,
            explicitWorkflowPath: fileURL.path
        )
        )

        let expectedPath = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("symphony-workspaces")
            .standardizedFileURL
            .path
        #expect(result.serviceConfig.workspace.rootPath == expectedPath)
    }

    @Test
    func legacyAPIKeyInputIsIgnoredDuringResolution() throws {
        let fileURL = try SymphonyWorkflowConfigurationTestSupport.makeWorkflowFile(
            named: "EnvAPIKey.md",
            contents: """
            ---
            tracker:
              kind: linear
              api_key: $LINEAR_API_KEY
            ---
            Prompt body.
            """
        )

        let useCase = SymphonyWorkflowConfigurationTestSupport.makeUseCase(
            environment: [
                "LINEAR_API_KEY": ""
            ]
        )
        let result = try useCase.resolve(
            SymphonyWorkspaceLocatorContract(
            currentWorkingDirectoryPath: SymphonyWorkflowConfigurationTestSupport.temporaryDirectory().path,
            explicitWorkflowPath: fileURL.path
        )
        )

        #expect(result.serviceConfig.tracker.kind == "linear")
        #expect(result.serviceConfig.tracker.endpoint == "https://api.linear.app/graphql")
    }
}
