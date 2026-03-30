import Testing
@testable import SymphonyKanban

struct SymphonyIssueCatalogServiceTests {
    @Test
    func missingWorkflowResolutionFallsBackToMockIssues() async throws {
        let resolveWorkflowConfigurationUseCase = ResolveSymphonyWorkflowConfigurationUseCase(
            workflowLoaderPort: CodexCommandWorkflowLoaderSpy(
                loadError: SymphonyWorkflowInfrastructureError.missingWorkflowFile(path: "/tmp/missing")
            ),
            configResolverPort: CodexCommandConfigResolverSpy(
                serviceConfig: SymphonyServiceConfigContract(
                    tracker: SymphonyServiceConfigContract.Tracker(
                        kind: "linear",
                        endpoint: nil,
                        projectSlug: "project-slug",
                        activeStateTypes: ["backlog", "started"],
                        terminalStateTypes: ["completed", "canceled"]
                    ),
                    polling: .init(intervalMs: 30_000),
                    workspace: .init(rootPath: "/tmp/workspaces"),
                    hooks: .init(afterCreate: nil, beforeRun: nil, afterRun: nil, beforeRemove: nil, timeoutMs: 60_000),
                    agent: .init(maxConcurrentAgents: 10, maxTurns: 20, maxRetryBackoffMs: 300_000, maxConcurrentAgentsByState: [:]),
                    codex: .init(command: "codex app-server", approvalPolicy: nil, threadSandbox: nil, turnSandboxPolicy: nil, turnTimeoutMs: 3_600_000, readTimeoutMs: 5_000, stallTimeoutMs: 300_000)
                )
            )
        )
        let service = SymphonyIssueCatalogService(
            trackerConfigurationPort: SymphonyIssueCatalogTrackerConfigurationPortAdapter(
                resolveWorkflowConfigurationUseCase: resolveWorkflowConfigurationUseCase
            ),
            fetchIssuesUseCase: FetchSymphonyIssuesUseCase(
                issueTrackerReadPort: SymphonyMockIssueTrackerPortAdapter()
            )
        )

        let result = try await service.queryIssues(
            currentWorkingDirectoryPath: "/tmp/project"
        )

        #expect(result.issues.contains { $0.identifier == "KAN-142" })
    }

    @Test
    func resolvedWorkflowRequestsCombinedActiveAndTerminalStateTypes() async throws {
        let trackerSpy = IssueCatalogTrackerReadSpy()
        let resolveWorkflowConfigurationUseCase = ResolveSymphonyWorkflowConfigurationUseCase(
            workflowLoaderPort: CodexCommandWorkflowLoaderSpy(),
            configResolverPort: CodexCommandConfigResolverSpy(
                serviceConfig: SymphonyServiceConfigContract(
                    tracker: SymphonyServiceConfigContract.Tracker(
                        kind: "linear",
                        endpoint: nil,
                        projectSlug: "project-slug",
                        activeStateTypes: ["backlog", "started"],
                        terminalStateTypes: ["completed", "canceled"]
                    ),
                    polling: .init(intervalMs: 30_000),
                    workspace: .init(rootPath: "/tmp/workspaces"),
                    hooks: .init(afterCreate: nil, beforeRun: nil, afterRun: nil, beforeRemove: nil, timeoutMs: 60_000),
                    agent: .init(maxConcurrentAgents: 10, maxTurns: 20, maxRetryBackoffMs: 300_000, maxConcurrentAgentsByState: [:]),
                    codex: .init(command: "codex app-server", approvalPolicy: nil, threadSandbox: nil, turnSandboxPolicy: nil, turnTimeoutMs: 3_600_000, readTimeoutMs: 5_000, stallTimeoutMs: 300_000)
                )
            )
        )
        let service = SymphonyIssueCatalogService(
            trackerConfigurationPort: SymphonyIssueCatalogTrackerConfigurationPortAdapter(
                resolveWorkflowConfigurationUseCase: resolveWorkflowConfigurationUseCase
            ),
            fetchIssuesUseCase: FetchSymphonyIssuesUseCase(
                issueTrackerReadPort: trackerSpy
            )
        )

        _ = try await service.queryIssues(
            currentWorkingDirectoryPath: "/tmp/project"
        )

        #expect(await trackerSpy.recordedStateTypes() == ["backlog", "started", "completed", "canceled"])
    }
}

private actor IssueCatalogTrackerReadSpy: SymphonyIssueTrackerReadPortProtocol {
    private var recordedStateTypesValue: [String] = []

    func fetchCandidateIssues(
        using _: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        []
    }

    func fetchIssues(
        byStateTypes stateTypes: [String],
        using _: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        recordedStateTypesValue = stateTypes
        return []
    }

    func fetchIssueStates(
        byIDs _: [String],
        using _: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        []
    }

    func recordedStateTypes() -> [String] {
        recordedStateTypesValue
    }
}
