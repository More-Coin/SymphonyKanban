import Testing
@testable import SymphonyKanban

@Suite
struct SymphonySetupScopeSelectionPresenterTests {
    @Test
    func presenterMapsLoadedOptionsIntoSingleSelectionViewModel() {
        let presenter = SymphonySetupScopeSelectionPresenter()

        let viewModel = presenter.present(
            SymphonyTrackerScopeDiscoveryResultContract(
                options: [
                    SymphonyTrackerScopeOptionContract(
                        id: "team:ios",
                        scopeKind: "team",
                        scopeIdentifier: "ios",
                        scopeName: "iOS",
                        detailText: "Team key IOS"
                    ),
                    SymphonyTrackerScopeOptionContract(
                        id: "project:mobile-rebuild",
                        scopeKind: "project",
                        scopeIdentifier: "mobile-rebuild",
                        scopeName: "Mobile Rebuild",
                        detailText: "planned • iOS"
                    )
                ]
            ),
            trackerKind: "linear"
        )

        #expect(viewModel.state == .loaded)
        #expect(viewModel.message.contains("single"))
        #expect(viewModel.options.map(\.scopeKindLabel) == ["Team", "Project"])
        #expect(viewModel.options.map(\.scopeIdentifier) == ["ios", "mobile-rebuild"])
    }

    @Test
    func presenterMapsLoadingEmptyAndFailedStates() {
        let presenter = SymphonySetupScopeSelectionPresenter()

        let loadingViewModel = presenter.presentLoading(trackerKind: "linear")
        let emptyViewModel = presenter.present(
            SymphonyTrackerScopeDiscoveryResultContract(
                options: []
            ),
            trackerKind: "linear"
        )
        let failedViewModel = presenter.presentError(
            SymphonyIssueTrackerInfrastructureError.linearGraphQLErrors(
                messages: ["Forbidden"]
            ),
            trackerKind: "linear"
        )

        #expect(loadingViewModel.state == .loading)
        #expect(emptyViewModel.state == .empty)
        #expect(failedViewModel.state == .failed)
        #expect(failedViewModel.errorMessage?.contains("Forbidden") == true)
    }
}
