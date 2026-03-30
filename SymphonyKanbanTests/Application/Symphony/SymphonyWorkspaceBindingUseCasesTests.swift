import Testing
@testable import SymphonyKanban

struct SymphonyWorkspaceBindingUseCasesTests {
    @Test
    func resolveUseCaseDelegatesToBindingPort() throws {
        let binding = SymphonyWorkspaceTrackerBindingContract(
            workspacePath: "/tmp/nara-ios",
            explicitWorkflowPath: "/tmp/nara-ios/WORKFLOW.md",
            trackerKind: "linear",
            scopeKind: "team",
            scopeIdentifier: "team-ios",
            scopeName: "Nara IOS"
        )
        let portSpy = WorkspaceTrackerBindingPortSpy(
            resolvedBinding: binding
        )
        let useCase = ResolveSymphonyWorkspaceTrackerBindingUseCase(
            workspaceTrackerBindingPort: portSpy
        )

        let result = try useCase.resolve(
            for: SymphonyWorkspaceLocatorContract(
                currentWorkingDirectoryPath: "/tmp/nara-ios",
                explicitWorkflowPath: "/tmp/nara-ios/WORKFLOW.md"
            )
        )

        #expect(result == binding)
        #expect(portSpy.resolveCallCount == 1)
    }

    @Test
    func queryUseCaseReturnsAllBindingsFromPort() throws {
        let bindings = [
            SymphonyWorkspaceTrackerBindingContract(
                workspacePath: "/tmp/nara-ios",
                explicitWorkflowPath: nil,
                trackerKind: "linear",
                scopeKind: "team",
                scopeIdentifier: "team-ios",
                scopeName: "Nara IOS"
            ),
            SymphonyWorkspaceTrackerBindingContract(
                workspacePath: "/tmp/nara-server",
                explicitWorkflowPath: nil,
                trackerKind: "linear",
                scopeKind: "team",
                scopeIdentifier: "team-server",
                scopeName: "Nara Server"
            )
        ]
        let portSpy = WorkspaceTrackerBindingPortSpy(
            listedBindings: bindings
        )
        let useCase = QuerySymphonyWorkspaceTrackerBindingsUseCase(
            workspaceTrackerBindingPort: portSpy
        )

        let result = try useCase.queryBindings()

        #expect(result == bindings)
        #expect(portSpy.listCallCount == 1)
    }

    @Test
    func saveUseCasePersistsBindingThroughPort() throws {
        let portSpy = WorkspaceTrackerBindingPortSpy()
        let useCase = SaveSymphonyWorkspaceTrackerBindingUseCase(
            workspaceTrackerBindingPort: portSpy
        )
        let binding = SymphonyWorkspaceTrackerBindingContract(
            workspacePath: "/tmp/nara-ios",
            explicitWorkflowPath: "/tmp/nara-ios/WORKFLOW.md",
            trackerKind: "linear",
            scopeKind: "team",
            scopeIdentifier: "team-ios",
            scopeName: "Nara IOS"
        )

        let result = try useCase.save(binding)

        #expect(result == binding)
        #expect(portSpy.savedBindings == [binding])
    }

    @Test
    func removeUseCaseRemovesBindingThroughPort() throws {
        let portSpy = WorkspaceTrackerBindingPortSpy()
        let useCase = RemoveSymphonyWorkspaceTrackerBindingUseCase(
            workspaceTrackerBindingPort: portSpy
        )

        let result = try useCase.removeBinding(forWorkspacePath: "/tmp/nara-ios")

        #expect(result == SymphonyWorkspaceTrackerBindingRemovalResultContract(workspacePath: "/tmp/nara-ios"))
        #expect(portSpy.removedWorkspacePaths == ["/tmp/nara-ios"])
    }
}
