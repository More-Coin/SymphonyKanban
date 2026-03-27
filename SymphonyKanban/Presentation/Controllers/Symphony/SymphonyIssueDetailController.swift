@MainActor
public struct SymphonyIssueDetailController {
    private let runtimeQueryService: SymphonyRuntimeQueryService
    private let presenter: SymphonyIssueDetailPresenter
    private let renderer: SymphonyIssueDetailRenderer

    public init(
        runtimeQueryService: SymphonyRuntimeQueryService,
        presenter: SymphonyIssueDetailPresenter? = nil,
        renderer: SymphonyIssueDetailRenderer? = nil
    ) {
        self.runtimeQueryService = runtimeQueryService
        self.presenter = presenter ?? SymphonyIssueDetailPresenter()
        self.renderer = renderer ?? SymphonyIssueDetailRenderer()
    }

    public func run(issueIdentifier: String? = nil) -> SymphonyIssueDetailView {
        let request = SymphonyIssueDetailRequestDTO(issueIdentifier: issueIdentifier)
        let result = runtimeQueryService.queryIssueDetailSnapshot(
            issueIdentifier: request.queryParams().issueIdentifier ?? ""
        )
        let viewModel = presenter.present(result)
        return renderer.render(viewModel)
    }
}
