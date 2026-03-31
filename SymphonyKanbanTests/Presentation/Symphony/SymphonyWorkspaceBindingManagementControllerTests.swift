import Foundation
import Testing
@testable import SymphonyKanban

@MainActor
@Suite
struct SymphonyWorkspaceBindingManagementControllerTests {
    @Test
    func updateBindingWorkspaceReplacesTheSavedWorkspacePath() throws {
        let rootURL = SymphonyStartupFlowTestSupport.temporaryDirectory()
        let storageURL = rootURL.appendingPathComponent("workspace-bindings.json", isDirectory: false)
        let oldWorkspaceURL = try makeWorkspace(
            named: "OldWorkspace",
            in: rootURL
        )
        let newWorkspaceURL = try makeWorkspace(
            named: "NewWorkspace",
            in: rootURL
        )

        let repository = SymphonyWorkspaceTrackerBindingRepository(
            storageURL: storageURL
        )
        try repository.saveBinding(
            SymphonyStartupFlowTestSupport.makeWorkspaceBinding(
                workspacePath: oldWorkspaceURL.path,
                scopeIdentifier: "nara-ios",
                scopeName: "Nara iOS"
            )
        )

        let controller = makeController(repository: repository)

        let viewModel = controller.updateBindingWorkspace(
            existingWorkspacePath: oldWorkspaceURL.path,
            newWorkspacePath: newWorkspaceURL.path,
            explicitWorkflowPath: nil,
            trackerKind: "linear",
            scopeKind: "team",
            scopeIdentifier: "nara-ios",
            scopeName: "Nara iOS"
        )

        #expect(viewModel.bannerMessage == nil)
        #expect(viewModel.cards.count == 1)
        #expect(viewModel.cards.first?.workspacePath == newWorkspaceURL.path)

        let bindings = try repository.listBindings()
        #expect(bindings.count == 1)
        #expect(bindings.first?.workspacePath == newWorkspaceURL.path)
    }

    @Test
    func queryViewModelCanRetainCardsWhileShowingBannerMessage() throws {
        let rootURL = SymphonyStartupFlowTestSupport.temporaryDirectory()
        let storageURL = rootURL.appendingPathComponent("workspace-bindings.json", isDirectory: false)
        let workspaceURL = try makeWorkspace(
            named: "Workspace",
            in: rootURL
        )

        let repository = SymphonyWorkspaceTrackerBindingRepository(
            storageURL: storageURL
        )
        try repository.saveBinding(
            SymphonyStartupFlowTestSupport.makeWorkspaceBinding(
                workspacePath: workspaceURL.path,
                scopeIdentifier: "nara-server",
                scopeName: "Nara Server"
            )
        )

        let controller = makeController(repository: repository)

        let viewModel = controller.queryViewModel(
            bannerMessage: "No WORKFLOW.md was found at the expected path."
        )

        #expect(viewModel.cards.count == 1)
        #expect(viewModel.cards.first?.scopeName == "Nara Server")
        #expect(viewModel.bannerMessage == "No WORKFLOW.md was found at the expected path.")
    }

    private func makeController(
        repository: SymphonyWorkspaceTrackerBindingRepository
    ) -> SymphonyWorkspaceBindingManagementController {
        SymphonyWorkspaceBindingManagementController(
            managementService: SymphonyWorkspaceBindingManagementService(
                queryWorkspaceTrackerBindingsUseCase: QuerySymphonyWorkspaceTrackerBindingsUseCase(
                    workspaceTrackerBindingPort: repository
                ),
                removeBindingUseCase: RemoveSymphonyWorkspaceTrackerBindingUseCase(
                    workspaceTrackerBindingPort: repository
                ),
                resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase(
                    workflowLoaderPort: SymphonyWorkflowLoaderPortAdapter(environment: [:]),
                    configResolverPort: SymphonyConfigResolverPortAdapter(environment: [:])
                ),
                validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase(
                    startupConfigurationValidatorPort: ValidateSymphonyStartupConfigurationPortAdapter()
                ),
                validateTrackerConnectionUseCase: ValidateSymphonyTrackerConnectionReadinessUseCase(
                    trackerAuthPort: TrackerAuthPortSpy()
                )
            ),
            setupController: SymphonyWorkspaceBindingSetupController(
                setupService: SymphonyWorkspaceBindingSetupService(
                    saveWorkspaceTrackerBindingUseCase: SaveSymphonyWorkspaceTrackerBindingUseCase(
                        workspaceTrackerBindingPort: repository
                    )
                )
            )
        )
    }

    private func makeWorkspace(
        named workspaceName: String,
        in rootURL: URL
    ) throws -> URL {
        let workspaceURL = rootURL.appendingPathComponent(workspaceName, isDirectory: true)
        try FileManager.default.createDirectory(
            at: workspaceURL,
            withIntermediateDirectories: true
        )

        let workflowURL = workspaceURL.appendingPathComponent("WORKFLOW.md", isDirectory: false)
        try """
        ---
        tracker:
          kind: linear
          team_id: \(workspaceName.lowercased())
        ---
        Prompt body.
        """.write(to: workflowURL, atomically: true, encoding: .utf8)

        return workspaceURL
    }
}
