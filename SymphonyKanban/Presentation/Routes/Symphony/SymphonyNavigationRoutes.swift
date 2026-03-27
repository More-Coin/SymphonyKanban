import SwiftUI

// MARK: - SymphonyNavigationRoutes
/// Route coordinator that composes the sidebar, content router,
/// and inspector panel by wiring controllers to their respective views.
/// All visual rendering is delegated to View files in Views/Symphony.

@MainActor
public struct SymphonyNavigationRoutes: View {
    private let dashboardController: SymphonyDashboardController
    private let issueDetailController: SymphonyIssueDetailController
    private let refreshController: SymphonyRefreshController

    @State private var selectedTab: SymphonyTabViewModel = .board
    @State private var selectedIssueIdentifier: String?
    @State private var showInspector = false
    @State private var showAuthSheet = false
    @State private var isRefreshing = false
    @State private var isLinearConnected = false
    @State private var isCodexConnected = false

    public init(
        dashboardController: SymphonyDashboardController,
        issueDetailController: SymphonyIssueDetailController,
        refreshController: SymphonyRefreshController,
        initialSelectedIssueIdentifier: String? = nil
    ) {
        self.dashboardController = dashboardController
        self.issueDetailController = issueDetailController
        self.refreshController = refreshController
        _selectedIssueIdentifier = State(initialValue: initialSelectedIssueIdentifier)
    }

    public var body: some View {
        NavigationSplitView {
            SymphonySidebarView(
                selectedTab: $selectedTab,
                isLinearConnected: isLinearConnected,
                isCodexConnected: isCodexConnected,
                onIntegrationTapped: handleIntegrationTapped
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: SymphonyDesignStyle.Sidebar.width, max: 260)
        } detail: {
            SymphonyContentRouterView(
                selectedTab: selectedTab,
                isRefreshing: isRefreshing,
                selectedIssueIdentifier: selectedIssueIdentifier,
                showInspector: showInspector,
                onCardSelected: handleIssueSelected,
                onRefreshTapped: handleRefresh,
                onToggleInspector: handleToggleInspector
            )
        }
        .background(SymphonyDesignStyle.Background.primary.ignoresSafeArea())
        .inspector(isPresented: $showInspector) {
            SymphonyInspectorPanelView(
                issueDetailView: selectedIssueIdentifier.map { id in
                    AnyView(issueDetailController.run(issueIdentifier: id))
                }
            )
            .inspectorColumnWidth(min: 380, ideal: 480, max: 600)
        }
        .onChange(of: selectedIssueIdentifier) { _, newValue in
            withAnimation(SymphonyDesignStyle.Motion.smooth) {
                showInspector = newValue != nil
            }
        }
        .sheet(isPresented: $showAuthSheet) {
            SymphonyAuthView()
                .frame(minWidth: 520, minHeight: 480)
        }
    }

    // MARK: - Route Actions

    private func handleIssueSelected(_ issueIdentifier: String) {
        withAnimation(SymphonyDesignStyle.Motion.snappy) {
            selectedIssueIdentifier = issueIdentifier
            showInspector = true
        }
    }

    private func handleToggleInspector() {
        withAnimation(SymphonyDesignStyle.Motion.smooth) {
            showInspector.toggle()
        }
    }

    private func handleIntegrationTapped(_ service: String) {
        withAnimation(SymphonyDesignStyle.Motion.smooth) {
            showAuthSheet = true
        }
    }

    private func handleRefresh() {
        isRefreshing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(SymphonyDesignStyle.Motion.smooth) {
                isRefreshing = false
            }
        }
    }
}

#Preview {
    SymphonyNavigationRoutes(
        dashboardController: SymphonyDashboardController(
            runtimeQueryService: SymphonyUIDI.makeRuntimeQueryService()
        ),
        issueDetailController: SymphonyIssueDetailController(
            runtimeQueryService: SymphonyUIDI.makeRuntimeQueryService()
        ),
        refreshController: SymphonyRefreshController(),
        initialSelectedIssueIdentifier: "KAN-142"
    )
    .frame(width: 1200, height: 800)
}
