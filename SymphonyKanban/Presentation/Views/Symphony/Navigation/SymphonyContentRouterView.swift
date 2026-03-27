import SwiftUI

// MARK: - SymphonyContentRouterView
/// Main content area that renders the active tab's view and the toolbar.

public struct SymphonyContentRouterView: View {
    let selectedTab: SymphonyTabViewModel
    let isRefreshing: Bool
    let selectedIssueIdentifier: String?
    let showInspector: Bool
    let onCardSelected: (String) -> Void
    let onRefreshTapped: () -> Void
    let onToggleInspector: () -> Void

    @State private var searchText = ""

    public init(
        selectedTab: SymphonyTabViewModel,
        isRefreshing: Bool,
        selectedIssueIdentifier: String?,
        showInspector: Bool,
        onCardSelected: @escaping (String) -> Void,
        onRefreshTapped: @escaping () -> Void,
        onToggleInspector: @escaping () -> Void
    ) {
        self.selectedTab = selectedTab
        self.isRefreshing = isRefreshing
        self.selectedIssueIdentifier = selectedIssueIdentifier
        self.showInspector = showInspector
        self.onCardSelected = onCardSelected
        self.onRefreshTapped = onRefreshTapped
        self.onToggleInspector = onToggleInspector
    }

    public var body: some View {
        ZStack {
            SymphonyDesignStyle.Background.secondary.ignoresSafeArea()

            switch selectedTab {
            case .board:
                SymphonyKanbanBoardView(onCardSelected: onCardSelected)
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
                HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    Button {
                        onRefreshTapped()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(isRefreshing)

                    if selectedIssueIdentifier != nil {
                        Button {
                            onToggleInspector()
                        } label: {
                            Label("Inspector", systemImage: "sidebar.right")
                        }
                    }
                }
            }
        }
    }
}
