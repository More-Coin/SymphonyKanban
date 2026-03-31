public protocol SymphonyIssueCatalogDisplayModePreferencePortProtocol: Sendable {
    func queryDisplayMode() throws -> SymphonyIssueCatalogDisplayModeContract?
    func saveDisplayMode(
        _ displayMode: SymphonyIssueCatalogDisplayModeContract
    ) throws
}
