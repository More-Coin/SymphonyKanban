import SwiftUI

// MARK: - SymphonySetupWelcomeStepView

/// Welcome step explaining what Symphony does and prompting the user
/// to connect their first workspace.
public struct SymphonySetupWelcomeStepView: View {

    // MARK: - Parameters

    private let onGetStarted: () -> Void

    // MARK: - State

    @State private var appeared = false

    // MARK: - Initializer

    public init(onGetStarted: @escaping () -> Void) {
        self.onGetStarted = onGetStarted
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.xxl) {
            Spacer()

            heroIcon
            titleAndDescription
            getStartedButton

            Spacer()
        }
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }

    // MARK: - Hero Icon

    private var heroIcon: some View {
        Image(systemName: "square.grid.3x3.topleft.filled")
            .font(.system(size: 48, weight: .light))
            .foregroundStyle(SymphonyDesignStyle.Accent.teal)
            .symphonyStaggerIn(index: 0, isVisible: appeared)
    }

    // MARK: - Title + Description

    private var titleAndDescription: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.md) {
            Text("Welcome to Symphony")
                .font(SymphonyDesignStyle.Typography.largeTitle)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)

            Text("Connect your workspace to a project tracker to see your issues on a live Kanban board.")
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .symphonyStaggerIn(index: 1, isVisible: appeared)
    }

    // MARK: - Get Started Button

    private var getStartedButton: some View {
        Button(action: onGetStarted) {
            Text("Get Started")
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
}

// MARK: - Preview

#Preview {
    SymphonySetupWelcomeStepView(onGetStarted: {})
        .frame(width: 480, height: 600)
        .background(LinearGradient.symphonyBackground)
}
