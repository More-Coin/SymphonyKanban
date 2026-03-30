import Testing
@testable import SymphonyKanban

@Suite
struct SymphonyWorkspaceBindingResolutionServiceTests {
    @Test
    func workspaceBindingResolutionReturnsSetupRequiredWhenBindingMissing() throws {
        let service = SymphonyWorkspaceBindingResolutionService(
            queryWorkspaceTrackerBindingsUseCase: QuerySymphonyWorkspaceTrackerBindingsUseCase(
                workspaceTrackerBindingPort: WorkspaceTrackerBindingPortSpy()
            )
        )

        let result = try service.resolveStartupContext(
            for: SymphonyWorkspaceLocatorContract(
                currentWorkingDirectoryPath: "/tmp/nara-ios",
                explicitWorkflowPath: "/tmp/nara-ios/WORKFLOW.md"
            )
        )

        #expect(
            result == .setupRequired(
                workspaceLocator: SymphonyWorkspaceLocatorContract(
                    currentWorkingDirectoryPath: "/tmp/nara-ios",
                    explicitWorkflowPath: "/tmp/nara-ios/WORKFLOW.md"
                )
            )
        )
    }

    @Test
    func workspaceBindingResolutionUsesLaunchWorkflowPathWhenProvided() throws {
        let binding = SymphonyWorkspaceTrackerBindingContract(
            workspacePath: "/tmp/nara-ios",
            explicitWorkflowPath: "/tmp/saved/WORKFLOW.md",
            trackerKind: "linear",
            scopeKind: "team",
            scopeIdentifier: "team-1",
            scopeName: "Nara IOS"
        )
        let service = SymphonyWorkspaceBindingResolutionService(
            queryWorkspaceTrackerBindingsUseCase: QuerySymphonyWorkspaceTrackerBindingsUseCase(
                workspaceTrackerBindingPort: WorkspaceTrackerBindingPortSpy(listedBindings: [binding])
            )
        )

        let result = try service.resolveStartupContext(
            for: SymphonyWorkspaceLocatorContract(
                currentWorkingDirectoryPath: "/tmp/nara-ios",
                explicitWorkflowPath: "/tmp/launch/WORKFLOW.md"
            )
        )

        guard case let .ready(activeBindings) = result,
              let resolvedBinding = activeBindings.first else {
            Issue.record("Expected ready binding resolution outcome.")
            return
        }

        #expect(resolvedBinding.effectiveWorkspaceLocator.currentWorkingDirectoryPath == "/tmp/nara-ios")
        #expect(resolvedBinding.effectiveWorkspaceLocator.explicitWorkflowPath == "/tmp/launch/WORKFLOW.md")
        #expect(resolvedBinding.workspaceBinding == binding)
    }

    @Test
    func workspaceBindingResolutionUsesSavedWorkflowPathWhenLaunchDoesNotProvideOne() throws {
        let binding = SymphonyWorkspaceTrackerBindingContract(
            workspacePath: "/tmp/nara-server",
            explicitWorkflowPath: "/tmp/nara-server/WORKFLOW.md",
            trackerKind: "linear",
            scopeKind: "team",
            scopeIdentifier: "team-2",
            scopeName: "Nara Server"
        )
        let service = SymphonyWorkspaceBindingResolutionService(
            queryWorkspaceTrackerBindingsUseCase: QuerySymphonyWorkspaceTrackerBindingsUseCase(
                workspaceTrackerBindingPort: WorkspaceTrackerBindingPortSpy(listedBindings: [binding])
            )
        )

        let result = try service.resolveStartupContext(
            for: SymphonyWorkspaceLocatorContract(
                currentWorkingDirectoryPath: "/tmp/nara-server",
                explicitWorkflowPath: nil
            )
        )

        guard case let .ready(activeBindings) = result,
              let resolvedBinding = activeBindings.first else {
            Issue.record("Expected ready binding resolution outcome.")
            return
        }

        #expect(resolvedBinding.effectiveWorkspaceLocator.explicitWorkflowPath == "/tmp/nara-server/WORKFLOW.md")
    }
}
