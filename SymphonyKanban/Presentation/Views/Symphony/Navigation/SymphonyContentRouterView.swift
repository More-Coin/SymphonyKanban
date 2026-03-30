import SwiftUI

// MARK: - SymphonyContentRouterView
/// Main content area that renders the active tab's view and the toolbar.

public struct SymphonyContentRouterView: View {
    let selectedTab: SymphonyTabViewModel
    let boardViewModel: SymphonyKanbanBoardViewModel
    let issueListViewModel: SymphonyIssueListViewModel
    let issueBannerMessage: String?
    let isRefreshing: Bool
    let onCardSelected: (String) -> Void
    let onRefreshTapped: () -> Void
    let onDismissInspector: () -> Void

    @State private var searchText = ""

    public init(
        selectedTab: SymphonyTabViewModel,
        boardViewModel: SymphonyKanbanBoardViewModel,
        issueListViewModel: SymphonyIssueListViewModel,
        issueBannerMessage: String? = nil,
        isRefreshing: Bool,
        onCardSelected: @escaping (String) -> Void,
        onRefreshTapped: @escaping () -> Void,
        onDismissInspector: @escaping () -> Void = {}
    ) {
        self.selectedTab = selectedTab
        self.boardViewModel = boardViewModel
        self.issueListViewModel = issueListViewModel
        self.issueBannerMessage = issueBannerMessage
        self.isRefreshing = isRefreshing
        self.onCardSelected = onCardSelected
        self.onRefreshTapped = onRefreshTapped
        self.onDismissInspector = onDismissInspector
    }

    public var body: some View {
        ZStack {
            SymphonyDesignStyle.Background.secondary.ignoresSafeArea()

            VStack(spacing: 0) {
                if let issueBannerMessage,
                   issueBannerMessage.isEmpty == false {
                    issueBanner(issueBannerMessage)
                }

                switch selectedTab {
                case .board:
                    SymphonyKanbanBoardView(
                        viewModel: boardViewModel,
                        onCardSelected: onCardSelected,
                        onBackgroundTapped: onDismissInspector
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                case .list:
                    SymphonyIssueListView(
                        viewModel: issueListViewModel,
                        onIssueSelected: onCardSelected
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                case .timeline:
                    SymphonyActivityTimelineView()
                        .transition(.opacity.combined(with: .move(edge: .bottom)))

                case .agents:
                    SymphonyAgentManagementView()
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
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

    private func issueBanner(_ message: String) -> some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(SymphonyDesignStyle.Accent.coral)
            Text(message)
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
            Spacer()
        }
        .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)
        .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
        .background(SymphonyDesignStyle.Background.tertiary)
        .overlay(alignment: .bottom) {
            SymphonyDividerView()
        }
    }
}
