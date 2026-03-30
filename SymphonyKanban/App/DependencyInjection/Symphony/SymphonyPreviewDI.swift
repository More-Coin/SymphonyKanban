import Foundation
import SwiftUI

@MainActor
public enum SymphonyPreviewDI {
    public enum StartupPreviewState: Equatable {
        case loading
        case ready
        case setupRequired
        case failed
        case readyDegraded
    }

    public enum AuthPreviewState: Equatable {
        case disconnected
        case connecting
        case connected
        case error
    }

    public enum CodexPreviewState: Equatable {
        case connected
        case disconnected
    }

    public enum IssueDetailPreviewState: Equatable {
        case missionControl
        case empty
    }

    public static func makeRootPreview() -> some View {
        makeStartupGate(startupState: .readyDegraded)
    }

    public static func makeStartupGate(
        startupState: StartupPreviewState = .readyDegraded
    ) -> SymphonyStartupGateView {
        SymphonyStartupGateView(
            previewViewModel: makeStartupStatusViewModel(startupState),
            navigationRoutesBuilder: { viewModel in
                AnyView(
                    makeNavigationRoutes(
                        failedBindingCount: viewModel.failedBindingCount,
                        activeBindingCount: viewModel.activeBindingCount
                    )
                )
            },
            setupViewBuilder: { _, onComplete in
                AnyView(
                    makeWorkspaceBindingSetupView(
                        mode: .firstRun,
                        authState: .connected,
                        onComplete: onComplete
                    )
                )
            }
        )
    }

    public static func makeNavigationRoutes(
        failedBindingCount: Int = 1,
        activeBindingCount: Int = 2,
        selectedIssueIdentifier: String? = "NARAIOS-142"
    ) -> SymphonyNavigationRoutes {
        SymphonyNavigationRoutes(
            issueDetailController: SymphonyIssueDetailController(
                runtimeQueryService: SymphonyUIDI.makeRuntimeQueryService()
            ),
            issueCatalogController: SymphonyUIDI.makeIssueCatalogController()
                .withPreviewViewModel(
                    makeIssueCatalogViewModel(
                        selectedIssueIdentifier: selectedIssueIdentifier,
                        degraded: failedBindingCount > 0
                    )
                ),
            authController: makeAuthController(state: .connected),
            codexConnectionController: makeCodexConnectionController(state: .connected),
            initialSelectedIssueIdentifier: selectedIssueIdentifier,
            failedBindingCount: failedBindingCount,
            activeBindingCount: activeBindingCount
        )
    }

    public static func makeWorkspaceBindingSetupView(
        mode: SymphonyWorkspaceBindingSetupView.Mode = .firstRun,
        authState: AuthPreviewState = .disconnected,
        onComplete: @escaping (SymphonyWorkspaceLocatorContract) -> Void = { _ in }
    ) -> SymphonyWorkspaceBindingSetupView {
        SymphonyWorkspaceBindingSetupView(
            mode: mode,
            authController: makeAuthController(state: authState),
            scopeSelectionController: makeSetupScopeSelectionController(),
            workspaceSelectionController: makeWorkspaceSelectionController(),
            chooseWorkspaceDirectory: { _ in nil },
            workspaceBindingSetupController: makeWorkspaceBindingSetupController(),
            onComplete: onComplete
        )
    }

    public static func makeSetupScopeSelectionController() -> SymphonySetupScopeSelectionController {
        SymphonyUIDI.makeSetupScopeSelectionController()
            .withPreviewViewModel(
                SymphonySetupScopeSelectionViewModel(
                    state: .loaded,
                    title: "Select Scope",
                    message: "Choose the single team or project this workspace should track.",
                    options: [
                        .init(
                            id: "team:preview-ios",
                            scopeKind: "team",
                            scopeKindLabel: "Team",
                            scopeIdentifier: "preview-ios",
                            scopeName: "Preview iOS",
                            detailText: "Team key IOS"
                        ),
                        .init(
                            id: "project:mobile-rebuild",
                            scopeKind: "project",
                            scopeKindLabel: "Project",
                            scopeIdentifier: "mobile-rebuild",
                            scopeName: "Mobile Rebuild",
                            detailText: "planned • Preview iOS"
                        )
                    ]
                )
            )
    }

    public static func makeWorkspaceBindingSetupController() -> SymphonyWorkspaceBindingSetupController {
        let previewStorageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("symphony-preview-workspace-bindings.json", isDirectory: false)

        return SymphonyWorkspaceBindingSetupController(
            setupService: SymphonyWorkspaceBindingSetupService(
                saveWorkspaceTrackerBindingUseCase: SaveSymphonyWorkspaceTrackerBindingUseCase(
                    workspaceTrackerBindingPort: SymphonyWorkspaceTrackerBindingRepository(
                        storageURL: previewStorageURL
                    )
                )
            )
        )
    }

    public static func makeWorkspaceSelectionController(
        currentWorkingDirectoryPath: String = "/Preview/NaraIOS",
        explicitWorkflowPath: String? = "/Preview/NaraIOS/WORKFLOW.md"
    ) -> SymphonyWorkspaceSelectionController {
        SymphonyUIDI.makeWorkspaceSelectionController()
            .withPreviewViewModel(
                SymphonyWorkspaceSelectionViewModel(
                    state: .selected,
                    title: "Select Workspace",
                    message: "This workspace folder is ready to be saved with the selected tracker scope.",
                    selection: .init(
                        id: currentWorkingDirectoryPath,
                        workspacePath: currentWorkingDirectoryPath,
                        explicitWorkflowPath: explicitWorkflowPath,
                        resolvedWorkflowPath: explicitWorkflowPath ?? "\(currentWorkingDirectoryPath)/WORKFLOW.md",
                        workspaceName: URL(fileURLWithPath: currentWorkingDirectoryPath).lastPathComponent
                    )
                )
            )
    }

    public static func makeAuthController(
        state: AuthPreviewState = .disconnected
    ) -> SymphonyAuthController {
        SymphonyUIDI.makeAuthController()
            .withPreviewViewModel(makeAuthViewModel(state))
    }

    public static func makeCodexConnectionController(
        state: CodexPreviewState = .connected
    ) -> SymphonyCodexConnectionController {
        SymphonyUIDI.makeCodexConnectionController()
            .withPreviewViewModel(makeCodexConnectionViewModel(state))
    }

    public static func makeBoardViewModel(
        degraded: Bool = true,
        selectedIssueIdentifier: String? = "NARAIOS-142"
    ) -> SymphonyKanbanBoardViewModel {
        makeIssueCatalogViewModel(
            selectedIssueIdentifier: selectedIssueIdentifier,
            degraded: degraded
        ).boardViewModel
    }

    public static func makeIssueListViewModel(
        degraded: Bool = true,
        selectedIssueIdentifier: String? = "NARAIOS-142"
    ) -> SymphonyIssueListViewModel {
        makeIssueCatalogViewModel(
            selectedIssueIdentifier: selectedIssueIdentifier,
            degraded: degraded
        ).listViewModel
    }

    public static func makeIssueDetailViewModel(
        _ state: IssueDetailPreviewState
    ) -> SymphonyIssueDetailViewModel {
        switch state {
        case .missionControl:
            return SymphonyIssueDetailViewModel(
                issueIdentifier: "KAN-142",
                title: "Rebuild Symphony dashboard pipeline",
                subtitle: "KAN-142",
                stateLabel: "Doing",
                stateKey: "doing",
                runtimeStatusLabel: "Running",
                priorityLabel: "Priority High",
                labels: ["symphony", "dashboard", "pipeline"],
                descriptionText: "Rebuild the dashboard presentation slice around controller, presenter, and page-level view models. Migrate from legacy SymphonyDashboardStyle to SymphonyDesignStyle.",
                metadataLines: [
                    "Status: Running",
                    "Branch: feature/dashboard-pipeline",
                    "Agent: codex-alpha-7"
                ],
                attemptsLabel: "2 restarts • retry 1",
                generatedAtLabel: "Snapshot 1 minute ago",
                runtimeViewModel: SymphonyIssueRuntimeViewModel(
                    title: "Runtime",
                    stateLabel: "Running",
                    sessionIDLabel: "Session sess-142",
                    threadIDLabel: "Thread thr-142",
                    turnIDLabel: "Turn turn-9",
                    processLabel: "PID 80121",
                    turnCountLabel: "9 turns",
                    startedAtLabel: "Started 54 minutes ago",
                    lastEventLabel: "Last event tool_call",
                    lastMessageLabel: "Patched dashboard presenter",
                    tokenLabel: "16,000 total tokens • 12,000 in • 4,000 out"
                ),
                workspaceViewModel: SymphonyWorkspaceViewModel(
                    title: "Workspace",
                    pathLabel: "/tmp/symphony/workspaces/KAN-142",
                    branchLabel: "feature/dashboard-pipeline",
                    statusLabel: "Running"
                ),
                logsViewModel: SymphonyLogsViewModel(
                    title: "Logs",
                    subtitle: "Codex session output captured for this issue.",
                    emptyState: "No log files are attached to this issue.",
                    entries: [
                        SymphonyLogsViewModel.Entry(
                            label: "Console",
                            subtitle: "/tmp/symphony/logs/KAN-142-console.log",
                            destination: nil
                        )
                    ]
                ),
                recentEventsSectionTitle: "Recent Events",
                recentEventsEmptyState: "No recent events are available.",
                recentEventRows: [
                    SymphonyRecentEventRowViewModel(
                        title: "tool_call",
                        subtitle: "2 minutes ago",
                        detailLines: ["Patched dashboard presenter"]
                    ),
                    SymphonyRecentEventRowViewModel(
                        title: "build",
                        subtitle: "6 minutes ago",
                        detailLines: ["Build succeeded in 28s"]
                    ),
                    SymphonyRecentEventRowViewModel(
                        title: "lint",
                        subtitle: "10 minutes ago",
                        detailLines: ["Architecture linter passed"]
                    )
                ],
                lastErrorTitle: "Last Error",
                lastErrorMessage: "Type mismatch in SymphonyDashboardPresenter: expected IssueDetailViewModel, got IssueCardViewModel",
                lastErrorDetailLines: [
                    "File: SymphonyDashboardPresenter.swift:142",
                    "Resolution: Auto-fixed by agent on retry"
                ],
                trackedSectionTitle: "Tracked Fields",
                trackedFieldLines: [
                    "workflow: dashboard",
                    "agent: codex-alpha-7",
                    "tier: presentation"
                ],
                emptyStateTitle: nil,
                emptyStateMessage: nil
            )

        case .empty:
            return SymphonyIssueDetailViewModel(
                issueIdentifier: "",
                title: "Select an issue",
                subtitle: "Choose a running or queued issue from the dashboard to inspect its runtime context.",
                stateLabel: "Idle",
                stateKey: "idle",
                runtimeStatusLabel: "Idle",
                priorityLabel: nil,
                labels: [],
                descriptionText: nil,
                metadataLines: [],
                attemptsLabel: "No attempts recorded",
                generatedAtLabel: "No runtime snapshot",
                runtimeViewModel: nil,
                workspaceViewModel: nil,
                logsViewModel: SymphonyLogsViewModel(
                    title: "Logs",
                    subtitle: "Runtime logs appear here when a session is active.",
                    emptyState: "No log files are attached to this issue.",
                    entries: []
                ),
                recentEventsSectionTitle: "Recent Events",
                recentEventsEmptyState: "No recent events are available.",
                recentEventRows: [],
                lastErrorTitle: nil,
                lastErrorMessage: nil,
                lastErrorDetailLines: [],
                trackedSectionTitle: "Tracked Fields",
                trackedFieldLines: [],
                emptyStateTitle: "Issue Detail",
                emptyStateMessage: "Pick an issue from the dashboard to view runtime, workspace, logs, and event details."
            )
        }
    }

    public static func makeStartupStatusController(
        state: StartupPreviewState
    ) -> SymphonyStartupStatusController {
        let controller = SymphonyUIDI.makeStartupStatusController()
        guard let previewViewModel = makeStartupStatusViewModel(state) else {
            return controller
        }

        return controller.withPreviewViewModel(previewViewModel)
    }

    public static func makeStartupStatusViewModel(
        _ startupState: StartupPreviewState
    ) -> SymphonyStartupStatusViewModel? {
        switch startupState {
        case .loading:
            return nil

        case .ready:
            return SymphonyStartupStatusViewModel(
                state: .ready,
                title: "Workspaces Ready",
                message: "Loaded 2 of 2 bindings.",
                currentWorkingDirectoryPath: "/Preview/NaraIOS",
                explicitWorkflowPath: "/Preview/NaraIOS/WORKFLOW.md",
                activeBindingCount: 2,
                readyBindingCount: 2,
                failedBindingCount: 0,
                boundScopeNames: ["Nara IOS", "Nara Server"],
                resolvedWorkflowPaths: [
                    "/Preview/NaraIOS/WORKFLOW.md",
                    "/Preview/NaraServer/WORKFLOW.md"
                ],
                trackerStatusLabels: [
                    "Connected to Linear.",
                    "Connected to Linear."
                ]
            )

        case .setupRequired:
            return SymphonyStartupStatusViewModel(
                state: .setupRequired,
                title: "Workspace Setup Required",
                message: "Link this workspace to a tracker scope before loading live issues.",
                currentWorkingDirectoryPath: "/Preview/NaraIOS",
                explicitWorkflowPath: nil,
                activeBindingCount: 0,
                readyBindingCount: 0,
                failedBindingCount: 0,
                boundScopeNames: [],
                resolvedWorkflowPaths: [],
                trackerStatusLabels: []
            )

        case .failed:
            return SymphonyStartupStatusViewModel(
                state: .failed,
                title: "Startup Failed",
                message: "Could not resolve the workspace workflow. Check the saved binding and try again.",
                currentWorkingDirectoryPath: "/Preview/NaraIOS",
                explicitWorkflowPath: "/Preview/NaraIOS/WORKFLOW.md",
                activeBindingCount: 1,
                readyBindingCount: 0,
                failedBindingCount: 1,
                boundScopeNames: ["Nara IOS"],
                resolvedWorkflowPaths: [],
                trackerStatusLabels: ["Linear needs attention."]
            )

        case .readyDegraded:
            return SymphonyStartupStatusViewModel(
                state: .ready,
                title: "Workspaces Ready",
                message: "Loaded 1 of 2 bindings. One workspace still needs attention.",
                currentWorkingDirectoryPath: "/Preview/NaraIOS",
                explicitWorkflowPath: "/Preview/NaraIOS/WORKFLOW.md",
                activeBindingCount: 2,
                readyBindingCount: 1,
                failedBindingCount: 1,
                boundScopeNames: ["Nara IOS", "Nara Server"],
                resolvedWorkflowPaths: ["/Preview/NaraIOS/WORKFLOW.md"],
                trackerStatusLabels: [
                    "Connected to Linear.",
                    "Workflow configuration missing."
                ]
            )
        }
    }

    public static func makeAuthViewModel(
        _ authState: AuthPreviewState
    ) -> SymphonyAuthViewModel {
        let service: SymphonyAuthServiceViewModel
        let bannerMessage: String?

        switch authState {
        case .disconnected:
            service = SymphonyAuthServiceViewModel(
                id: "linear",
                name: "Linear",
                icon: "point.3.filled.connected.trianglepath.dotted",
                description: "Connect your Linear workspace to sync issues.",
                state: .disconnected,
                statusLabel: "Not Connected",
                statusMessage: "No Linear session is connected.",
                actionLabel: "Connect",
                connectedAtLabel: nil,
                expiresAtLabel: nil,
                accountLabel: nil,
                isActionEnabled: true
            )
            bannerMessage = nil

        case .connecting:
            service = SymphonyAuthServiceViewModel(
                id: "linear",
                name: "Linear",
                icon: "point.3.filled.connected.trianglepath.dotted",
                description: "Connect your Linear workspace to sync issues.",
                state: .connecting,
                statusLabel: "Connecting",
                statusMessage: "Waiting for the browser callback to complete.",
                actionLabel: "Connecting",
                connectedAtLabel: nil,
                expiresAtLabel: nil,
                accountLabel: nil,
                isActionEnabled: false
            )
            bannerMessage = nil

        case .connected:
            service = SymphonyAuthServiceViewModel(
                id: "linear",
                name: "Linear",
                icon: "point.3.filled.connected.trianglepath.dotted",
                description: "Connect your Linear workspace to sync issues.",
                state: .connected,
                statusLabel: "Connected",
                statusMessage: "Connected to Linear.",
                actionLabel: "Disconnect",
                connectedAtLabel: "Connected just now",
                expiresAtLabel: "Session expires in 8 hours",
                accountLabel: "preview@linear.app",
                isActionEnabled: true
            )
            bannerMessage = nil

        case .error:
            service = SymphonyAuthServiceViewModel(
                id: "linear",
                name: "Linear",
                icon: "point.3.filled.connected.trianglepath.dotted",
                description: "Connect your Linear workspace to sync issues.",
                state: .staleSession,
                statusLabel: "Needs Attention",
                statusMessage: "The preview session is stale.",
                actionLabel: "Reconnect",
                connectedAtLabel: nil,
                expiresAtLabel: nil,
                accountLabel: nil,
                isActionEnabled: true
            )
            bannerMessage = "Session expired. Reconnect to continue."
        }

        return SymphonyAuthViewModel(
            title: "Integrations",
            subtitle: "Manage your tracker connections.",
            bannerMessage: bannerMessage,
            services: [service]
        )
    }

    public static func makeCodexConnectionViewModel(
        _ codexState: CodexPreviewState
    ) -> SymphonyCodexConnectionViewModel {
        switch codexState {
        case .connected:
            return SymphonyCodexConnectionViewModel(
                isConnected: true,
                title: "Codex Connected",
                message: "Codex is ready for preview interactions."
            )
        case .disconnected:
            return SymphonyCodexConnectionViewModel(
                isConnected: false,
                title: "Codex Login Required",
                message: "Codex verification has not run yet."
            )
        }
    }

    public static func makeIssueCatalogViewModel(
        selectedIssueIdentifier: String? = "NARAIOS-142",
        degraded: Bool = true
    ) -> SymphonyIssueCatalogViewModel {
        let presenter = SymphonyIssueCatalogPresenter()
        return presenter.present(
            makeIssueCollection(degraded: degraded),
            displayMode: .groupedSections,
            selectedIssueIdentifier: selectedIssueIdentifier
        )
    }

    private static func makeIssueCollection(
        degraded: Bool
    ) -> SymphonyIssueCollectionContract {
        let iosBinding = makeActiveBindingContext(
            workspacePath: "/Preview/NaraIOS",
            workflowPath: "/Preview/NaraIOS/WORKFLOW.md",
            scopeIdentifier: "nara-ios",
            scopeName: "Nara IOS"
        )
        let serverBinding = makeActiveBindingContext(
            workspacePath: "/Preview/NaraServer",
            workflowPath: degraded ? nil : "/Preview/NaraServer/WORKFLOW.md",
            scopeIdentifier: "nara-server",
            scopeName: "Nara Server",
            startupFailure: degraded ? SymphonyFailureSummaryContract(
                message: "Workflow configuration missing.",
                details: "The saved workflow path could not be resolved for this workspace."
            ) : nil
        )

        var bindingResults = [
            SymphonyIssueCatalogBindingResultContract(
                bindingContext: iosBinding,
                issues: [
                    makeIssue(
                        id: "nara-ios-142",
                        identifier: "NARAIOS-142",
                        title: "Refactor startup gate for preview-safe composition",
                        priority: 2,
                        state: "In Progress",
                        stateType: "started",
                        labels: ["preview", "startup"]
                    ),
                    makeIssue(
                        id: "nara-ios-177",
                        identifier: "NARAIOS-177",
                        title: "Render grouped issue sections in board previews",
                        priority: 3,
                        state: "Review",
                        stateType: "started",
                        labels: ["preview", "board"]
                    ),
                    makeIssue(
                        id: "nara-ios-181",
                        identifier: "NARAIOS-181",
                        title: "Keep startup loading bounded in production",
                        priority: 2,
                        state: "Blocked",
                        stateType: "started",
                        labels: ["preview", "performance"]
                    )
                ],
                loadState: .loaded
            )
        ]

        if degraded {
            bindingResults.append(
                SymphonyIssueCatalogBindingResultContract(
                    bindingContext: serverBinding,
                    issues: [],
                    loadState: .failed,
                    loadError: SymphonyFailureSummaryContract(
                        message: "Workflow configuration missing.",
                        details: "Open setup to repair the workspace binding."
                    )
                )
            )
        } else {
            bindingResults.append(
                SymphonyIssueCatalogBindingResultContract(
                    bindingContext: serverBinding,
                    issues: [
                        makeIssue(
                            id: "nara-server-101",
                            identifier: "NARASERVER-101",
                            title: "Stabilize Linear webhook fanout for server tasks",
                            priority: 1,
                            state: "Ready",
                            stateType: "backlog",
                            labels: ["server", "linear"]
                        ),
                        makeIssue(
                            id: "nara-server-108",
                            identifier: "NARASERVER-108",
                            title: "Persist workspace binding repairs to disk",
                            priority: 2,
                            state: "Backlog",
                            stateType: "backlog",
                            labels: ["server", "storage"]
                        )
                    ],
                    loadState: .loaded
                )
            )
        }

        return SymphonyIssueCollectionContract(bindingResults: bindingResults)
    }

    private static func makeActiveBindingContext(
        workspacePath: String,
        workflowPath: String?,
        scopeIdentifier: String,
        scopeName: String,
        startupFailure: SymphonyFailureSummaryContract? = nil
    ) -> SymphonyActiveWorkspaceBindingContextContract {
        SymphonyActiveWorkspaceBindingContextContract(
            workspaceBinding: SymphonyWorkspaceTrackerBindingContract(
                workspacePath: workspacePath,
                explicitWorkflowPath: workflowPath,
                trackerKind: "linear",
                scopeKind: "team",
                scopeIdentifier: scopeIdentifier,
                scopeName: scopeName
            ),
            effectiveWorkspaceLocator: SymphonyWorkspaceLocatorContract(
                currentWorkingDirectoryPath: workspacePath,
                explicitWorkflowPath: workflowPath
            ),
            workflowConfiguration: workflowPath.map(makeWorkflowConfiguration),
            trackerAuthStatus: SymphonyTrackerAuthStatusContract(
                trackerKind: "linear",
                state: startupFailure == nil ? .connected : .staleSession,
                statusMessage: startupFailure == nil
                    ? "Connected to Linear."
                    : "Workflow configuration missing."
            ),
            startupFailure: startupFailure
        )
    }

    private static func makeWorkflowConfiguration(
        workflowPath: String
    ) -> SymphonyWorkflowConfigurationResultContract {
        SymphonyWorkflowConfigurationResultContract(
            workflowDefinition: SymphonyWorkflowDefinitionContract(
                resolvedPath: workflowPath,
                config: [:],
                promptTemplate: "Preview prompt template"
            ),
            serviceConfig: SymphonyServiceConfigContract(
                tracker: SymphonyServiceConfigContract.Tracker(
                    kind: "linear",
                    endpoint: "https://api.linear.app/graphql",
                    projectSlug: nil,
                    activeStateTypes: ["started"],
                    terminalStateTypes: ["completed", "canceled"]
                ),
                polling: SymphonyServiceConfigContract.Polling(intervalMs: 5000),
                workspace: SymphonyServiceConfigContract.Workspace(rootPath: workflowPath),
                hooks: SymphonyServiceConfigContract.Hooks(
                    afterCreate: nil,
                    beforeRun: nil,
                    afterRun: nil,
                    beforeRemove: nil,
                    timeoutMs: 30000
                ),
                agent: SymphonyServiceConfigContract.Agent(
                    maxConcurrentAgents: 4,
                    maxTurns: 12,
                    maxRetryBackoffMs: 12000,
                    maxConcurrentAgentsByState: [:]
                ),
                codex: SymphonyServiceConfigContract.Codex(
                    command: "codex",
                    approvalPolicy: nil,
                    threadSandbox: nil,
                    turnSandboxPolicy: nil,
                    turnTimeoutMs: 120000,
                    readTimeoutMs: 20000,
                    stallTimeoutMs: 30000
                )
            )
        )
    }

    private static func makeIssue(
        id: String,
        identifier: String,
        title: String,
        priority: Int,
        state: String,
        stateType: String,
        labels: [String]
    ) -> SymphonyIssue {
        SymphonyIssue(
            id: id,
            identifier: identifier,
            title: title,
            description: nil,
            priority: priority,
            state: state,
            stateType: stateType,
            branchName: nil,
            url: nil,
            labels: labels,
            blockedBy: [],
            createdAt: nil,
            updatedAt: nil
        )
    }
}
