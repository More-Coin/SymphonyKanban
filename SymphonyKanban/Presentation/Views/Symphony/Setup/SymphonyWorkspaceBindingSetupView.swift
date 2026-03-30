import SwiftUI

// MARK: - SymphonyWorkspaceBindingSetupView

/// Multi-step wizard container for creating workspace-to-tracker bindings.
///
/// Guides the user through tracker selection, authentication, scope selection,
/// and confirmation. Supports both first-run onboarding and repair flows.
public struct SymphonyWorkspaceBindingSetupView: View {

    // MARK: - Public Types

    public enum Mode {
        case firstRun
        case repair
    }

    private enum SetupStep: Int, CaseIterable {
        case welcome = 0
        case trackerSelection = 1
        case authentication = 2
        case scopeSelection = 3
        case confirmation = 4
    }

    // MARK: - Parameters

    private let mode: Mode
    private let currentWorkingDirectoryPath: String
    private let explicitWorkflowPath: String?
    private let authController: SymphonyAuthController
    private let scopeSelectionController: SymphonySetupScopeSelectionController
    private let workspaceBindingSetupController: SymphonyWorkspaceBindingSetupController
    private let launchTrackerAuthorizationURL: @MainActor (URL) throws -> Void
    private let prepareTrackerAuthorizationCallbackListener: @MainActor () async throws -> Void
    private let awaitTrackerAuthorizationCallback: @MainActor () async throws -> SymphonyTrackerAuthCallbackContract
    private let cancelTrackerAuthorizationCallbackListener: @MainActor () async -> Void
    private let onComplete: () -> Void

    // MARK: - State

    @State private var currentStep: SetupStep
    @State private var appeared = false
    @State private var selectedTrackerKind: String?
    @State private var isAuthenticated = false
    @State private var selectedScope: SymphonySetupScopeSelectionViewModel.Option?
    @State private var isCompleting = false
    @State private var completionErrorMessage: String?

    // MARK: - Initializer

    public init(
        mode: Mode = .firstRun,
        currentWorkingDirectoryPath: String = FileManager.default.currentDirectoryPath,
        explicitWorkflowPath: String? = nil,
        authController: SymphonyAuthController,
        scopeSelectionController: SymphonySetupScopeSelectionController,
        workspaceBindingSetupController: SymphonyWorkspaceBindingSetupController,
        launchTrackerAuthorizationURL: @escaping @MainActor (URL) throws -> Void = { _ in },
        prepareTrackerAuthorizationCallbackListener: @escaping @MainActor () async throws -> Void = {},
        awaitTrackerAuthorizationCallback: @escaping @MainActor () async throws -> SymphonyTrackerAuthCallbackContract = {
            throw SymphonyTrackerAuthPresentationError.callbackListenerFailed(
                details: "The callback listener was not configured."
            )
        },
        cancelTrackerAuthorizationCallbackListener: @escaping @MainActor () async -> Void = {},
        onComplete: @escaping () -> Void
    ) {
        self.mode = mode
        self.currentWorkingDirectoryPath = currentWorkingDirectoryPath
        self.explicitWorkflowPath = explicitWorkflowPath
        self.authController = authController
        self.scopeSelectionController = scopeSelectionController
        self.workspaceBindingSetupController = workspaceBindingSetupController
        self.launchTrackerAuthorizationURL = launchTrackerAuthorizationURL
        self.prepareTrackerAuthorizationCallbackListener = prepareTrackerAuthorizationCallbackListener
        self.awaitTrackerAuthorizationCallback = awaitTrackerAuthorizationCallback
        self.cancelTrackerAuthorizationCallbackListener = cancelTrackerAuthorizationCallbackListener
        self.onComplete = onComplete
        _currentStep = State(initialValue: mode == .firstRun ? .welcome : .trackerSelection)
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            LinearGradient.symphonyBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                stepContent
                stepDots
            }
        }
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            if showsBackButton {
                Button(action: goBack) {
                    HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .frame(height: 48)
        .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)
    }

    // MARK: - Step Content

    private var stepContent: some View {
        Group {
            switch currentStep {
            case .welcome:
                SymphonySetupWelcomeStepView(
                    onGetStarted: { advanceTo(.trackerSelection) }
                )

            case .trackerSelection:
                SymphonySetupTrackerSelectionStepView(
                    selectedTrackerKind: $selectedTrackerKind,
                    onContinue: { advanceTo(.authentication) }
                )

            case .authentication:
                SymphonySetupAuthenticationStepView(
                    trackerKind: selectedTrackerKind ?? "",
                    isAuthenticated: $isAuthenticated,
                    authController: authController,
                    launchTrackerAuthorizationURL: launchTrackerAuthorizationURL,
                    prepareTrackerAuthorizationCallbackListener: prepareTrackerAuthorizationCallbackListener,
                    awaitTrackerAuthorizationCallback: awaitTrackerAuthorizationCallback,
                    cancelTrackerAuthorizationCallbackListener: cancelTrackerAuthorizationCallbackListener,
                    onContinue: { advanceTo(.scopeSelection) }
                )

            case .scopeSelection:
                SymphonySetupScopeSelectionStepView(
                    trackerKind: selectedTrackerKind ?? "",
                    scopeSelectionController: scopeSelectionController,
                    selectedScope: $selectedScope,
                    onContinue: { advanceTo(.confirmation) }
                )

            case .confirmation:
                SymphonySetupConfirmationStepView(
                    trackerKind: selectedTrackerKind ?? "",
                    selectedScope: selectedScope,
                    isSaving: isCompleting,
                    errorMessage: completionErrorMessage,
                    onComplete: {
                        Task {
                            await completeSetup()
                        }
                    }
                )
            }
        }
        .frame(maxWidth: 480, maxHeight: .infinity)
        .frame(maxWidth: .infinity)
        .transition(
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        )
    }

    // MARK: - Step Dots

    private var stepDots: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            ForEach(SetupStep.allCases, id: \.rawValue) { step in
                Circle()
                    .fill(
                        step == currentStep
                            ? SymphonyDesignStyle.Accent.blue
                            : SymphonyDesignStyle.Text.tertiary.opacity(0.4)
                    )
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.bottom, SymphonyDesignStyle.Spacing.xl)
    }

    // MARK: - Navigation Helpers

    private var initialStep: SetupStep {
        mode == .firstRun ? .welcome : .trackerSelection
    }

    private var showsBackButton: Bool {
        currentStep.rawValue > initialStep.rawValue
    }

    private func goBack() {
        let minimumRawValue = initialStep.rawValue
        let targetRawValue = currentStep.rawValue - 1
        guard targetRawValue >= minimumRawValue,
              let previousStep = SetupStep(rawValue: targetRawValue) else {
            return
        }
        withAnimation(SymphonyDesignStyle.Motion.smooth) {
            currentStep = previousStep
        }
    }

    private func advanceTo(_ step: SetupStep) {
        if step == .scopeSelection {
            selectedScope = nil
        }

        if step == .confirmation {
            completionErrorMessage = nil
        }

        withAnimation(SymphonyDesignStyle.Motion.smooth) {
            currentStep = step
        }
    }

    @MainActor
    private func completeSetup() async {
        guard let trackerKind = selectedTrackerKind,
              let selectedScope else {
            return
        }

        isCompleting = true
        completionErrorMessage = nil

        do {
            _ = try workspaceBindingSetupController.saveBinding(
                workspacePath: currentWorkingDirectoryPath,
                explicitWorkflowPath: explicitWorkflowPath,
                trackerKind: trackerKind,
                selectedScope: selectedScope
            )
            isCompleting = false
            onComplete()
        } catch {
            completionErrorMessage = workspaceBindingSetupController.errorMessage(for: error)
            isCompleting = false
        }
    }
}

// MARK: - Preview

#Preview("Setup - First Run") {
    SymphonyPreviewDI.makeWorkspaceBindingSetupView(
        mode: .firstRun,
        authState: .disconnected
    )
    .frame(width: 800, height: 600)
}

#Preview("Setup - Repair") {
    SymphonyPreviewDI.makeWorkspaceBindingSetupView(
        mode: .repair,
        authState: .connected
    )
    .frame(width: 800, height: 600)
}
