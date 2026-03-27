import SwiftUI

@MainActor
public struct SymphonyDashboardRenderer {
    public init() {}

    @MainActor
    public func render(
        _ viewModel: SymphonyDashboardViewModel,
        onIssueSelected: @escaping (String) -> Void = { _ in }
    ) -> SymphonyDashboardView {
        SymphonyDashboardView(
            viewModel: viewModel,
            onIssueSelected: onIssueSelected
        )
    }
}
