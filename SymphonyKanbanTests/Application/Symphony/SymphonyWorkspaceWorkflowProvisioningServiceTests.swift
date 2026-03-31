import Foundation
import Testing
@testable import SymphonyKanban

@Suite
struct SymphonyWorkspaceWorkflowProvisioningServiceTests {
    @Test
    func provisionWorkspaceCreatesWorkflowFileForProjectScopeWhenMissing() throws {
        let workspaceURL = SymphonyStartupFlowTestSupport.temporaryDirectory()
        let service = makeService()

        let result = try service.provisionWorkspace(
            workspacePath: workspaceURL.path,
            selectedScope: .init(
                id: "project:mobile-rebuild",
                scopeKind: "project",
                scopeIdentifier: "mobile-rebuild",
                scopeName: "Mobile Rebuild"
            )
        )

        let workflowURL = workspaceURL.appendingPathComponent("WORKFLOW.md", isDirectory: false)
        let contents = try String(contentsOf: workflowURL, encoding: .utf8)

        #expect(result.workflowProvisioningStatus == .created)
        #expect(result.resolvedWorkflowPath == workflowURL.path)
        #expect(contents.contains("project_slug: mobile-rebuild"))
        #expect(contents.contains("You are working on an issue from Linear."))
    }

    @Test
    func provisionWorkspaceCreatesWorkflowFileForTeamScopeWhenMissing() throws {
        let workspaceURL = SymphonyStartupFlowTestSupport.temporaryDirectory()
        let service = makeService()

        let result = try service.provisionWorkspace(
            workspacePath: workspaceURL.path,
            selectedScope: .init(
                id: "team:team-ios",
                scopeKind: "team",
                scopeIdentifier: "team-ios",
                scopeName: "Nara iOS"
            )
        )

        let workflowURL = workspaceURL.appendingPathComponent("WORKFLOW.md", isDirectory: false)
        let contents = try String(contentsOf: workflowURL, encoding: .utf8)

        #expect(result.workflowProvisioningStatus == .created)
        #expect(contents.contains("team_id: team-ios"))
    }

    @Test
    func provisionWorkspaceReusesExistingWorkflowWithoutOverwritingIt() throws {
        let workspaceURL = SymphonyStartupFlowTestSupport.temporaryDirectory()
        let workflowURL = workspaceURL.appendingPathComponent("WORKFLOW.md", isDirectory: false)
        let existingContents = """
        ---
        tracker:
          kind: linear
          project_slug: mobile-rebuild
        ---
        Existing prompt body.
        """
        try existingContents.write(to: workflowURL, atomically: true, encoding: .utf8)

        let service = makeService()

        let result = try service.provisionWorkspace(
            workspacePath: workspaceURL.path,
            selectedScope: .init(
                id: "project:mobile-rebuild",
                scopeKind: "project",
                scopeIdentifier: "mobile-rebuild",
                scopeName: "Mobile Rebuild"
            )
        )

        let contentsAfterProvisioning = try String(contentsOf: workflowURL, encoding: .utf8)

        #expect(result.workflowProvisioningStatus == .existing)
        #expect(contentsAfterProvisioning == existingContents)
    }

    @Test
    func provisionWorkspacePreservesInvalidExistingWorkflowAndSurfacesValidationFailure() throws {
        let workspaceURL = SymphonyStartupFlowTestSupport.temporaryDirectory()
        let workflowURL = workspaceURL.appendingPathComponent("WORKFLOW.md", isDirectory: false)
        let invalidContents = """
        ---
        tracker:
          kind: linear
        ---
        Existing prompt body.
        """
        try invalidContents.write(to: workflowURL, atomically: true, encoding: .utf8)

        let service = makeService()

        do {
            _ = try service.provisionWorkspace(
                workspacePath: workspaceURL.path,
                selectedScope: .init(
                    id: "project:mobile-rebuild",
                    scopeKind: "project",
                    scopeIdentifier: "mobile-rebuild",
                    scopeName: "Mobile Rebuild"
                )
            )
            Issue.record("Expected invalid existing workflow file to fail validation.")
        } catch let error as SymphonyStartupApplicationError {
            #expect(error == .missingTrackerScopeIdentifier)
            let contentsAfterFailure = try String(contentsOf: workflowURL, encoding: .utf8)
            #expect(contentsAfterFailure == invalidContents)
        } catch {
            Issue.record("Expected startup validation error, received \(error).")
        }
    }

    @Test
    func provisionWorkspaceRejectsExistingWorkflowWhenItsScopeDoesNotMatchSelection() throws {
        let workspaceURL = SymphonyStartupFlowTestSupport.temporaryDirectory()
        let workflowURL = workspaceURL.appendingPathComponent("WORKFLOW.md", isDirectory: false)
        try """
        ---
        tracker:
          kind: linear
          project_slug: mobile-rebuild
        ---
        Existing prompt body.
        """.write(to: workflowURL, atomically: true, encoding: .utf8)

        let service = makeService()

        do {
            _ = try service.provisionWorkspace(
                workspacePath: workspaceURL.path,
                selectedScope: .init(
                    id: "team:team-ios",
                    scopeKind: "team",
                    scopeIdentifier: "team-ios",
                    scopeName: "Nara iOS"
                )
            )
            Issue.record("Expected mismatched workflow scope to fail.")
        } catch let error as SymphonyWorkspaceSelectionApplicationError {
            guard case .workflowScopeMismatch(
                let expectedScopeKind,
                let expectedScopeIdentifier,
                let actualScopeKind,
                let actualScopeIdentifier
            ) = error else {
                Issue.record("Expected workflowScopeMismatch, received \(error).")
                return
            }

            #expect(expectedScopeKind == "team")
            #expect(expectedScopeIdentifier == "team-ios")
            #expect(actualScopeKind == "project")
            #expect(actualScopeIdentifier == "mobile-rebuild")
        } catch {
            Issue.record("Expected workspace selection mismatch error, received \(error).")
        }
    }

    private func makeService() -> SymphonyWorkspaceWorkflowProvisioningService {
        SymphonyWorkspaceWorkflowProvisioningService(
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
    }
}
