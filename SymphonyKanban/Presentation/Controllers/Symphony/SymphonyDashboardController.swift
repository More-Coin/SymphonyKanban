@MainActor
public struct SymphonyDashboardController {
    private let runtimeQueryService: SymphonyRuntimeQueryService
    private let presenter: SymphonyDashboardPresenter
    private let renderer: SymphonyDashboardRenderer

    public init(
        runtimeQueryService: SymphonyRuntimeQueryService,
        presenter: SymphonyDashboardPresenter? = nil,
        renderer: SymphonyDashboardRenderer? = nil
    ) {
        self.runtimeQueryService = runtimeQueryService
        self.presenter = presenter ?? SymphonyDashboardPresenter()
        self.renderer = renderer ?? SymphonyDashboardRenderer()
    }

    public func run(
        selectedIssueIdentifier: String? = nil,
        onIssueSelected: @escaping (String) -> Void = { _ in }
    ) -> SymphonyDashboardView {
        let request = SymphonyDashboardRequestDTO(
            selectedIssueIdentifier: selectedIssueIdentifier
        )
        let result = runtimeQueryService.queryDashboardSnapshot()
        let viewModel = presenter.present(
            result,
            selectedIssueIdentifier: request.requestContract().selectedIssueIdentifier
        )
        return renderer.render(
            viewModel,
            onIssueSelected: onIssueSelected
        )
    }
}
