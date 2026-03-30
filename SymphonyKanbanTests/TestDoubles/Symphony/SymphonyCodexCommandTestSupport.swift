import Foundation
@testable import SymphonyKanban

enum SymphonyCodexCommandTestSupport {
    static func makeServiceConfig(command: String) -> SymphonyServiceConfigContract {
        SymphonyServiceConfigContract(
            tracker: .init(
                kind: "linear",
                endpoint: "https://api.linear.app/graphql",
                projectSlug: "test-project",
                activeStateTypes: ["backlog"],
                terminalStateTypes: ["completed"]
            ),
            polling: .init(intervalMs: 30000),
            workspace: .init(rootPath: "/tmp/workspaces"),
            hooks: .init(
                afterCreate: nil,
                beforeRun: nil,
                afterRun: nil,
                beforeRemove: nil,
                timeoutMs: 60000
            ),
            agent: .init(
                maxConcurrentAgents: 10,
                maxTurns: 20,
                maxRetryBackoffMs: 300000,
                maxConcurrentAgentsByState: [:]
            ),
            codex: .init(
                command: command,
                approvalPolicy: nil,
                threadSandbox: nil,
                turnSandboxPolicy: nil,
                turnTimeoutMs: 3600000,
                readTimeoutMs: 5000,
                stallTimeoutMs: 300000
            )
        )
    }
}

enum SymphonyCodexCommandTestError: Error {
    case workflowLoadFailed
}

struct CodexCommandWorkflowLoaderSpy: SymphonyWorkflowLoaderPortProtocol {
    let definition: SymphonyWorkflowDefinitionContract?
    let loadError: Error?

    init(
        definition: SymphonyWorkflowDefinitionContract? = nil,
        loadError: Error? = nil
    ) {
        self.definition = definition
        self.loadError = loadError
    }

    func loadWorkflow(
        using workspaceLocator: SymphonyWorkspaceLocatorContract
    ) throws -> SymphonyWorkflowDefinitionContract {
        if let loadError {
            throw loadError
        }

        return definition ?? SymphonyWorkflowDefinitionContract(
            resolvedPath: workspaceLocator.explicitWorkflowPath ?? "\(workspaceLocator.currentWorkingDirectoryPath)/WORKFLOW.md",
            config: [:],
            promptTemplate: "Prompt body"
        )
    }
}

struct CodexCommandConfigResolverSpy: SymphonyConfigResolverPortProtocol {
    let serviceConfig: SymphonyServiceConfigContract

    func resolveConfig(
        from definition: SymphonyWorkflowDefinitionContract
    ) -> SymphonyServiceConfigContract {
        serviceConfig
    }
}
