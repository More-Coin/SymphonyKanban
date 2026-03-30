import Testing
@testable import SymphonyKanban

@Suite
struct SymphonyIssueCatalogDisplayPreferenceServiceTests {
    @Test
    func queryDisplayModePersistsDefaultWhenNoPreferenceExists() throws {
        let preferencePort = IssueCatalogDisplayModePreferencePortSpy()
        let service = SymphonyIssueCatalogDisplayPreferenceService(
            queryDisplayModeUseCase: QuerySymphonyIssueCatalogDisplayModeUseCase(
                preferencePort: preferencePort
            ),
            saveDisplayModeUseCase: SaveSymphonyIssueCatalogDisplayModeUseCase(
                preferencePort: preferencePort
            )
        )

        let displayMode = try service.queryDisplayMode()

        #expect(displayMode == .groupedSections)
        #expect(preferencePort.savedDisplayModes == [.groupedSections])
    }

    @Test
    func saveDisplayModeSkipsPersistenceWhenRequestedModeMatchesStoredMode() throws {
        let preferencePort = IssueCatalogDisplayModePreferencePortSpy()
        preferencePort.storedDisplayMode = .mergedWithBadges
        let service = SymphonyIssueCatalogDisplayPreferenceService(
            queryDisplayModeUseCase: QuerySymphonyIssueCatalogDisplayModeUseCase(
                preferencePort: preferencePort
            ),
            saveDisplayModeUseCase: SaveSymphonyIssueCatalogDisplayModeUseCase(
                preferencePort: preferencePort
            )
        )

        let displayMode = try service.saveDisplayMode(.mergedWithBadges)

        #expect(displayMode == .mergedWithBadges)
        #expect(preferencePort.savedDisplayModes.isEmpty)
    }
}

private final class IssueCatalogDisplayModePreferencePortSpy:
    SymphonyIssueCatalogDisplayModePreferencePortProtocol,
    @unchecked Sendable
{
    var storedDisplayMode: SymphonyIssueCatalogDisplayModeContract?
    var savedDisplayModes: [SymphonyIssueCatalogDisplayModeContract] = []

    func queryDisplayMode() throws -> SymphonyIssueCatalogDisplayModeContract? {
        storedDisplayMode
    }

    func saveDisplayMode(
        _ displayMode: SymphonyIssueCatalogDisplayModeContract
    ) throws {
        storedDisplayMode = displayMode
        savedDisplayModes.append(displayMode)
    }
}
