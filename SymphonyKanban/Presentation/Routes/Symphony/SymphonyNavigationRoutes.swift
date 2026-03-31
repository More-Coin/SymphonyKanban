import SwiftUI

// MARK: - SymphonyNavigationRoutes
/// Route coordinator that composes the sidebar, content router,
/// and inspector panel by wiring controllers to their respective views.
/// All visual rendering is delegated to View files in Views/Symphony.

@MainActor
public struct SymphonyNavigationRoutes: View {
    private let issueDetailController: SymphonyIssueDetailController
    private let issueCatalogController: SymphonyIssueCatalogController
    private let authController: SymphonyAuthController
    private let codexConnectionController: SymphonyCodexConnectionController
    private let bindingManagementController: SymphonyWorkspaceBindingManagementController
    private let workspaceSelectionController: SymphonyWorkspaceSelectionController
    private let workspaceBindingSetupController: SymphonyWorkspaceBindingSetupController
    private let chooseWorkspaceDirectory: @MainActor (String?) -> String?
    private let launchTrackerAuthorizationURL: @MainActor (URL) throws -> Void
    private let prepareTrackerAuthorizationCallbackListener: @MainActor () async throws -> Void
    private let awaitTrackerAuthorizationCallback: @MainActor () async throws -> SymphonyTrackerAuthCallbackContract
    private let cancelTrackerAuthorizationCallbackListener: @MainActor () async -> Void
    private let failedBindingCount: Int
    private let activeBindingCount: Int

    @State private var selectedTab: SymphonyTabViewModel = .board
    @State private var selectedIssueIdentifier: String?
    @State private var showInspector = false
    @State private var showAuthSheet = false
    @State private var showBindingsSheet = false
    @State private var showCodexStatusAlert = false
    @State private var bindingsViewModel: SymphonyWorkspaceBindingManagementViewModel?
    @State private var isRefreshing = false
    @State private var authViewModel = SymphonyAuthView.mockViewModel
    @State private var isCodexConnected = false
    @State private var issueCatalogViewModel: SymphonyIssueCatalogViewModel?
    @State private var issueLoadErrorMessage: String?
    @State private var codexConnectionViewModel = SymphonyCodexConnectionViewModel(
        isConnected: false,
        title: "Codex Login Required",
        message: "Codex verification has not run yet."
    )

    public init(
        issueDetailController: SymphonyIssueDetailController,
        issueCatalogController: SymphonyIssueCatalogController,
        authController: SymphonyAuthController,
        codexConnectionController: SymphonyCodexConnectionController,
        bindingManagementController: SymphonyWorkspaceBindingManagementController,
        workspaceSelectionController: SymphonyWorkspaceSelectionController,
        workspaceBindingSetupController: SymphonyWorkspaceBindingSetupController,
        chooseWorkspaceDirectory: @escaping @MainActor (String?) -> String? = { _ in nil },
        launchTrackerAuthorizationURL: @escaping @MainActor (URL) throws -> Void = { _ in },
        prepareTrackerAuthorizationCallbackListener: @escaping @MainActor () async throws -> Void = {},
        awaitTrackerAuthorizationCallback: @escaping @MainActor () async throws -> SymphonyTrackerAuthCallbackContract = {
            throw SymphonyTrackerAuthPresentationError.callbackListenerFailed(
                details: "The callback listener was not configured."
            )
        },
        cancelTrackerAuthorizationCallbackListener: @escaping @MainActor () async -> Void = {},
        initialSelectedIssueIdentifier: String? = nil,
        failedBindingCount: Int = 0,
        activeBindingCount: Int = 0
    ) {
        self.issueDetailController = issueDetailController
        self.issueCatalogController = issueCatalogController
        self.authController = authController
        self.codexConnectionController = codexConnectionController
        self.bindingManagementController = bindingManagementController
        self.workspaceSelectionController = workspaceSelectionController
        self.workspaceBindingSetupController = workspaceBindingSetupController
        self.chooseWorkspaceDirectory = chooseWorkspaceDirectory
        self.launchTrackerAuthorizationURL = launchTrackerAuthorizationURL
        self.prepareTrackerAuthorizationCallbackListener = prepareTrackerAuthorizationCallbackListener
        self.awaitTrackerAuthorizationCallback = awaitTrackerAuthorizationCallback
        self.cancelTrackerAuthorizationCallbackListener = cancelTrackerAuthorizationCallbackListener
        self.failedBindingCount = failedBindingCount
        self.activeBindingCount = activeBindingCount
        _selectedIssueIdentifier = State(initialValue: initialSelectedIssueIdentifier)
    }

    public var body: some View {
        NavigationSplitView {
            SymphonySidebarView(
                selectedTab: $selectedTab,
                isLinearConnected: authViewModel.linearService?.isConnected == true,
                isCodexConnected: isCodexConnected,
                onIntegrationTapped: handleIntegrationTapped,
                onSettingsTapped: handleSettingsTapped
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: SymphonyDesignStyle.Sidebar.width, max: 260)
        } detail: {
            SymphonyContentRouterView(
                selectedTab: selectedTab,
                boardViewModel: issueCatalogViewModel?.boardViewModel ?? SymphonyPreviewDI.makeBoardViewModel(),
                issueListViewModel: issueCatalogViewModel?.listViewModel ?? SymphonyPreviewDI.makeIssueListViewModel(),
                issueBannerMessage: issueLoadErrorMessage ?? issueCatalogViewModel?.mutationErrorMessage,
                isRefreshing: isRefreshing,
                failedBindingCount: failedBindingCount,
                activeBindingCount: activeBindingCount,
                onCardSelected: handleIssueSelected,
                onCancelIssue: handleCancelIssue,
                onRefreshTapped: handleRefresh,
                onDismissInspector: handleDismissInspector,
                onBannerTapped: handleSettingsTapped
            )
        }
        .background(SymphonyDesignStyle.Background.primary.ignoresSafeArea())
        .inspector(isPresented: $showInspector) {
            SymphonyInspectorPanelView(
                issueDetailView: selectedIssueIdentifier.map { id in
                    AnyView(
                        issueDetailController.run(
                            issueIdentifier: id,
                            issue: issueCatalogViewModel?.issuesByIdentifier[id]
                        )
                    )
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
            try? await Task.sleep(nanoseconds: 100_000_000)
            await refreshConnectionState()
            await Task.yield()
            await refreshIssueCatalog()
        }
        .sheet(isPresented: $showAuthSheet) {
            SymphonyAuthView(
                viewModel: authViewModel,
                onConnect: handleAuthConnect,
                onDisconnect: handleAuthDisconnect,
                onDismiss: { showAuthSheet = false }
            )
                .frame(minWidth: 520, minHeight: 480)
        }
        .alert(
            codexConnectionViewModel.title,
            isPresented: $showCodexStatusAlert
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(codexConnectionViewModel.message)
        }
        .sheet(isPresented: $showBindingsSheet) {
            SymphonyWorkspaceBindingManagementView(
                viewModel: bindingsViewModel ?? bindingManagementController.queryViewModel(),
                onChooseFolder: handleChooseFolder,
                onRemoveBinding: handleRemoveBinding,
                onDismiss: { showBindingsSheet = false }
            )
            .frame(minWidth: 560, minHeight: 520)
        }
    }

    // MARK: - Route Actions

    private func handleSettingsTapped() {
        bindingsViewModel = bindingManagementController.queryViewModel()
        showBindingsSheet = true
    }

    private func handleChooseFolder(
        _ card: SymphonyWorkspaceBindingManagementViewModel.Card
    ) {
        guard let chosenPath = chooseWorkspaceDirectory(card.workspacePath) else {
            return
        }

        let validationResult = workspaceSelectionController.selectWorkspace(
            workspacePath: chosenPath,
            scopeKind: card.scopeKind,
            scopeIdentifier: card.scopeIdentifier,
            scopeName: card.scopeName
        )

        guard validationResult.state == .selected,
              let selection = validationResult.selection else {
            let bannerMessage = validationResult.errorMessage
                ?? "Symphony could not validate the selected workspace folder."

            withAnimation(SymphonyDesignStyle.Motion.smooth) {
                bindingsViewModel = bindingManagementController.queryViewModel(
                    bannerMessage: bannerMessage
                )
            }
            return
        }

        withAnimation(SymphonyDesignStyle.Motion.smooth) {
            bindingsViewModel = bindingManagementController.updateBindingWorkspace(
                existingWorkspacePath: card.workspacePath,
                newWorkspacePath: selection.workspacePath,
                explicitWorkflowPath: selection.explicitWorkflowPath,
                trackerKind: card.trackerKind,
                scopeKind: card.scopeKind,
                scopeIdentifier: card.scopeIdentifier,
                scopeName: card.scopeName
            )
        }
    }

    private func handleRemoveBinding(
        _ card: SymphonyWorkspaceBindingManagementViewModel.Card
    ) {
        withAnimation(SymphonyDesignStyle.Motion.smooth) {
            bindingsViewModel = bindingManagementController.removeBinding(
                forWorkspacePath: card.workspacePath
            )
        }
    }

    private func handleIssueSelected(_ issueIdentifier: String) {
        withAnimation(SymphonyDesignStyle.Motion.snappy) {
            selectedIssueIdentifier = issueIdentifier
            showInspector = true
        }
    }

    private func handleCancelIssue(_ issueIdentifier: String) {
        Task {
            do {
                issueCatalogViewModel = try await issueCatalogController.updatingIssueViewModel(
                    issueIdentifier: issueIdentifier,
                    selectedIssueIdentifier: selectedIssueIdentifier
                )

                issueCatalogViewModel = try await issueCatalogController.cancelIssueViewModel(
                    issueIdentifier: issueIdentifier,
                    selectedIssueIdentifier: selectedIssueIdentifier
                )
            } catch {
                issueLoadErrorMessage = structuredMessage(for: error)
            }
        }
    }

    private func handleDismissInspector() {
        guard showInspector else { return }
        withAnimation(SymphonyDesignStyle.Motion.smooth) {
            selectedIssueIdentifier = nil
        }
    }

    private func handleIntegrationTapped(_ service: String) {
        switch service.lowercased() {
        case "codex":
            Task {
                await refreshCodexConnectionViewModel()
                showCodexStatusAlert = true
            }
        default:
            withAnimation(SymphonyDesignStyle.Motion.smooth) {
                showAuthSheet = true
            }
            Task {
                await refreshAuthViewModel()
            }
        }
    }

    private func handleRefresh() {
        Task {
            isRefreshing = true
            await refreshConnectionState()
            await refreshIssueCatalog()
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
                try await prepareTrackerAuthorizationCallbackListener()
                let result = try await authController.startAuthorization()
                guard let url = URL(string: result.browserLaunchURL) else {
                    await cancelTrackerAuthorizationCallbackListener()
                    authViewModel = authController.errorViewModel(
                        for: SymphonyTrackerAuthPresentationError.invalidAuthorizationURL
                    )
                    return
                }

                authViewModel = await authController.viewModelAfterStartingAuthorization()
                try launchTrackerAuthorizationURL(url)
                let callback = try await awaitTrackerAuthorizationCallback()
                authViewModel = await authController.completeAuthorizationViewModel(using: callback)
                if authViewModel.linearService?.isConnected == true {
                    await refreshIssueCatalog()
                    showAuthSheet = false
                }
            } catch {
                await cancelTrackerAuthorizationCallbackListener()
                authViewModel = authController.errorViewModel(for: error)
            }
        }
    }

    private func handleAuthDisconnect(
        _ service: SymphonyAuthServiceViewModel
    ) {
        Task {
            authViewModel = await authController.disconnectViewModel()
            await refreshIssueCatalog()
        }
    }

    private func refreshAuthViewModel() async {
        authViewModel = await authController.queryViewModel()
    }

    private func refreshCodexConnectionViewModel() async {
        let viewModel = codexConnectionController.queryViewModel()
        codexConnectionViewModel = viewModel
        isCodexConnected = viewModel.isConnected
    }

    private func refreshConnectionState() async {
        await refreshAuthViewModel()
        await refreshCodexConnectionViewModel()
    }

    private func refreshIssueCatalog() async {
        do {
            issueCatalogViewModel = try await issueCatalogController.queryViewModel(
                selectedIssueIdentifier: selectedIssueIdentifier
            )
            issueLoadErrorMessage = nil
        } catch {
            issueLoadErrorMessage = structuredMessage(for: error)
        }
    }

    private func structuredMessage(
        for error: any Error
    ) -> String {
        if let structuredError = error as? any StructuredErrorProtocol {
            guard let details = structuredError.details,
                  !details.isEmpty else {
                return structuredError.message
            }

            return "\(structuredError.message) \(details)"
        }

        return error.localizedDescription
    }
}

#Preview {
    SymphonyPreviewDI.makeNavigationRoutes()
    .frame(width: 1200, height: 800)
}
