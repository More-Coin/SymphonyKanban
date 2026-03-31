@MainActor
public struct SymphonySetupScopeSelectionController {
    private let trackerScopeService: SymphonyTrackerScopeService
    private let presenter: SymphonySetupScopeSelectionPresenter
    private let previewViewModel: SymphonySetupScopeSelectionViewModel?

    public init(
        trackerScopeService: SymphonyTrackerScopeService,
        presenter: SymphonySetupScopeSelectionPresenter? = nil,
        previewViewModel: SymphonySetupScopeSelectionViewModel? = nil
    ) {
        self.trackerScopeService = trackerScopeService
        self.presenter = presenter ?? SymphonySetupScopeSelectionPresenter()
        self.previewViewModel = previewViewModel
    }

    public func withPreviewViewModel(
        _ previewViewModel: SymphonySetupScopeSelectionViewModel
    ) -> SymphonySetupScopeSelectionController {
        SymphonySetupScopeSelectionController(
            trackerScopeService: trackerScopeService,
            presenter: presenter,
            previewViewModel: previewViewModel
        )
    }

    public func loadingViewModel(
        trackerKind: String
    ) -> SymphonySetupScopeSelectionViewModel {
        presenter.presentLoading(trackerKind: trackerKind)
    }

    public func queryViewModel(
        trackerKind: String
    ) async -> SymphonySetupScopeSelectionViewModel {
        if let previewViewModel {
            return previewViewModel
        }

        let trackerConfiguration = SymphonyServiceConfigContract.Tracker(
            kind: trackerKind,
            endpoint: nil,
            projectSlug: nil,
            teamID: nil,
            activeStateTypes: [],
            terminalStateTypes: []
        )

        do {
            return presenter.present(
                try await trackerScopeService.queryAvailableScopes(using: trackerConfiguration),
                trackerKind: trackerKind
            )
        } catch {
            return presenter.presentError(error, trackerKind: trackerKind)
        }
    }
}
