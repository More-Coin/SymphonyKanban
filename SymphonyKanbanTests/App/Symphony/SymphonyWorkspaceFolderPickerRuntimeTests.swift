import Foundation
import Testing
@testable import SymphonyKanban

@MainActor
@Suite
struct SymphonyWorkspaceFolderPickerRuntimeTests {
    @Test
    func chooseWorkspaceDirectoryNormalizesSelectedPath() {
        let runtime = SymphonyWorkspaceFolderPickerRuntime(
            chooseDirectory: { _ in
                URL(fileURLWithPath: "/tmp/../tmp/Workspace", isDirectory: true)
            }
        )

        let selectedPath = runtime.chooseWorkspaceDirectory()

        #expect(selectedPath == "/tmp/Workspace")
    }

    @Test
    func chooseWorkspaceDirectoryReturnsNilWhenSelectionCancelled() {
        let runtime = SymphonyWorkspaceFolderPickerRuntime(
            chooseDirectory: { _ in nil }
        )

        let selectedPath = runtime.chooseWorkspaceDirectory()

        #expect(selectedPath == nil)
    }
}
