import Foundation
import Testing
@testable import SymphonyKanban

@MainActor
@Suite
struct SymphonyWorkspaceSelectionControllerTests {
    @Test
    func selectWorkspaceCreatesWorkflowForTeamScopedWorkspaceWhenMissing() throws {
        let workspaceURL = SymphonyStartupFlowTestSupport.temporaryDirectory()

        let controller = makeController()

        let viewModel = controller.selectWorkspace(
            workspacePath: workspaceURL.path,
            scopeKind: "team",
            scopeIdentifier: "team-ios",
            scopeName: "Nara iOS"
        )

        #expect(viewModel.state == .selected)
        #expect(viewModel.selection?.workspacePath == workspaceURL.path)
        #expect(viewModel.selection?.resolvedWorkflowPath == workspaceURL.appendingPathComponent("WORKFLOW.md").path)
        #expect(viewModel.selection?.workspaceName == workspaceURL.lastPathComponent)
        #expect(viewModel.selection?.workflowProvisioningStatus == .created)
    }

    @Test
    func workspaceLocatorMapsFromSelection() {
        let controller = makeController()
        let selection = SymphonyWorkspaceSelectionViewModel.Selection(
            id: "/Workspace",
            workspacePath: "/Workspace",
            explicitWorkflowPath: "/Workspace/WORKFLOW.md",
            resolvedWorkflowPath: "/Workspace/WORKFLOW.md",
            workspaceName: "Workspace",
            workflowProvisioningStatus: .existing
        )

        let workspaceLocator = controller.workspaceLocator(for: selection)

        #expect(workspaceLocator.currentWorkingDirectoryPath == "/Workspace")
        #expect(workspaceLocator.explicitWorkflowPath == "/Workspace/WORKFLOW.md")
    }

    private func makeController() -> SymphonyWorkspaceSelectionController {
        SymphonyWorkspaceSelectionController(
            workspaceProvisioningService: SymphonyWorkspaceWorkflowProvisioningService(
                resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase(
                    workflowLoaderPort: SymphonyWorkflowLoaderPortAdapter(environment: [:]),
                    configResolverPort: SymphonyConfigResolverPortAdapter(environment: [:])
                ),
                validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase(
                    startupConfigurationValidatorPort: ValidateSymphonyStartupConfigurationPortAdapter()
                ),
                workflowWritePort: SymphonyWorkflowWritePortAdapter(),
                workflowTemplatePort: SymphonyWorkflowTemplatePortAdapter()
            )
        )
    }
}
