import SwiftUI

// MARK: - SymphonyStartupGatePhaseView

/// Internal state machine for the startup gate's resolution lifecycle.
private enum SymphonyStartupGatePhaseView: Equatable {
    case loading
    case ready(SymphonyStartupStatusViewModel)
    case setupRequired(SymphonyStartupStatusViewModel)
    case failed(SymphonyStartupStatusViewModel)
}

// MARK: - SymphonyStartupGateView

/// Root application gate that branches on startup state.
///
/// Sits between the app entry point and the main navigation routes.
/// Resolves workspace bindings on appear and transitions to the appropriate
/// phase once the startup status controller returns a result.
public struct SymphonyStartupGateView: View {
    private let startupStatusController: SymphonyStartupStatusController?
    private let navigationRoutesBuilder: (SymphonyStartupStatusViewModel) -> AnyView
    private let setupViewBuilder: (SymphonyStartupStatusViewModel, @escaping () -> Void) -> AnyView
    private let resolvesStartupOnAppear: Bool

    @State private var phase: SymphonyStartupGatePhaseView

    public init(
        startupStatusController: SymphonyStartupStatusController,
        navigationRoutesBuilder: @escaping (SymphonyStartupStatusViewModel) -> AnyView,
        setupViewBuilder: @escaping (SymphonyStartupStatusViewModel, @escaping () -> Void) -> AnyView
    ) {
        self.startupStatusController = startupStatusController
        self.navigationRoutesBuilder = navigationRoutesBuilder
        self.setupViewBuilder = setupViewBuilder
        resolvesStartupOnAppear = true
        _phase = State(initialValue: .loading)
    }

    public init(
        previewViewModel: SymphonyStartupStatusViewModel?,
        navigationRoutesBuilder: @escaping (SymphonyStartupStatusViewModel) -> AnyView,
        setupViewBuilder: @escaping (SymphonyStartupStatusViewModel, @escaping () -> Void) -> AnyView
    ) {
        startupStatusController = nil
        self.navigationRoutesBuilder = navigationRoutesBuilder
        self.setupViewBuilder = setupViewBuilder
        resolvesStartupOnAppear = false
        _phase = State(initialValue: Self.makePhase(for: previewViewModel))
    }

    // MARK: - Body

    public var body: some View {
        Group {
            switch phase {
            case .loading:
                SymphonyStartupLoadingView()

            case .ready(let viewModel):
                navigationRoutesBuilder(viewModel)

            case .setupRequired(let viewModel):
                setupViewBuilder(viewModel, resolveStartupState)

            case .failed(let viewModel):
                SymphonyStartupErrorView(
                    viewModel: viewModel,
                    onRetry: {
                        resolveStartupState()
                    },
                    onSetup: {
                        withAnimation(SymphonyDesignStyle.Motion.smooth) {
                            phase = .setupRequired(viewModel)
                        }
                    }
                )
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
        .animation(SymphonyDesignStyle.Motion.smooth, value: phaseKey)
        .task {
            guard resolvesStartupOnAppear else { return }
            try? await Task.sleep(nanoseconds: 100_000_000)
            resolveStartupState()
        }
    }

    // MARK: - Phase Key

    /// Stable string key derived from the current phase for animation tracking.
    private var phaseKey: String {
        switch phase {
        case .loading:
            return "loading"
        case .ready:
            return "ready"
        case .setupRequired:
            return "setupRequired"
        case .failed:
            return "failed"
        }
    }

    // MARK: - State Resolution

    /// Resolves the startup state after the gate has already rendered its
    /// loading frame, then maps the result to the appropriate phase.
    private func resolveStartupState() {
        guard let startupStatusController else { return }

        withAnimation(SymphonyDesignStyle.Motion.smooth) {
            phase = .loading
        }

        let viewModel = startupStatusController.queryViewModel()

        withAnimation(SymphonyDesignStyle.Motion.smooth) {
            phase = Self.makePhase(for: viewModel)
        }
    }

    private static func makePhase(
        for viewModel: SymphonyStartupStatusViewModel?
    ) -> SymphonyStartupGatePhaseView {
        guard let viewModel else {
            return .loading
        }

        switch viewModel.state {
        case .ready:
            return .ready(viewModel)
        case .setupRequired:
            return .setupRequired(viewModel)
        case .failed:
            return .failed(viewModel)
        }
    }
}

// MARK: - Preview

#Preview("Startup Gate - Loading State") {
    SymphonyPreviewDI.makeStartupGate(startupState: .loading)
        .frame(width: 800, height: 600)
}

#Preview("Startup Gate - Setup Required") {
    SymphonyPreviewDI.makeStartupGate(startupState: .setupRequired)
        .frame(width: 800, height: 600)
}

#Preview("Startup Gate - Failed") {
    SymphonyPreviewDI.makeStartupGate(startupState: .failed)
        .frame(width: 800, height: 600)
}

#Preview("Startup Gate - Ready Degraded") {
    SymphonyPreviewDI.makeStartupGate(startupState: .readyDegraded)
        .frame(width: 800, height: 600)
}
