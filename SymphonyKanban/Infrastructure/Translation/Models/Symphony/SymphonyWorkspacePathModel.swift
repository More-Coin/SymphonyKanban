import Foundation

struct SymphonyWorkspacePathModel {
    func fromContract(
        using workspace: SymphonyServiceConfigContract.Workspace,
        currentWorkingDirectoryPath: String
    ) throws -> String {
        let trimmedRoot = workspace.rootPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRoot.isEmpty else {
            throw SymphonyWorkspaceInfrastructureError.invalidWorkspaceRoot(path: workspace.rootPath)
        }

        return toAbsolutePath(
            from: trimmedRoot,
            currentWorkingDirectoryPath: currentWorkingDirectoryPath
        )
    }

    func toAbsolutePath(
        from path: String,
        currentWorkingDirectoryPath: String
    ) -> String {
        let baseURL = URL(fileURLWithPath: currentWorkingDirectoryPath, isDirectory: true)
        let fileURL: URL

        if NSString(string: path).isAbsolutePath {
            fileURL = URL(fileURLWithPath: path, isDirectory: true)
        } else {
            fileURL = URL(fileURLWithPath: path, relativeTo: baseURL)
        }

        return fileURL.standardizedFileURL.path
    }

    func toResolvedPath(from path: String) -> String {
        URL(fileURLWithPath: path).resolvingSymlinksInPath().standardizedFileURL.path
    }
}

struct SymphonyHookScriptModel {
    func normalizedConfigHookScript(_ script: String?) -> String? {
        guard let script = script?.trimmingCharacters(in: .whitespacesAndNewlines),
              !script.isEmpty else {
            return nil
        }

        return script
    }
}
