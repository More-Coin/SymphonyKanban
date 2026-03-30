import SwiftUI

// MARK: - SymphonySetupAuthenticationStepView

/// Authentication step that shows connection status and triggers the OAuth
/// flow for the selected tracker integration.
public struct SymphonySetupAuthenticationStepView: View {

    // MARK: - Parameters

    private let trackerKind: String
    @Binding private var isAuthenticated: Bool
    private let authController: SymphonyAuthController
    private let launchTrackerAuthorizationURL: @MainActor (URL) throws -> Void
    private let prepareTrackerAuthorizationCallbackListener: @MainActor () async throws -> Void
    private let awaitTrackerAuthorizationCallback: @MainActor () async throws -> SymphonyTrackerAuthCallbackContract
    private let cancelTrackerAuthorizationCallbackListener: @MainActor () async -> Void
    private let onContinue: () -> Void

    // MARK: - State

    @State private var appeared = false
    @State private var isConnecting = false
    @State private var errorMessage: String?

    // MARK: - Computed

    private var trackerDisplayName: String {
        trackerKind == "linear" ? "Linear" : trackerKind.capitalized
    }

    // MARK: - Initializer

    public init(
        trackerKind: String,
        isAuthenticated: Binding<Bool>,
        authController: SymphonyAuthController,
        launchTrackerAuthorizationURL: @escaping @MainActor (URL) throws -> Void = { _ in },
        prepareTrackerAuthorizationCallbackListener: @escaping @MainActor () async throws -> Void = {},
        awaitTrackerAuthorizationCallback: @escaping @MainActor () async throws -> SymphonyTrackerAuthCallbackContract = {
            throw SymphonyTrackerAuthPresentationError.callbackListenerFailed(
                details: "The callback listener was not configured."
            )
        },
        cancelTrackerAuthorizationCallbackListener: @escaping @MainActor () async -> Void = {},
        onContinue: @escaping () -> Void
    ) {
        self.trackerKind = trackerKind
        self._isAuthenticated = isAuthenticated
        self.authController = authController
        self.launchTrackerAuthorizationURL = launchTrackerAuthorizationURL
        self.prepareTrackerAuthorizationCallbackListener = prepareTrackerAuthorizationCallbackListener
        self.awaitTrackerAuthorizationCallback = awaitTrackerAuthorizationCallback
        self.cancelTrackerAuthorizationCallbackListener = cancelTrackerAuthorizationCallbackListener
        self.onContinue = onContinue
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.xxl) {
            Spacer()

            titleArea
            connectionStatusCard
            if let errorMessage, errorMessage.isEmpty == false {
                errorBanner(errorMessage)
            }
            if isAuthenticated {
                continueButton
            }

            Spacer()
        }
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }

            Task {
                await refreshAuthenticationState()
            }
        }
    }

    // MARK: - Title Area

    private var titleArea: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Text("Authenticate")
                .font(SymphonyDesignStyle.Typography.title)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)

            Text("Connect to \(trackerDisplayName) to access your issues.")
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
        }
        .symphonyStaggerIn(index: 0, isVisible: appeared)
    }

    // MARK: - Connection Status Card

    private var connectionStatusCard: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.md) {
            HStack {
                Circle()
                    .fill(isAuthenticated ? SymphonyDesignStyle.Accent.green : SymphonyDesignStyle.Accent.amber)
                    .frame(width: 10, height: 10)

                Text(isAuthenticated ? "Connected to \(trackerDisplayName)" : "Not connected")
                    .font(SymphonyDesignStyle.Typography.headline)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)

                Spacer()

                if isConnecting {
                    ProgressView()
                        .controlSize(.small)
                } else if isAuthenticated {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(SymphonyDesignStyle.Accent.green)
                }
            }

            if !isAuthenticated {
                connectButton
            }
        }
        .padding(SymphonyDesignStyle.Spacing.md)
        .symphonyCard(selected: isAuthenticated)
        .symphonyStaggerIn(index: 1, isVisible: appeared)
    }

    // MARK: - Connect Button

    private var connectButton: some View {
        Button {
            Task {
                await connect()
            }
        } label: {
            HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                if isConnecting {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Image(systemName: "link")
                }
                Text(isConnecting ? "Connecting..." : "Connect \(trackerDisplayName)")
            }
            .font(SymphonyDesignStyle.Typography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, SymphonyDesignStyle.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                    .fill(SymphonyDesignStyle.Accent.blue)
            )
        }
        .buttonStyle(.plain)
        .disabled(isConnecting)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: onContinue) {
            Text("Continue")
                .font(SymphonyDesignStyle.Typography.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, SymphonyDesignStyle.Spacing.xxl)
                .padding(.vertical, SymphonyDesignStyle.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                        .fill(SymphonyDesignStyle.Accent.blue)
                )
        }
        .buttonStyle(.plain)
        .symphonyStaggerIn(index: 2, isVisible: appeared)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(SymphonyDesignStyle.Accent.coral)
            Text(message)
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
            Spacer()
        }
        .padding(SymphonyDesignStyle.Spacing.md)
        .background(SymphonyDesignStyle.Background.tertiary)
        .clipShape(
            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
        )
        .symphonyStaggerIn(index: 2, isVisible: appeared)
    }

    private func refreshAuthenticationState() async {
        let viewModel = await authController.queryViewModel()
        isAuthenticated = viewModel.linearService?.isConnected == true
        errorMessage = nil
    }

    private func connect() async {
        isConnecting = true
        errorMessage = nil

        let viewModel: SymphonyAuthViewModel
        do {
            try await prepareTrackerAuthorizationCallbackListener()
            let result = try await authController.startAuthorization()
            guard let url = URL(string: result.browserLaunchURL) else {
                await cancelTrackerAuthorizationCallbackListener()
                viewModel = authController.errorViewModel(
                    for: SymphonyTrackerAuthPresentationError.invalidAuthorizationURL
                )
                isAuthenticated = false
                errorMessage = viewModel.bannerMessage ?? viewModel.linearService?.statusMessage
                isConnecting = false
                return
            }

            _ = await authController.viewModelAfterStartingAuthorization()
            try launchTrackerAuthorizationURL(url)
            let callback = try await awaitTrackerAuthorizationCallback()
            viewModel = await authController.completeAuthorizationViewModel(using: callback)
        } catch {
            await cancelTrackerAuthorizationCallbackListener()
            viewModel = authController.errorViewModel(for: error)
        }

        isAuthenticated = viewModel.linearService?.isConnected == true
        if isAuthenticated == false {
            errorMessage = viewModel.bannerMessage ?? viewModel.linearService?.statusMessage
        }
        isConnecting = false
    }
}

// MARK: - Previews

#Preview("Not Connected") {
    SymphonySetupAuthenticationStepView(
        trackerKind: "linear",
        isAuthenticated: .constant(false),
        authController: SymphonyPreviewDI.makeAuthController(state: .disconnected),
        onContinue: {}
    )
    .frame(width: 480, height: 600)
    .background(LinearGradient.symphonyBackground)
}

#Preview("Connecting") {
    SymphonySetupAuthenticationStepView(
        trackerKind: "linear",
        isAuthenticated: .constant(false),
        authController: SymphonyPreviewDI.makeAuthController(state: .connecting),
        onContinue: {}
    )
    .frame(width: 480, height: 600)
    .background(LinearGradient.symphonyBackground)
}

#Preview("Connected") {
    SymphonySetupAuthenticationStepView(
        trackerKind: "linear",
        isAuthenticated: .constant(true),
        authController: SymphonyPreviewDI.makeAuthController(state: .connected),
        onContinue: {}
    )
    .frame(width: 480, height: 600)
    .background(LinearGradient.symphonyBackground)
}

#Preview("Error") {
    SymphonySetupAuthenticationStepView(
        trackerKind: "linear",
        isAuthenticated: .constant(false),
        authController: SymphonyPreviewDI.makeAuthController(state: .error),
        onContinue: {}
    )
    .frame(width: 480, height: 600)
    .background(LinearGradient.symphonyBackground)
}
