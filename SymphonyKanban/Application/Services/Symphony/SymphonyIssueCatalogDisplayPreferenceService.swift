public struct SymphonyIssueCatalogDisplayPreferenceService: Sendable {
    private let queryDisplayModeUseCase: QuerySymphonyIssueCatalogDisplayModeUseCase
    private let saveDisplayModeUseCase: SaveSymphonyIssueCatalogDisplayModeUseCase
    private let displayModeStateTransition: SymphonyIssueCatalogDisplayModeStateTransition

    public init(
        queryDisplayModeUseCase: QuerySymphonyIssueCatalogDisplayModeUseCase,
        saveDisplayModeUseCase: SaveSymphonyIssueCatalogDisplayModeUseCase,
        displayModeStateTransition: SymphonyIssueCatalogDisplayModeStateTransition = .init()
    ) {
        self.queryDisplayModeUseCase = queryDisplayModeUseCase
        self.saveDisplayModeUseCase = saveDisplayModeUseCase
        self.displayModeStateTransition = displayModeStateTransition
    }

    public func queryDisplayMode() throws -> SymphonyIssueCatalogDisplayModeContract {
        let storedDisplayMode = try queryDisplayModeUseCase.queryStoredDisplayMode()
        let resolvedDisplayMode = displayModeStateTransition.resolveStoredDisplayMode(
            storedDisplayMode
        )

        if displayModeStateTransition.shouldPersistResolvedDisplayMode(
            storedDisplayMode: storedDisplayMode,
            resolvedDisplayMode: resolvedDisplayMode
        ) {
            _ = try saveDisplayModeUseCase.saveDisplayMode(resolvedDisplayMode)
        }

        return resolvedDisplayMode
    }

    public func saveDisplayMode(
        _ displayMode: SymphonyIssueCatalogDisplayModeContract
    ) throws -> SymphonyIssueCatalogDisplayModeContract {
        let storedDisplayMode = try queryDisplayModeUseCase.queryStoredDisplayMode()
        let currentDisplayMode = displayModeStateTransition.resolveStoredDisplayMode(
            storedDisplayMode
        )
        let updatedDisplayMode = displayModeStateTransition.resolveUpdatedDisplayMode(
            currentDisplayMode: currentDisplayMode,
            requestedDisplayMode: displayMode
        )

        if displayModeStateTransition.shouldPersistUpdatedDisplayMode(
            storedDisplayMode: storedDisplayMode,
            updatedDisplayMode: updatedDisplayMode
        ) {
            _ = try saveDisplayModeUseCase.saveDisplayMode(updatedDisplayMode)
        }

        return updatedDisplayMode
    }
}
