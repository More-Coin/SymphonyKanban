import Foundation
import Testing
@testable import SymphonyKanban

@MainActor
@Suite
struct SymphonyWorkspaceSelectionControllerTests {
    @Test
    func selectWorkspaceReturnsSelectedViewModelForValidWorkspace() throws {
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

        let controller = SymphonyWorkspaceSelectionController(
            workspaceSelectionService: SymphonyWorkspaceSelectionService(
                resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase(
                    workflowLoaderPort: SymphonyWorkflowLoaderPortAdapter(environment: [:]),
                    configResolverPort: SymphonyConfigResolverPortAdapter(environment: [:])
                )
            )
        )

        let viewModel = controller.selectWorkspace(workspacePath: workspaceURL.path)

        #expect(viewModel.state == .selected)
        #expect(viewModel.selection?.workspacePath == workspaceURL.path)
        #expect(viewModel.selection?.resolvedWorkflowPath == workflowURL.path)
        #expect(viewModel.selection?.workspaceName == workspaceURL.lastPathComponent)
    }

    @Test
    func workspaceLocatorMapsFromSelection() {
        let controller = SymphonyWorkspaceSelectionController(
            workspaceSelectionService: SymphonyWorkspaceSelectionService(
                resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase(
                    workflowLoaderPort: SymphonyWorkflowLoaderPortAdapter(environment: [:]),
                    configResolverPort: SymphonyConfigResolverPortAdapter(environment: [:])
                )
            )
        )
        let selection = SymphonyWorkspaceSelectionViewModel.Selection(
            id: "/Workspace",
            workspacePath: "/Workspace",
            explicitWorkflowPath: "/Workspace/WORKFLOW.md",
            resolvedWorkflowPath: "/Workspace/WORKFLOW.md",
            workspaceName: "Workspace"
        )

        let workspaceLocator = controller.workspaceLocator(for: selection)

        #expect(workspaceLocator.currentWorkingDirectoryPath == "/Workspace")
        #expect(workspaceLocator.explicitWorkflowPath == "/Workspace/WORKFLOW.md")
    }
}
