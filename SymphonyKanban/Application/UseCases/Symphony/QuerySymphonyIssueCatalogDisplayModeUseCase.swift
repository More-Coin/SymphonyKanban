public struct QuerySymphonyIssueCatalogDisplayModeUseCase: Sendable {
    private let preferencePort: any SymphonyIssueCatalogDisplayModePreferencePortProtocol

    public init(
        preferencePort: any SymphonyIssueCatalogDisplayModePreferencePortProtocol
    ) {
        self.preferencePort = preferencePort
    }

    public func queryStoredDisplayMode() throws -> SymphonyIssueCatalogDisplayModeContract? {
        try preferencePort.queryDisplayMode()
    }
}
