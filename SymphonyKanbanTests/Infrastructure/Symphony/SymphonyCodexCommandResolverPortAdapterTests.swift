import Foundation
import Testing
@testable import SymphonyKanban

private final class ShellInvocationRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var recordedInvocations: [[String]] = []

    func append(_ arguments: [String]) {
        lock.lock()
        recordedInvocations.append(arguments)
        lock.unlock()
    }

    func snapshot() -> [[String]] {
        lock.lock()
        defer { lock.unlock() }
        return recordedInvocations
    }
}

private final class ShellInvocationCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var currentValue = 0

    func nextValue() -> Int {
        lock.lock()
        defer {
            currentValue += 1
            lock.unlock()
        }
        return currentValue
    }

    func value() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return currentValue
    }
}

struct SymphonyCodexCommandResolverPortAdapterTests {
    @Test
    func resolveCodexCommandResolvesConfiguredExecutableFromLoginShellPath() {
        let invocations = ShellInvocationRecorder()
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
                invocations.append(arguments)
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
        #expect(invocations.snapshot() == [["-lc", "command -v 'codex'"]])
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
        let invocations = ShellInvocationRecorder()
        let adapter = SymphonyCodexCommandResolverPortAdapter(
            workflowLoaderPort: CodexCommandWorkflowLoaderSpy(),
            configResolverPort: CodexCommandConfigResolverSpy(
                serviceConfig: SymphonyCodexCommandTestSupport.makeServiceConfig(
                    command: "codex app-server"
                )
            ),
            environmentProvider: { ["SHELL": "/bin/zsh"] },
            runCommand: { _, arguments in
                invocations.append(arguments)
                return .init(
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
        #expect(result.detailMessage?.contains("/bin/zsh -lc") == true)
        #expect(result.detailMessage?.contains("/bin/zsh -ilc") == true)
        #expect(result.detailMessage?.contains("codex not found") == true)
        #expect(
            invocations.snapshot() == [
                ["-lc", "command -v 'codex'"],
                ["-ilc", "command -v 'codex'"]
            ]
        )
    }

    @Test
    func resolveCodexCommandFallsBackToInteractiveLoginShellWhenLoginShellCannotResolveExecutable() {
        let invocationCounter = ShellInvocationCounter()
        let adapter = SymphonyCodexCommandResolverPortAdapter(
            workflowLoaderPort: CodexCommandWorkflowLoaderSpy(),
            configResolverPort: CodexCommandConfigResolverSpy(
                serviceConfig: SymphonyCodexCommandTestSupport.makeServiceConfig(
                    command: "codex app-server"
                )
            ),
            environmentProvider: { ["SHELL": "/bin/zsh"] },
            runCommand: { _, arguments in
                let invocationIndex = invocationCounter.nextValue()
                if invocationIndex == 0 {
                    #expect(arguments == ["-lc", "command -v 'codex'"])
                    return .init(
                        terminationStatus: 1,
                        standardOutput: "",
                        standardError: "not found in login shell"
                    )
                }

                #expect(arguments == ["-ilc", "command -v 'codex'"])
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

        #expect(invocationCounter.value() == 2)
        #expect(result.effectiveCommand == "/opt/homebrew/bin/codex app-server")
        #expect(result.executablePath == "/opt/homebrew/bin/codex")
        #expect(result.detailMessage == nil)
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
