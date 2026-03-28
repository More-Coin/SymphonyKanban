import Testing
@testable import SymphonyKanban

struct SymphonyCodexCommandResolverPortAdapterTests {
    @Test
    func resolveCodexCommandResolvesConfiguredExecutableFromLoginShellPath() {
        let adapter = SymphonyCodexCommandResolverPortAdapter(
            workflowLoaderPort: CodexCommandWorkflowLoaderSpy(
                definition: SymphonyWorkflowDefinitionContract(
                    resolvedPath: "/tmp/project/WORKFLOW.md",
                    config: [:],
                    promptTemplate: "Prompt body"
                )
            ),
            configResolverPort: CodexCommandConfigResolverSpy(
                serviceConfig: SymphonyCodexCommandTestSupport.makeServiceConfig(
                    command: "codex app-server --listen stdio://"
                )
            ),
            environmentProvider: { ["SHELL": "/bin/zsh"] },
            runCommand: { executableURL, arguments in
                #expect(executableURL.path == "/bin/zsh")
                #expect(arguments == ["-lc", "command -v 'codex'"])
                return .init(
                    terminationStatus: 0,
                    standardOutput: "/opt/homebrew/bin/codex\n",
                    standardError: ""
                )
            }
        )

        let result = adapter.resolveCodexCommand(
            currentWorkingDirectoryPath: "/tmp/project",
            explicitWorkflowPath: "/tmp/project/WORKFLOW.md"
        )

        #expect(result.configuredCommand == "codex app-server --listen stdio://")
        #expect(result.effectiveCommand == "/opt/homebrew/bin/codex app-server --listen stdio://")
        #expect(result.executableName == "codex")
        #expect(result.executablePath == "/opt/homebrew/bin/codex")
        #expect(result.detailMessage == nil)
    }

    @Test
    func resolveCodexCommandPreservesAlreadyAbsoluteExecutableCommand() {
        let adapter = SymphonyCodexCommandResolverPortAdapter(
            workflowLoaderPort: CodexCommandWorkflowLoaderSpy(),
            configResolverPort: CodexCommandConfigResolverSpy(
                serviceConfig: SymphonyCodexCommandTestSupport.makeServiceConfig(
                    command: "/opt/homebrew/bin/codex app-server"
                )
            ),
            environmentProvider: { ["SHELL": "/bin/zsh"] },
            runCommand: { _, _ in
                Issue.record("Shell lookup should not run for an absolute executable command.")
                return .init(terminationStatus: 1, standardOutput: "", standardError: "unexpected")
            }
        )

        let result = adapter.resolveCodexCommand(
            currentWorkingDirectoryPath: "/tmp/project",
            explicitWorkflowPath: nil
        )

        #expect(result.configuredCommand == "/opt/homebrew/bin/codex app-server")
        #expect(result.effectiveCommand == "/opt/homebrew/bin/codex app-server")
        #expect(result.executablePath == "/opt/homebrew/bin/codex")
        #expect(result.detailMessage == nil)
    }

    @Test
    func resolveCodexCommandFallsBackToDefaultCommandWhenWorkflowLoadFails() {
        let adapter = SymphonyCodexCommandResolverPortAdapter(
            workflowLoaderPort: CodexCommandWorkflowLoaderSpy(
                loadError: SymphonyCodexCommandTestError.workflowLoadFailed
            ),
            configResolverPort: CodexCommandConfigResolverSpy(
                serviceConfig: SymphonyCodexCommandTestSupport.makeServiceConfig(
                    command: "unused"
                )
            ),
            environmentProvider: { ["SHELL": "/bin/zsh"] },
            runCommand: { _, _ in
                .init(
                    terminationStatus: 0,
                    standardOutput: "/opt/homebrew/bin/codex\n",
                    standardError: ""
                )
            }
        )

        let result = adapter.resolveCodexCommand(
            currentWorkingDirectoryPath: "/tmp/project",
            explicitWorkflowPath: nil
        )

        #expect(result.configuredCommand == "codex app-server")
        #expect(result.effectiveCommand == "/opt/homebrew/bin/codex app-server")
        #expect(result.detailMessage?.contains("default command") == true)
    }

    @Test
    func resolveCodexCommandReturnsDiagnosticWhenExecutableCannotBeResolvedFromLoginShell() {
        let adapter = SymphonyCodexCommandResolverPortAdapter(
            workflowLoaderPort: CodexCommandWorkflowLoaderSpy(),
            configResolverPort: CodexCommandConfigResolverSpy(
                serviceConfig: SymphonyCodexCommandTestSupport.makeServiceConfig(
                    command: "codex app-server"
                )
            ),
            environmentProvider: { ["SHELL": "/bin/zsh"] },
            runCommand: { _, _ in
                .init(
                    terminationStatus: 1,
                    standardOutput: "",
                    standardError: "codex not found"
                )
            }
        )

        let result = adapter.resolveCodexCommand(
            currentWorkingDirectoryPath: "/tmp/project",
            explicitWorkflowPath: nil
        )

        #expect(result.effectiveCommand == "codex app-server")
        #expect(result.executablePath == nil)
        #expect(result.detailMessage?.contains("login shell PATH") == true)
        #expect(result.detailMessage?.contains("codex not found") == true)
    }

    @Test
    func resolveCodexCommandFallsBackToZshWhenShellEnvironmentIsMissing() {
        let adapter = SymphonyCodexCommandResolverPortAdapter(
            workflowLoaderPort: CodexCommandWorkflowLoaderSpy(),
            configResolverPort: CodexCommandConfigResolverSpy(
                serviceConfig: SymphonyCodexCommandTestSupport.makeServiceConfig(
                    command: "codex app-server"
                )
            ),
            environmentProvider: { [:] },
            runCommand: { executableURL, _ in
                #expect(executableURL.path == "/bin/zsh")
                return .init(
                    terminationStatus: 0,
                    standardOutput: "/opt/homebrew/bin/codex\n",
                    standardError: ""
                )
            }
        )

        let result = adapter.resolveCodexCommand(
            currentWorkingDirectoryPath: "/tmp/project",
            explicitWorkflowPath: nil
        )

        #expect(result.executablePath == "/opt/homebrew/bin/codex")
    }
}
