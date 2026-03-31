import Testing
@testable import SymphonyKanban

struct ValidateSymphonyStartupConfigurationPortAdapterTests {
    @Test
    func validateAcceptsLinearTeamScopeWithoutProjectSlug() throws {
        let adapter = ValidateSymphonyStartupConfigurationPortAdapter()

        try adapter.validate(
            SymphonyServiceConfigContract(
                tracker: .init(
                    kind: "linear",
                    endpoint: nil,
                    projectSlug: nil,
                    teamID: "team-ios",
                    activeStateTypes: [],
                    terminalStateTypes: []
                ),
                polling: .init(intervalMs: 30_000),
                workspace: .init(rootPath: "/tmp/workspaces"),
                hooks: .init(afterCreate: nil, beforeRun: nil, afterRun: nil, beforeRemove: nil, timeoutMs: 60_000),
                agent: .init(maxConcurrentAgents: 10, maxTurns: 20, maxRetryBackoffMs: 300_000, maxConcurrentAgentsByState: [:]),
                codex: .init(command: "codex app-server", approvalPolicy: nil, threadSandbox: nil, turnSandboxPolicy: nil, turnTimeoutMs: 3_600_000, readTimeoutMs: 5_000, stallTimeoutMs: 300_000)
            )
        )
    }

    @Test
    func validateRejectsLinearTrackerWithoutProjectOrTeamScope() {
        let adapter = ValidateSymphonyStartupConfigurationPortAdapter()

        do {
            try adapter.validate(
                SymphonyServiceConfigContract(
                    tracker: .init(
                        kind: "linear",
                        endpoint: nil,
                        projectSlug: nil,
                        teamID: nil,
                        activeStateTypes: [],
                        terminalStateTypes: []
                    ),
                    polling: .init(intervalMs: 30_000),
                    workspace: .init(rootPath: "/tmp/workspaces"),
                    hooks: .init(afterCreate: nil, beforeRun: nil, afterRun: nil, beforeRemove: nil, timeoutMs: 60_000),
                    agent: .init(maxConcurrentAgents: 10, maxTurns: 20, maxRetryBackoffMs: 300_000, maxConcurrentAgentsByState: [:]),
                    codex: .init(command: "codex app-server", approvalPolicy: nil, threadSandbox: nil, turnSandboxPolicy: nil, turnTimeoutMs: 3_600_000, readTimeoutMs: 5_000, stallTimeoutMs: 300_000)
                )
            )
            Issue.record("Expected missing tracker scope identifier validation failure.")
        } catch let error as SymphonyStartupApplicationError {
            #expect(error == .missingTrackerScopeIdentifier)
        } catch {
            Issue.record("Expected startup validation error, received \(error).")
        }
    }

    @Test
    func validateRejectsLinearTrackerWhenProjectAndTeamAreBothPresent() {
        let adapter = ValidateSymphonyStartupConfigurationPortAdapter()

        do {
            try adapter.validate(
                SymphonyServiceConfigContract(
                    tracker: .init(
                        kind: "linear",
                        endpoint: nil,
                        projectSlug: "mobile-rebuild",
                        teamID: "team-ios",
                        activeStateTypes: [],
                        terminalStateTypes: []
                    ),
                    polling: .init(intervalMs: 30_000),
                    workspace: .init(rootPath: "/tmp/workspaces"),
                    hooks: .init(afterCreate: nil, beforeRun: nil, afterRun: nil, beforeRemove: nil, timeoutMs: 60_000),
                    agent: .init(maxConcurrentAgents: 10, maxTurns: 20, maxRetryBackoffMs: 300_000, maxConcurrentAgentsByState: [:]),
                    codex: .init(command: "codex app-server", approvalPolicy: nil, threadSandbox: nil, turnSandboxPolicy: nil, turnTimeoutMs: 3_600_000, readTimeoutMs: 5_000, stallTimeoutMs: 300_000)
                )
            )
            Issue.record("Expected ambiguous tracker scope validation failure.")
        } catch let error as SymphonyStartupApplicationError {
            #expect(error == .ambiguousTrackerScopeIdentifier)
        } catch {
            Issue.record("Expected startup validation error, received \(error).")
        }
    }
}
