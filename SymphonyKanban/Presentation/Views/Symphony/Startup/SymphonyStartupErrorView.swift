import SwiftUI

/// Full-screen error surface for startup failures with retry and setup actions.
public struct SymphonyStartupErrorView: View {
    private let viewModel: SymphonyStartupStatusViewModel
    private let onRetry: () -> Void
    private let onSetup: () -> Void

    @State private var appeared = false

    public init(
        viewModel: SymphonyStartupStatusViewModel,
        onRetry: @escaping () -> Void,
        onSetup: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onRetry = onRetry
        self.onSetup = onSetup
    }

    public var body: some View {
        ZStack {
            LinearGradient.symphonyBackground
                .ignoresSafeArea()

            VStack(spacing: SymphonyDesignStyle.Spacing.xl) {
                errorIcon
                titleAndMessage
                actionButtons
            }
        }
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }

    // MARK: - Error Icon

    private var errorIcon: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 40, weight: .light))
            .foregroundStyle(SymphonyDesignStyle.Accent.coral)
            .symphonyStaggerIn(index: 0, isVisible: appeared)
    }

    // MARK: - Title + Message

    private var titleAndMessage: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Text(viewModel.title)
                .font(SymphonyDesignStyle.Typography.title)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)

            Text(viewModel.message)
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .symphonyStaggerIn(index: 1, isVisible: appeared)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.md) {
            retryButton
            setupButton
        }
        .symphonyStaggerIn(index: 2, isVisible: appeared)
    }

    private var retryButton: some View {
        Button(action: onRetry) {
            Text("Retry")
                .font(SymphonyDesignStyle.Typography.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, SymphonyDesignStyle.Spacing.xl)
                .padding(.vertical, SymphonyDesignStyle.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                        .fill(SymphonyDesignStyle.Accent.blue)
                )
        }
        .buttonStyle(.plain)
    }

    private var setupButton: some View {
        Button(action: onSetup) {
            Text("Setup Workspace")
                .font(SymphonyDesignStyle.Typography.headline)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                .padding(.horizontal, SymphonyDesignStyle.Spacing.xl)
                .padding(.vertical, SymphonyDesignStyle.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                        .fill(SymphonyDesignStyle.Background.tertiary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                        .strokeBorder(SymphonyDesignStyle.Border.default, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SymphonyStartupErrorView(
        viewModel: SymphonyStartupStatusViewModel(
            state: .failed,
            title: "Startup Failed",
            message: "Could not connect to tracker. Check your network and workspace configuration, then try again.",
            currentWorkingDirectoryPath: "/demo",
            explicitWorkflowPath: nil,
            activeBindingCount: 0,
            readyBindingCount: 0,
            failedBindingCount: 0,
            boundScopeNames: [],
            resolvedWorkflowPaths: [],
            trackerStatusLabels: []
        ),
        onRetry: {},
        onSetup: {}
    )
    .frame(width: 800, height: 600)
}
