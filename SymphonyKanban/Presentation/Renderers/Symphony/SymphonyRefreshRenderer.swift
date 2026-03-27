import SwiftUI

@MainActor
public struct SymphonyRefreshRenderer {
    public init() {}

    @MainActor
    public func render(
        _ viewModel: SymphonyRefreshTriggerViewModel,
        onRefreshTapped: @escaping () -> Void = {}
    ) -> SymphonyRefreshTriggerView {
        SymphonyRefreshTriggerView(
            viewModel: viewModel,
            onRefreshTapped: onRefreshTapped
        )
    }
}
