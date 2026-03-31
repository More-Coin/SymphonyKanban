import Foundation

public struct SymphonyWorkflowWritePortAdapter: SymphonyWorkflowWritePortProtocol {
    private let fileManager: FileManager

    public init(
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
    }

    public func defaultDefinitionPath(
        forWorkspacePath workspacePath: String
    ) -> String {
        URL(fileURLWithPath: workspacePath, isDirectory: true)
            .appendingPathComponent("WORKFLOW.md", isDirectory: false)
            .standardizedFileURL
            .path
    }

    @discardableResult
    public func ensureDefinitionExists(
        contents: String,
        atPath path: String
    ) throws -> Bool {
        guard fileManager.fileExists(atPath: path) == false else {
            return false
        }

        let targetURL = URL(fileURLWithPath: path)
        let parentURL = targetURL.deletingLastPathComponent()

        do {
            if fileManager.fileExists(atPath: parentURL.path) == false {
                try fileManager.createDirectory(
                    at: parentURL,
                    withIntermediateDirectories: true
                )
            }

            try contents.write(
                to: targetURL,
                atomically: true,
                encoding: .utf8
            )
        } catch {
            throw SymphonyWorkflowInfrastructureError.workflowWriteFailed(
                path: path,
                details: error.localizedDescription
            )
        }

        return true
    }
}
