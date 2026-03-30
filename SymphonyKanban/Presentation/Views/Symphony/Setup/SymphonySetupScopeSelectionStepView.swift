import SwiftUI

// MARK: - SymphonySetupScopeSelectionStepView

/// Scope selection step allowing the user to choose the single tracker scope
/// (team or project) that should bind to the current workspace.
public struct SymphonySetupScopeSelectionStepView: View {

    // MARK: - Parameters

    private let trackerKind: String
    private let scopeSelectionController: SymphonySetupScopeSelectionController
    @Binding private var selectedScope: SymphonySetupScopeSelectionViewModel.Option?
    private let onContinue: () -> Void

    // MARK: - State

    @State private var appeared = false
    @State private var viewModel: SymphonySetupScopeSelectionViewModel

    // MARK: - Initializer

    public init(
        trackerKind: String,
        scopeSelectionController: SymphonySetupScopeSelectionController,
        selectedScope: Binding<SymphonySetupScopeSelectionViewModel.Option?>,
        onContinue: @escaping () -> Void
    ) {
        self.trackerKind = trackerKind
        self.scopeSelectionController = scopeSelectionController
        self._selectedScope = selectedScope
        self.onContinue = onContinue
        _viewModel = State(
            initialValue: scopeSelectionController.loadingViewModel(trackerKind: trackerKind)
        )
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.xxl) {
            Spacer()

            titleArea
            contentArea
            continueButton

            Spacer()
        }
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
        .task(id: trackerKind) {
            await loadAvailableScopes()
        }
    }

    // MARK: - Title Area

    private var titleArea: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Text(viewModel.title)
                .font(SymphonyDesignStyle.Typography.title)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)

            Text(viewModel.message)
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .symphonyStaggerIn(index: 0, isVisible: appeared)
    }

    // MARK: - Content Area

    private var contentArea: some View {
        Group {
            switch viewModel.state {
            case .loading:
                loadingIndicator
            case .loaded:
                scopeCardList
            case .empty:
                emptyState
            case .failed:
                failedState
            }
        }
    }

    // MARK: - Loading Indicator

    private var loadingIndicator: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            SymphonyPulsingDotView(color: SymphonyDesignStyle.Accent.teal)

            Text(viewModel.message)
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
        }
        .symphonyStaggerIn(index: 1, isVisible: appeared)
    }

    // MARK: - Scope Card List

    private var scopeCardList: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            ForEach(Array(viewModel.options.enumerated()), id: \.element.id) { index, scope in
                scopeCard(for: scope, staggerIndex: index)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.md) {
            Text("No scopes found")
                .font(SymphonyDesignStyle.Typography.headline)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)

            Text(viewModel.message)
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                .multilineTextAlignment(.center)

            retryButton
        }
        .padding(SymphonyDesignStyle.Spacing.lg)
        .symphonyCard()
        .symphonyStaggerIn(index: 1, isVisible: appeared)
    }

    private var failedState: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.md) {
            Text("Could not load scopes")
                .font(SymphonyDesignStyle.Typography.headline)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)

            Text(viewModel.errorMessage ?? viewModel.message)
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                .multilineTextAlignment(.center)

            retryButton
        }
        .padding(SymphonyDesignStyle.Spacing.lg)
        .symphonyCard()
        .symphonyStaggerIn(index: 1, isVisible: appeared)
    }

    private var retryButton: some View {
        Button {
            Task {
                await loadAvailableScopes()
            }
        } label: {
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

    // MARK: - Scope Card

    private func scopeCard(
        for scope: SymphonySetupScopeSelectionViewModel.Option,
        staggerIndex: Int
    ) -> some View {
        let isSelected = selectedScope?.id == scope.id

        return Button {
            toggleSelection(for: scope)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xxs) {
                    Text(scope.scopeName)
                        .font(SymphonyDesignStyle.Typography.headline)
                        .foregroundStyle(SymphonyDesignStyle.Text.primary)

                    Text(scope.scopeKindLabel)
                        .font(SymphonyDesignStyle.Typography.micro)
                        .foregroundStyle(SymphonyDesignStyle.Accent.indigo)

                    if let detailText = scope.detailText, detailText.isEmpty == false {
                        Text(detailText)
                            .font(SymphonyDesignStyle.Typography.caption)
                            .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                    } else {
                        Text(scope.scopeIdentifier)
                            .font(SymphonyDesignStyle.Typography.caption)
                            .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(
                        isSelected
                            ? SymphonyDesignStyle.Accent.blue
                            : SymphonyDesignStyle.Text.tertiary
                    )
            }
            .padding(SymphonyDesignStyle.Spacing.lg)
            .symphonyCard(selected: isSelected)
        }
        .buttonStyle(.plain)
        .symphonyStaggerIn(index: staggerIndex, isVisible: viewModel.state == .loaded)
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
        .disabled(selectedScope == nil || viewModel.state != .loaded)
        .opacity(selectedScope == nil || viewModel.state != .loaded ? 0.5 : 1.0)
        .symphonyStaggerIn(index: viewModel.options.count + 1, isVisible: viewModel.state != .loading)
    }

    // MARK: - Helpers

    private func toggleSelection(for scope: SymphonySetupScopeSelectionViewModel.Option) {
        withAnimation(SymphonyDesignStyle.Motion.snappy) {
            if selectedScope?.id == scope.id {
                selectedScope = nil
            } else {
                selectedScope = scope
            }
        }
    }

    private func loadAvailableScopes() async {
        let loadingViewModel = scopeSelectionController.loadingViewModel(trackerKind: trackerKind)
        withAnimation(SymphonyDesignStyle.Motion.smooth) {
            viewModel = loadingViewModel
        }

        let loadedViewModel = await scopeSelectionController.queryViewModel(trackerKind: trackerKind)

        withAnimation(SymphonyDesignStyle.Motion.smooth) {
            viewModel = loadedViewModel
            if let selectedScope,
               loadedViewModel.options.contains(where: { $0.id == selectedScope.id }) == false {
                self.selectedScope = nil
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SymphonySetupScopeSelectionStepView(
        trackerKind: "linear",
        scopeSelectionController: SymphonyPreviewDI.makeSetupScopeSelectionController(),
        selectedScope: .constant(nil),
        onContinue: {}
    )
    .frame(width: 480, height: 600)
    .background(LinearGradient.symphonyBackground)
}
