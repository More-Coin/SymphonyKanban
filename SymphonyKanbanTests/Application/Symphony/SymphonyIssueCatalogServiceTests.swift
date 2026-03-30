import Testing
@testable import SymphonyKanban

struct SymphonyIssueCatalogServiceTests {
    @Test
    func readyBindingLoadsIssuesFromConfiguredTrackerSource() async throws {
        let service = SymphonyIssueCatalogService(
            fetchIssuesUseCase: FetchSymphonyIssuesUseCase(
                issueTrackerReadPort: SymphonyMockIssueTrackerPortAdapter()
            )
        )
        let activeBinding = makeActiveBindingContext()

        let result = try await service.queryIssues(
            activeBindings: [activeBinding]
        )

        #expect(result.issues.contains { $0.identifier == "KAN-142" })
        #expect(result.bindingResults.count == 1)
        #expect(result.loadedBindingCount == 1)
    }

    @Test
    func readyBindingRequestsCombinedActiveAndTerminalStateTypes() async throws {
        let trackerSpy = IssueCatalogTrackerReadSpy()
        let service = SymphonyIssueCatalogService(
            fetchIssuesUseCase: FetchSymphonyIssuesUseCase(
                issueTrackerReadPort: trackerSpy
            )
        )

        _ = try await service.queryIssues(
            activeBindings: [makeActiveBindingContext()]
        )

        #expect(await trackerSpy.recordedStateTypes() == ["backlog", "started", "completed", "canceled"])
    }

    @Test
    func failedBindingIsCarriedAsPartialFailureWithoutThrowing() async throws {
        let service = SymphonyIssueCatalogService(
            fetchIssuesUseCase: FetchSymphonyIssuesUseCase(
                issueTrackerReadPort: SymphonyMockIssueTrackerPortAdapter()
            )
        )

        let result = try await service.queryIssues(
            activeBindings: [
                SymphonyActiveWorkspaceBindingContextContract(
                    workspaceBinding: SymphonyStartupFlowTestSupport.makeWorkspaceBinding(
                        workspacePath: "/tmp/project"
                    ),
                    effectiveWorkspaceLocator: SymphonyWorkspaceLocatorContract(
                        currentWorkingDirectoryPath: "/tmp/project",
                        explicitWorkflowPath: nil
                    ),
                    startupFailure: SymphonyFailureSummaryContract(
                        message: "Binding failed."
                    )
                )
            ]
        )

        #expect(result.issues.isEmpty)
        #expect(result.failedBindingCount == 1)
        #expect(result.bindingResults.first?.loadState == .failed)
        #expect(result.bindingResults.first?.loadError?.message == "Binding failed.")
    }
}

private func makeActiveBindingContext() -> SymphonyActiveWorkspaceBindingContextContract {
    let workflowConfiguration = SymphonyWorkflowConfigurationResultContract(
        workflowDefinition: SymphonyWorkflowDefinitionContract(
            resolvedPath: "/tmp/project/WORKFLOW.md",
            config: [:],
            promptTemplate: "Prompt body."
        ),
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

    return SymphonyActiveWorkspaceBindingContextContract(
        workspaceBinding: SymphonyStartupFlowTestSupport.makeWorkspaceBinding(
            workspacePath: "/tmp/project",
            scopeName: "Nara IOS"
        ),
        effectiveWorkspaceLocator: SymphonyWorkspaceLocatorContract(
            currentWorkingDirectoryPath: "/tmp/project",
            explicitWorkflowPath: "/tmp/project/WORKFLOW.md"
        ),
        workflowConfiguration: workflowConfiguration,
        trackerAuthStatus: SymphonyTrackerAuthStatusContract(
            trackerKind: "linear",
            state: .connected,
            statusMessage: "Connected to Linear."
        )
    )
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
