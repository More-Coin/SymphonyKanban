import Foundation

public struct SourceFileDiscoveryGateway: SourceFileDiscoveryPortProtocol {
    private let fileManager: FileManager
    private let excludedPrefixes: [String]
    private let repoRelativePathModel: LinterRepoRelativePathModel

    public init(
        fileManager: FileManager = .default,
        excludedPrefixes: [String] = [
            ".build/",
            ".git/",
            ".derivedData",
            "Tools/"
        ]
    ) {
        self.fileManager = fileManager
        self.repoRelativePathModel = LinterRepoRelativePathModel()
        self.excludedPrefixes = excludedPrefixes
    }

    public func discoverSwiftFiles(in rootURL: URL) throws -> [URL] {
        var isDirectory: ObjCBool = false
        let rootPath = rootURL.standardizedFileURL.path

        guard fileManager.fileExists(atPath: rootPath, isDirectory: &isDirectory),
              isDirectory.boolValue,
              fileManager.isReadableFile(atPath: rootPath) else {
            throw KanbanArchitectureLinterInfrastructureError.invalidRootDirectory(path: rootPath)
        }

        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw KanbanArchitectureLinterInfrastructureError.invalidRootDirectory(path: rootPath)
        }

        var results: [URL] = []
        for case let fileURL as URL in enumerator {
            let path = fileURL.path
            guard path.hasSuffix(".swift") else { continue }

            let relativePath = repoRelativePathModel.fromURLs(
                fileURL: fileURL,
                rootURL: rootURL
            )
            guard shouldLint(repoRelativePath: relativePath) else { continue }
            results.append(fileURL)
        }

        return results.sorted { lhs, rhs in
            repoRelativePathModel.fromURLs(fileURL: lhs, rootURL: rootURL)
                < repoRelativePathModel.fromURLs(fileURL: rhs, rootURL: rootURL)
        }
    }

    private func shouldLint(repoRelativePath: String) -> Bool {
        if isExcludedUITestPath(repoRelativePath) {
            return false
        }

        return !excludedPrefixes.contains { prefix in
            if prefix.hasSuffix("/") {
                return repoRelativePath.hasPrefix(prefix)
            }
            return repoRelativePath.hasPrefix(prefix)
        }
    }

    private func isExcludedUITestPath(_ repoRelativePath: String) -> Bool {
        guard let firstComponent = repoRelativePath.split(separator: "/").first else {
            return false
        }

        let rootFolder = String(firstComponent)
        return rootFolder.hasSuffix("UITests")
    }
}
