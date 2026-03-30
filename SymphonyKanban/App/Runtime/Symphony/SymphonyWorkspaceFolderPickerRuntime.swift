import Foundation
#if os(macOS)
import AppKit
#endif

@MainActor
public struct SymphonyWorkspaceFolderPickerRuntime {
    typealias ChooseDirectory = @MainActor (URL?) -> URL?

    private let chooseDirectory: ChooseDirectory

    init(
        chooseDirectory: @escaping ChooseDirectory = Self.defaultChooseDirectory
    ) {
        self.chooseDirectory = chooseDirectory
    }

    public func chooseWorkspaceDirectory(
        startingDirectoryPath: String? = nil
    ) -> String? {
        let startingDirectoryURL = startingDirectoryPath.flatMap {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : URL(fileURLWithPath: $0, isDirectory: true)
        }

        return chooseDirectory(startingDirectoryURL)?
            .resolvingSymlinksInPath()
            .standardizedFileURL
            .path
    }

    private static func defaultChooseDirectory(
        startingDirectoryURL: URL?
    ) -> URL? {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = startingDirectoryURL
        panel.prompt = "Choose Workspace"
        panel.message = "Choose the local workspace folder Symphony should bind."
        return panel.runModal() == .OK ? panel.url : nil
        #else
        return nil
        #endif
    }
}
