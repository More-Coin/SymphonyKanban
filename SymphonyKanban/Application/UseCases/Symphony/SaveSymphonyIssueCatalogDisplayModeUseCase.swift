public struct SaveSymphonyIssueCatalogDisplayModeUseCase: Sendable {
    private let preferencePort: any SymphonyIssueCatalogDisplayModePreferencePortProtocol

    public init(
        preferencePort: any SymphonyIssueCatalogDisplayModePreferencePortProtocol
    ) {
        self.preferencePort = preferencePort
    }

    public func saveDisplayMode(
        _ displayMode: SymphonyIssueCatalogDisplayModeContract
    ) throws -> SymphonyIssueCatalogDisplayModeContract {
        try preferencePort.saveDisplayMode(displayMode)
        return displayMode
    }
}
