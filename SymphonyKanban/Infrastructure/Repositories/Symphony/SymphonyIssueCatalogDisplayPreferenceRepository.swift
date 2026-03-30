import Foundation

struct SymphonyIssueCatalogDisplayPreferenceRepository: SymphonyIssueCatalogDisplayModePreferencePortProtocol {
    private let storageURL: URL

    init(
        storageURL: URL = Self.defaultStorageURL()
    ) {
        self.storageURL = storageURL
    }

    func queryDisplayMode() throws -> SymphonyIssueCatalogDisplayModeContract? {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: storageURL)
            let preference = try JSONDecoder().decode(
                SymphonyIssueCatalogDisplayPreferenceDTO.self,
                from: data
            )
            return SymphonyIssueCatalogDisplayModeContract(
                rawValue: preference.displayModeRawValue
            )
        } catch {
            throw SymphonyWorkspaceInfrastructureError.displayPreferenceLoadFailed(
                path: storageURL.path,
                details: error.localizedDescription
            )
        }
    }

    func saveDisplayMode(
        _ displayMode: SymphonyIssueCatalogDisplayModeContract
    ) throws {
        do {
            let directoryURL = storageURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(
                SymphonyIssueCatalogDisplayPreferenceDTO(
                    displayModeRawValue: displayMode.rawValue
                )
            )
            try data.write(to: storageURL, options: .atomic)
        } catch {
            throw SymphonyWorkspaceInfrastructureError.displayPreferenceSaveFailed(
                path: storageURL.path,
                details: error.localizedDescription
            )
        }
    }

    private static func defaultStorageURL() -> URL {
        let applicationSupportURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.symphonykanban.app"
        return applicationSupportURL
            .appendingPathComponent(bundleIdentifier, isDirectory: true)
            .appendingPathComponent("issue_catalog_display_preference.json", isDirectory: false)
    }
}
