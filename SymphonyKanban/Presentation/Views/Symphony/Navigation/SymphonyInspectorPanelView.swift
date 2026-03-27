import SwiftUI

// MARK: - SymphonyInspectorPanelView
/// Right-side inspector that shows issue detail via the detail controller.

public struct SymphonyInspectorPanelView: View {
    let issueDetailView: AnyView?

    public init(issueDetailView: AnyView?) {
        self.issueDetailView = issueDetailView
    }

    public var body: some View {
        ScrollView {
            if let issueDetailView {
                issueDetailView
                    .padding(SymphonyDesignStyle.Spacing.lg)
            } else {
                emptyState
            }
        }
        .background(SymphonyDesignStyle.Background.primary.ignoresSafeArea())
    }

    private var emptyState: some View {
        SymphonyEmptyStateView(
            icon: "doc.text.magnifyingglass",
            title: "No Issue Selected",
            message: "Select a card from the board or an issue from the list to inspect its details."
        )
    }
}
