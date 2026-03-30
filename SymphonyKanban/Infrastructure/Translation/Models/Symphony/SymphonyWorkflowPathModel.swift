import Foundation

struct SymphonyWorkflowPathModel {
    let environment: [String: String]

    func fromContract(
        _ workspaceLocator: SymphonyWorkspaceLocatorContract
    ) -> String {
        if let explicitWorkflowPath = workspaceLocator.explicitWorkflowPath,
           !explicitWorkflowPath.isEmpty {
            return normalizedPath(from: explicitWorkflowPath)
        }

        let currentWorkingDirectory = normalizedPath(from: workspaceLocator.currentWorkingDirectoryPath)
        return URL(fileURLWithPath: currentWorkingDirectory)
            .appendingPathComponent("WORKFLOW.md")
            .standardizedFileURL
            .path
    }

    private func normalizedPath(from path: String) -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        let environmentExpanded = environmentToken(in: trimmed) ?? trimmed
        let homeExpanded: String

        if environmentExpanded == "~" {
            homeExpanded = NSHomeDirectory()
        } else if environmentExpanded.hasPrefix("~/") {
            homeExpanded = NSString(string: environmentExpanded).replacingCharacters(
                in: NSRange(location: 0, length: 1),
                with: NSHomeDirectory()
            )
        } else {
            homeExpanded = environmentExpanded
        }

        return URL(fileURLWithPath: homeExpanded).standardizedFileURL.path
    }

    private func environmentToken(in value: String) -> String? {
        guard value.hasPrefix("$"),
              !value.contains("/") else {
            return nil
        }

        let variableName = String(value.dropFirst())
        return environment[variableName]
    }
}
