import SwiftUI

// MARK: - SymphonySetupConfirmationStepView

/// Confirmation step showing the single workspace binding that will be saved
/// before the setup flow completes.
public struct SymphonySetupConfirmationStepView: View {

    // MARK: - Parameters

    private let trackerKind: String
    private let selectedScope: SymphonySetupScopeSelectionViewModel.Option?
    private let isSaving: Bool
    private let errorMessage: String?
    private let onComplete: () -> Void

    // MARK: - State

    @State private var appeared = false

    // MARK: - Computed

    private var trackerDisplayName: String {
        trackerKind == "linear" ? "Linear" : trackerKind.capitalized
    }

    // MARK: - Initializer

    public init(
        trackerKind: String,
        selectedScope: SymphonySetupScopeSelectionViewModel.Option?,
        isSaving: Bool = false,
        errorMessage: String? = nil,
        onComplete: @escaping () -> Void
    ) {
        self.trackerKind = trackerKind
        self.selectedScope = selectedScope
        self.isSaving = isSaving
        self.errorMessage = errorMessage
        self.onComplete = onComplete
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.xxl) {
            Spacer()

            header
            bindingCards
            if let errorMessage, errorMessage.isEmpty == false {
                errorBanner(errorMessage)
            }
            actions

            Spacer()
        }
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(SymphonyDesignStyle.Accent.green)

            Text("Ready to Connect")
                .font(SymphonyDesignStyle.Typography.title)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)

            Text("Review the single workspace binding that will be saved before setup finishes.")
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .symphonyStaggerIn(index: 0, isVisible: appeared)
    }

    // MARK: - Binding Cards

    private var bindingCards: some View {
        Group {
            if let selectedScope {
                bindingCard(for: selectedScope)
            } else {
                Text("Choose a scope before saving this workspace binding.")
                    .font(SymphonyDesignStyle.Typography.body)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                    .padding(SymphonyDesignStyle.Spacing.lg)
                    .symphonyCard()
            }
        }
    }

    private func bindingCard(
        for scope: SymphonySetupScopeSelectionViewModel.Option
    ) -> some View {
        HStack {
            SymphonyLabelChipView(
                scope.scopeKindLabel,
                color: SymphonyDesignStyle.Accent.indigo
            )

            VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xxs) {
                Text(scope.scopeName)
                    .font(SymphonyDesignStyle.Typography.headline)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)

                Text("\(trackerDisplayName) • \(scope.scopeIdentifier)")
                    .font(SymphonyDesignStyle.Typography.caption)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
            }

            Spacer()
        }
        .padding(SymphonyDesignStyle.Spacing.md)
        .symphonyCard()
        .symphonyStaggerIn(index: 1, isVisible: appeared)
    }

    // MARK: - Actions

    private var actions: some View {
        connectButton
            .symphonyStaggerIn(index: 2, isVisible: appeared)
    }

    private var connectButton: some View {
        Button(action: onComplete) {
            HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                }

                Text(isSaving ? "Saving Binding..." : "Connect Workspace")
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
        .disabled(selectedScope == nil || isSaving)
        .opacity(selectedScope == nil || isSaving ? 0.5 : 1.0)
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
        .symphonyStaggerIn(index: 3, isVisible: appeared)
    }
}

// MARK: - Preview

#Preview("Single") {
    SymphonySetupConfirmationStepView(
        trackerKind: "linear",
        selectedScope: .init(
            id: "team-eng",
            scopeKind: "team",
            scopeKindLabel: "Team",
            scopeIdentifier: "team-eng",
            scopeName: "Engineering",
            detailText: "Team key ENG"
        ),
        onComplete: {}
    )
    .frame(width: 480, height: 600)
    .background(LinearGradient.symphonyBackground)
}

#Preview("Saving") {
    SymphonySetupConfirmationStepView(
        trackerKind: "linear",
        selectedScope: .init(
            id: "project-platform",
            scopeKind: "project",
            scopeKindLabel: "Project",
            scopeIdentifier: "platform",
            scopeName: "Platform Rewrite",
            detailText: "planned • Engineering"
        ),
        isSaving: true,
        onComplete: {}
    )
    .frame(width: 480, height: 600)
    .background(LinearGradient.symphonyBackground)
}
