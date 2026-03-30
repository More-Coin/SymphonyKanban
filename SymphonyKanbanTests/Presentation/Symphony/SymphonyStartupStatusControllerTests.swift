import Foundation
import Testing
@testable import SymphonyKanban

@MainActor
@Suite
struct SymphonyStartupStatusControllerTests {
    @Test
    func queryViewModelReturnsPreviewOverrideWhenConfigured() {
        let previewViewModel = SymphonyStartupStatusViewModel(
            state: .ready,
            title: "Preview Ready",
            message: "Loaded preview bindings.",
            currentWorkingDirectoryPath: "/Preview/NaraIOS",
            explicitWorkflowPath: "/Preview/NaraIOS/WORKFLOW.md",
            activeBindingCount: 2,
            readyBindingCount: 2,
            failedBindingCount: 0,
            boundScopeNames: ["Nara IOS", "Nara Server"],
            resolvedWorkflowPaths: [
                "/Preview/NaraIOS/WORKFLOW.md",
                "/Preview/NaraServer/WORKFLOW.md"
            ],
            trackerStatusLabels: [
                "Connected to Linear.",
                "Connected to Linear."
            ]
        )
        let controller = SymphonyStartupStatusController(
            startupService: SymphonyStartupFlowTestSupport.makeStartupService()
        )
        .withPreviewViewModel(previewViewModel)

        let viewModel = controller.queryViewModel()

        #expect(viewModel == previewViewModel)
    }

    @Test
    func queryViewModelUsesExplicitWorkspaceLocatorOverride() throws {
        let workspaceURL = SymphonyStartupFlowTestSupport.temporaryDirectory()
        let workflowURL = workspaceURL.appendingPathComponent("WORKFLOW.md", isDirectory: false)
        try """
        ---
        tracker:
          kind: linear
          project_slug: project
        ---
        Prompt body.
        """.write(to: workflowURL, atomically: true, encoding: .utf8)

        let controller = SymphonyStartupStatusController(
            startupService: SymphonyStartupFlowTestSupport.makeStartupService(
                workspaceTrackerBindingPort: WorkspaceTrackerBindingPortSpy(
                    listedBindings: [
                        SymphonyStartupFlowTestSupport.makeWorkspaceBinding(
                            workspacePath: workspaceURL.path
                        )
                    ]
                )
            ),
            currentWorkingDirectoryPath: "/Unrelated",
            explicitWorkflowPath: nil
        )

        let viewModel = controller.queryViewModel(
            for: SymphonyWorkspaceLocatorContract(
                currentWorkingDirectoryPath: workspaceURL.path,
                explicitWorkflowPath: nil
            )
        )

        #expect(viewModel.state == .ready)
        #expect(viewModel.currentWorkingDirectoryPath == workspaceURL.path)
        #expect(viewModel.resolvedWorkflowPaths == [workflowURL.path])
    }
}
