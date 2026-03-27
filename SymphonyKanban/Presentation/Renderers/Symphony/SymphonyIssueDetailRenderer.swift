import SwiftUI

@MainActor
public struct SymphonyIssueDetailRenderer {
    public init() {}

    @MainActor
    public func render(_ viewModel: SymphonyIssueDetailViewModel) -> SymphonyIssueDetailView {
        SymphonyIssueDetailView(viewModel: viewModel)
    }
}
