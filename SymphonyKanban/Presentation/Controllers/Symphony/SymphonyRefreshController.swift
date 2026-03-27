import Foundation

@MainActor
public struct SymphonyRefreshController {
    private let presenter: SymphonyRefreshPresenter
    private let renderer: SymphonyRefreshRenderer

    public init(
        presenter: SymphonyRefreshPresenter? = nil,
        renderer: SymphonyRefreshRenderer? = nil
    ) {
        self.presenter = presenter ?? SymphonyRefreshPresenter()
        self.renderer = renderer ?? SymphonyRefreshRenderer()
    }

    public func run(
        source: String? = nil,
        lastRefreshedAt: Date? = nil,
        isRefreshing: Bool = false,
        note: String? = nil,
        requestedAt: Date = .now,
        onRefreshTapped: @escaping () -> Void = {}
    ) -> SymphonyRefreshTriggerView {
        let request = SymphonyRefreshRequestDTO(
            requestedAt: requestedAt,
            source: source,
            lastRefreshedAt: lastRefreshedAt,
            isRefreshing: isRefreshing,
            note: note
        )
        let viewModel = presenter.present(request.requestContract())
        return renderer.render(viewModel, onRefreshTapped: onRefreshTapped)
    }
}
