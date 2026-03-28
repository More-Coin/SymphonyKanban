import SwiftUI

// MARK: - SymphonyContentRouterView
/// Main content area that renders the active tab's view and the toolbar.

public struct SymphonyContentRouterView: View {
    let selectedTab: SymphonyTabViewModel
    let isRefreshing: Bool
    let onCardSelected: (String) -> Void
    let onRefreshTapped: () -> Void
    let onDismissInspector: () -> Void

    @State private var searchText = ""

    public init(
        selectedTab: SymphonyTabViewModel,
        isRefreshing: Bool,
        onCardSelected: @escaping (String) -> Void,
        onRefreshTapped: @escaping () -> Void,
        onDismissInspector: @escaping () -> Void = {}
    ) {
        self.selectedTab = selectedTab
        self.isRefreshing = isRefreshing
        self.onCardSelected = onCardSelected
        self.onRefreshTapped = onRefreshTapped
        self.onDismissInspector = onDismissInspector
    }

    public var body: some View {
        ZStack {
            SymphonyDesignStyle.Background.secondary.ignoresSafeArea()

            switch selectedTab {
            case .board:
                SymphonyKanbanBoardView(onCardSelected: onCardSelected, onBackgroundTapped: onDismissInspector)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

            case .list:
                SymphonyIssueListView(onIssueSelected: onCardSelected)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

            case .timeline:
                SymphonyActivityTimelineView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

            case .agents:
                SymphonyAgentManagementView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(SymphonyDesignStyle.Motion.smooth, value: selectedTab)
        .searchable(text: $searchText, prompt: "Search issues...")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    onRefreshTapped()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(isRefreshing)
            }
        }
    }
}
