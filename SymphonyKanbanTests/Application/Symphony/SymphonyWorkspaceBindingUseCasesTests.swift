import Foundation
import Testing
@testable import SymphonyKanban

@Suite
struct SymphonyWorkspaceBindingUseCasesTests {
    @Test
    func saveWorkspaceTrackerBindingUseCasePersistsSelectedScopeAndStartupResolvesIt() throws {
        let rootURL = SymphonyStartupFlowTestSupport.temporaryDirectory()
        let workspaceURL = rootURL.appendingPathComponent("Workspace", isDirectory: true)
        try FileManager.default.createDirectory(
            at: workspaceURL,
            withIntermediateDirectories: true
        )
        let workflowURL = workspaceURL.appendingPathComponent("WORKFLOW.md", isDirectory: false)
        try """
        ---
        tracker:
          kind: linear
          project_slug: mobile-rebuild
        ---
        Prompt body.
        """.write(to: workflowURL, atomically: true, encoding: .utf8)

        let repository = SymphonyWorkspaceTrackerBindingRepository(
            storageURL: rootURL.appendingPathComponent("workspace-bindings.json", isDirectory: false)
        )
        let saveBindingUseCase = SaveSymphonyWorkspaceTrackerBindingUseCase(
            workspaceTrackerBindingPort: repository
        )

        let savedBinding = try saveBindingUseCase.save(
            SymphonyWorkspaceTrackerBindingContract(
                workspacePath: workspaceURL.path,
                explicitWorkflowPath: workflowURL.path,
                trackerKind: "linear",
                scopeKind: "project",
                scopeIdentifier: "mobile-rebuild",
                scopeName: "Mobile Rebuild"
            )
        )
        let startupService = SymphonyStartupFlowTestSupport.makeStartupService(
            workspaceTrackerBindingPort: repository
        )

        let result = try startupService.execute(
            SymphonyWorkspaceLocatorContract(
                currentWorkingDirectoryPath: workspaceURL.path,
                explicitWorkflowPath: workflowURL.path
            )
        )

        #expect(savedBinding.scopeIdentifier == "mobile-rebuild")
        #expect(result.result.state == .ready)
        #expect(result.activeBindings.first?.workspaceBinding.scopeIdentifier == "mobile-rebuild")
        #expect(result.activeBindings.first?.workspaceBinding.scopeName == "Mobile Rebuild")
    }
}
