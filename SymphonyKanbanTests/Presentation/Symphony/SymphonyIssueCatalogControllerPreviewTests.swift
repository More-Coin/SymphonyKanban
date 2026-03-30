import Testing
@testable import SymphonyKanban

@MainActor
@Suite
struct SymphonyIssueCatalogControllerPreviewTests {
    @Test
    func queryViewModelReturnsPreviewOverrideWhenConfigured() async throws {
        let previewViewModel = SymphonyIssueCatalogViewModel(
            displayMode: .groupedSections,
            issuesByIdentifier: [:],
            boardViewModel: SymphonyKanbanBoardViewModel(columns: []),
            listViewModel: SymphonyIssueListViewModel(rows: []),
            activeBindingCount: 2,
            loadedBindingCount: 1,
            failedBindingCount: 1
        )
        let controller = SymphonyIssueCatalogController(
            startupService: SymphonyStartupFlowTestSupport.makeStartupService(),
            issueCatalogService: SymphonyIssueCatalogService(
                fetchIssuesUseCase: FetchSymphonyIssuesUseCase(
                    issueTrackerReadPort: SymphonyMockIssueTrackerPortAdapter()
                )
            ),
            displayPreferenceService: SymphonyIssueCatalogDisplayPreferenceService(
                queryDisplayModeUseCase: QuerySymphonyIssueCatalogDisplayModeUseCase(
                    preferencePort: IssueCatalogDisplayModePreferencePortPreviewSpy()
                ),
                saveDisplayModeUseCase: SaveSymphonyIssueCatalogDisplayModeUseCase(
                    preferencePort: IssueCatalogDisplayModePreferencePortPreviewSpy()
                )
            )
        )
        .withPreviewViewModel(previewViewModel)

        let viewModel = try await controller.queryViewModel(selectedIssueIdentifier: nil)

        #expect(viewModel == previewViewModel)
    }
}

private final class IssueCatalogDisplayModePreferencePortPreviewSpy:
    SymphonyIssueCatalogDisplayModePreferencePortProtocol,
    @unchecked Sendable
{
    func queryDisplayMode() throws -> SymphonyIssueCatalogDisplayModeContract? {
        .groupedSections
    }

    func saveDisplayMode(
        _: SymphonyIssueCatalogDisplayModeContract
    ) throws {}
}
