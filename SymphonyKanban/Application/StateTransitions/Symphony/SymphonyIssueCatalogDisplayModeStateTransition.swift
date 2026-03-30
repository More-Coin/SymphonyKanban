public struct SymphonyIssueCatalogDisplayModeStateTransition: Sendable {
    public init() {}

    public func resolveStoredDisplayMode(
        _ storedDisplayMode: SymphonyIssueCatalogDisplayModeContract?
    ) -> SymphonyIssueCatalogDisplayModeContract {
        storedDisplayMode ?? .groupedSections
    }

    public func shouldPersistResolvedDisplayMode(
        storedDisplayMode: SymphonyIssueCatalogDisplayModeContract?,
        resolvedDisplayMode: SymphonyIssueCatalogDisplayModeContract
    ) -> Bool {
        storedDisplayMode != resolvedDisplayMode
    }

    public func resolveUpdatedDisplayMode(
        currentDisplayMode: SymphonyIssueCatalogDisplayModeContract,
        requestedDisplayMode: SymphonyIssueCatalogDisplayModeContract
    ) -> SymphonyIssueCatalogDisplayModeContract {
        requestedDisplayMode
    }

    public func shouldPersistUpdatedDisplayMode(
        storedDisplayMode: SymphonyIssueCatalogDisplayModeContract?,
        updatedDisplayMode: SymphonyIssueCatalogDisplayModeContract
    ) -> Bool {
        storedDisplayMode != updatedDisplayMode
    }
}
