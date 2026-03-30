import Foundation
import Testing
@testable import SymphonyKanban

@Suite
struct SymphonyWorkspaceSelectionServiceTests {
    @Test
    func selectWorkspaceResolvesDefaultWorkflowPathForChosenFolder() throws {
        let workspaceURL = SymphonyStartupFlowTestSupport.temporaryDirectory()
        let workflowURL = workspaceURL.appendingPathComponent("WORKFLOW.md", isDirectory: false)
        try """
        ---
        tracker:
          kind: linear
          project_slug: mobile-rebuild
        ---
        Prompt body.
        """.write(to: workflowURL, atomically: true, encoding: .utf8)

        let service = SymphonyWorkspaceSelectionService(
            resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase(
                workflowLoaderPort: SymphonyWorkflowLoaderPortAdapter(environment: [:]),
                configResolverPort: SymphonyConfigResolverPortAdapter(environment: [:])
            )
        )

        let result = try service.selectWorkspace(
            workspacePath: workspaceURL.path
        )

        #expect(result.workspaceLocator.currentWorkingDirectoryPath == workspaceURL.path)
        #expect(result.workspaceLocator.explicitWorkflowPath == nil)
        #expect(result.resolvedWorkflowPath == workflowURL.path)
    }

    @Test
    func selectWorkspaceRejectsBlankWorkspacePath() {
        let service = SymphonyWorkspaceSelectionService(
            resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase(
                workflowLoaderPort: SymphonyWorkflowLoaderPortAdapter(environment: [:]),
                configResolverPort: SymphonyConfigResolverPortAdapter(environment: [:])
            )
        )

        #expect(throws: SymphonyWorkspaceSelectionApplicationError.missingWorkspacePath) {
            try service.selectWorkspace(workspacePath: "   ")
        }
    }
}
