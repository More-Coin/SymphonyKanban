import Foundation

struct SymphonyWorkspaceTrackerBindingRepository: SymphonyWorkspaceTrackerBindingPortProtocol {
    private let storageURL: URL

    init(
        storageURL: URL = Self.defaultStorageURL()
    ) {
        self.storageURL = storageURL
    }

    func resolveBinding(
        for workspaceLocator: SymphonyWorkspaceLocatorContract
    ) throws -> SymphonyWorkspaceTrackerBindingContract? {
        let normalizedWorkspacePath = normalizedPath(from: workspaceLocator.currentWorkingDirectoryPath)
        return try listBindings().first { $0.workspacePath == normalizedWorkspacePath }
    }

    func listBindings() throws -> [SymphonyWorkspaceTrackerBindingContract] {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: storageURL)
            let store = try JSONDecoder().decode(SymphonyWorkspaceTrackerBindingStoreDTO.self, from: data)
            return bindings(from: store)
                .map(normalizedBinding(from:))
                .sorted { $0.workspacePath.localizedCaseInsensitiveCompare($1.workspacePath) == .orderedAscending }
        } catch {
            throw SymphonyWorkspaceInfrastructureError.bindingLoadFailed(
                path: storageURL.path,
                details: error.localizedDescription
            )
        }
    }

    func saveBinding(
        _ binding: SymphonyWorkspaceTrackerBindingContract
    ) throws {
        let normalizedBinding = normalizedBinding(from: binding)
        var bindings = try listBindings()

        if let index = bindings.firstIndex(where: { $0.workspacePath == normalizedBinding.workspacePath }) {
            bindings[index] = normalizedBinding
        } else {
            bindings.append(normalizedBinding)
        }

        try writeBindings(bindings)
    }

    func removeBinding(
        forWorkspacePath workspacePath: String
    ) throws {
        let normalizedWorkspacePath = normalizedPath(from: workspacePath)
        let existingBindings = try listBindings()
        let filteredBindings = existingBindings.filter { $0.workspacePath != normalizedWorkspacePath }

        guard filteredBindings.count != existingBindings.count else {
            return
        }

        if filteredBindings.isEmpty {
            do {
                if FileManager.default.fileExists(atPath: storageURL.path) {
                    try FileManager.default.removeItem(at: storageURL)
                }
            } catch {
                throw SymphonyWorkspaceInfrastructureError.bindingRemovalFailed(
                    path: storageURL.path,
                    details: error.localizedDescription
                )
            }
            return
        }

        try writeBindings(filteredBindings)
    }

    private func writeBindings(
        _ bindings: [SymphonyWorkspaceTrackerBindingContract]
    ) throws {
        do {
            let directoryURL = storageURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(
                storeDTO(from: bindings)
            )
            try data.write(to: storageURL, options: .atomic)
        } catch {
            throw SymphonyWorkspaceInfrastructureError.bindingSaveFailed(
                path: storageURL.path,
                details: error.localizedDescription
            )
        }
    }

    private func normalizedBinding(
        from binding: SymphonyWorkspaceTrackerBindingContract
    ) -> SymphonyWorkspaceTrackerBindingContract {
        SymphonyWorkspaceTrackerBindingContract(
            workspacePath: normalizedPath(from: binding.workspacePath),
            explicitWorkflowPath: binding.explicitWorkflowPath.map(normalizedPath(from:)),
            trackerKind: binding.trackerKind.trimmingCharacters(in: .whitespacesAndNewlines),
            scopeKind: binding.scopeKind.trimmingCharacters(in: .whitespacesAndNewlines),
            scopeIdentifier: binding.scopeIdentifier.trimmingCharacters(in: .whitespacesAndNewlines),
            scopeName: binding.scopeName.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private func normalizedPath(
        from rawPath: String
    ) -> String {
        let trimmedPath = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
        let homeExpandedPath = NSString(string: trimmedPath).expandingTildeInPath
        return URL(fileURLWithPath: homeExpandedPath)
            .resolvingSymlinksInPath()
            .standardizedFileURL
            .path
    }

    private func storeDTO(
        from bindings: [SymphonyWorkspaceTrackerBindingContract]
    ) -> SymphonyWorkspaceTrackerBindingStoreDTO {
        SymphonyWorkspaceTrackerBindingStoreDTO(
            bindings: bindings.map(recordDTO(from:))
        )
    }

    private func bindings(
        from storeDTO: SymphonyWorkspaceTrackerBindingStoreDTO
    ) -> [SymphonyWorkspaceTrackerBindingContract] {
        storeDTO.bindings.map(bindingContract(from:))
    }

    private func recordDTO(
        from binding: SymphonyWorkspaceTrackerBindingContract
    ) -> SymphonyWorkspaceTrackerBindingRecordDTO {
        SymphonyWorkspaceTrackerBindingRecordDTO(
            workspacePath: binding.workspacePath,
            explicitWorkflowPath: binding.explicitWorkflowPath,
            trackerKind: binding.trackerKind,
            scopeKind: binding.scopeKind,
            scopeIdentifier: binding.scopeIdentifier,
            scopeName: binding.scopeName
        )
    }

    private func bindingContract(
        from recordDTO: SymphonyWorkspaceTrackerBindingRecordDTO
    ) -> SymphonyWorkspaceTrackerBindingContract {
        SymphonyWorkspaceTrackerBindingContract(
            workspacePath: recordDTO.workspacePath,
            explicitWorkflowPath: recordDTO.explicitWorkflowPath,
            trackerKind: recordDTO.trackerKind,
            scopeKind: recordDTO.scopeKind,
            scopeIdentifier: recordDTO.scopeIdentifier,
            scopeName: recordDTO.scopeName
        )
    }

    private static func defaultStorageURL() -> URL {
        let applicationSupportURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.symphonykanban.app"
        return applicationSupportURL
            .appendingPathComponent(bundleIdentifier, isDirectory: true)
            .appendingPathComponent("workspace_tracker_bindings.json", isDirectory: false)
    }
}
