import Foundation
import Testing
@testable import SymphonyKanban

struct SymphonyWorkflowWritePortAdapterTests {
    @Test
    func ensureDefinitionExistsWritesUTF8ContentsAndReportsFileExistence() throws {
        let workspaceURL = SymphonyStartupFlowTestSupport.temporaryDirectory()
        let workflowURL = workspaceURL.appendingPathComponent("WORKFLOW.md", isDirectory: false)
        let adapter = SymphonyWorkflowWritePortAdapter()

        let wasCreated = try adapter.ensureDefinitionExists(
            contents: "tracker: linear\n",
            atPath: workflowURL.path
        )

        #expect(adapter.defaultDefinitionPath(forWorkspacePath: workspaceURL.path) == workflowURL.path)
        #expect(wasCreated)
        #expect(try String(contentsOf: workflowURL, encoding: .utf8) == "tracker: linear\n")
    }

    @Test
    func ensureDefinitionExistsDoesNotOverwriteExistingFiles() throws {
        let workspaceURL = SymphonyStartupFlowTestSupport.temporaryDirectory()
        let workflowURL = workspaceURL.appendingPathComponent("WORKFLOW.md", isDirectory: false)
        try "existing".write(to: workflowURL, atomically: true, encoding: .utf8)

        let adapter = SymphonyWorkflowWritePortAdapter()

        let wasCreated = try adapter.ensureDefinitionExists(
            contents: "replacement",
            atPath: workflowURL.path
        )

        #expect(wasCreated == false)
        #expect(try String(contentsOf: workflowURL, encoding: .utf8) == "existing")
    }

    @Test
    func ensureDefinitionExistsMapsFilesystemFailuresToTypedErrors() throws {
        let rootURL = SymphonyStartupFlowTestSupport.temporaryDirectory()
        let blockingFileURL = rootURL.appendingPathComponent("blocked", isDirectory: false)
        try "blocked".write(to: blockingFileURL, atomically: true, encoding: .utf8)

        let adapter = SymphonyWorkflowWritePortAdapter()
        let targetPath = blockingFileURL.appendingPathComponent("WORKFLOW.md").path

        do {
            _ = try adapter.ensureDefinitionExists(
                contents: "new contents",
                atPath: targetPath
            )
            Issue.record("Expected a typed write failure.")
        } catch let error as SymphonyWorkflowInfrastructureError {
            guard case .workflowWriteFailed(let path, let details) = error else {
                Issue.record("Expected workflowWriteFailed, received \(error).")
                return
            }

            #expect(path == targetPath)
            #expect(details.isEmpty == false)
        } catch {
            Issue.record("Expected workflow infrastructure error, received \(error).")
        }
    }
}
