import SwiftUI

// MARK: - SymphonyNavigationRoutes
/// Route coordinator that composes the sidebar, content router,
/// and inspector panel by wiring controllers to their respective views.
/// All visual rendering is delegated to View files in Views/Symphony.

@MainActor
public struct SymphonyNavigationRoutes: View {
    private let issueDetailController: SymphonyIssueDetailController
    private let authController: SymphonyAuthController
    private let launchTrackerAuthorizationURL: @MainActor (URL) throws -> Void
    @Binding private var pendingTrackerAuthCallbackURL: URL?

    @State private var selectedTab: SymphonyTabViewModel = .board
    @State private var selectedIssueIdentifier: String?
    @State private var showInspector = false
    @State private var showAuthSheet = false
    @State private var isRefreshing = false
    @State private var authViewModel = SymphonyAuthView.mockViewModel
    @State private var isCodexConnected = false

    public init(
        issueDetailController: SymphonyIssueDetailController,
        authController: SymphonyAuthController,
        pendingTrackerAuthCallbackURL: Binding<URL?> = .constant(nil),
        launchTrackerAuthorizationURL: @escaping @MainActor (URL) throws -> Void = { _ in },
        initialSelectedIssueIdentifier: String? = nil
    ) {
        self.issueDetailController = issueDetailController
        self.authController = authController
        self._pendingTrackerAuthCallbackURL = pendingTrackerAuthCallbackURL
        self.launchTrackerAuthorizationURL = launchTrackerAuthorizationURL
        _selectedIssueIdentifier = State(initialValue: initialSelectedIssueIdentifier)
    }

    public var body: some View {
        NavigationSplitView {
            SymphonySidebarView(
                selectedTab: $selectedTab,
                isLinearConnected: authViewModel.linearService?.isConnected == true,
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
        .task {
            await refreshAuthViewModel()
        }
        .onChange(of: pendingTrackerAuthCallbackURL) { _, newValue in
            guard let callbackURL = newValue else {
                return
            }

            Task {
                authViewModel = await authController.completeAuthorizationViewModel(
                    from: callbackURL
                )
                if authViewModel.linearService?.isConnected == true {
                    showAuthSheet = false
                }
                pendingTrackerAuthCallbackURL = nil
            }
        }
        .sheet(isPresented: $showAuthSheet) {
            SymphonyAuthView(
                viewModel: authViewModel,
                onConnect: handleAuthConnect,
                onDisconnect: handleAuthDisconnect
            )
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
        Task {
            await refreshAuthViewModel()
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

    private func handleAuthConnect(
        _ service: SymphonyAuthServiceViewModel
    ) {
        Task {
            do {
                let result = try await authController.startAuthorization()
                guard let url = URL(string: result.browserLaunchURL) else {
                    authViewModel = authController.errorViewModel(
                        for: SymphonyTrackerAuthPresentationError.invalidAuthorizationURL
                    )
                    return
                }

                authViewModel = await authController.viewModelAfterStartingAuthorization()
                try launchTrackerAuthorizationURL(url)
            } catch {
                authViewModel = authController.errorViewModel(for: error)
            }
        }
    }

    private func handleAuthDisconnect(
        _ service: SymphonyAuthServiceViewModel
    ) {
        Task {
            authViewModel = await authController.disconnectViewModel()
        }
    }

    private func refreshAuthViewModel() async {
        authViewModel = await authController.queryViewModel()
    }
}

#Preview {
    SymphonyNavigationRoutes(
        issueDetailController: SymphonyIssueDetailController(
            runtimeQueryService: SymphonyUIDI.makeRuntimeQueryService()
        ),
        authController: SymphonyUIDI.makeAuthController(),
        initialSelectedIssueIdentifier: "KAN-142"
    )
    .frame(width: 1200, height: 800)
}
