import SwiftUI

// MARK: - SymphonyWorkspaceBindingManagementView

/// Sheet view for managing saved workspace-to-tracker bindings.
/// Shows one card per binding with folder-change and remove actions.
public struct SymphonyWorkspaceBindingManagementView: View {

    // MARK: - Parameters

    private let viewModel: SymphonyWorkspaceBindingManagementViewModel
    private let onChooseFolder: (SymphonyWorkspaceBindingManagementViewModel.Card) -> Void
    private let onRemoveBinding: (SymphonyWorkspaceBindingManagementViewModel.Card) -> Void
    private let onDismiss: (() -> Void)?

    // MARK: - State

    @State private var appeared = false

    // MARK: - Initializer

    public init(
        viewModel: SymphonyWorkspaceBindingManagementViewModel,
        onChooseFolder: @escaping (SymphonyWorkspaceBindingManagementViewModel.Card) -> Void,
        onRemoveBinding: @escaping (SymphonyWorkspaceBindingManagementViewModel.Card) -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onChooseFolder = onChooseFolder
        self.onRemoveBinding = onRemoveBinding
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            SymphonyDesignStyle.Background.primary.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, SymphonyDesignStyle.Spacing.lg)

                if let bannerMessage = viewModel.bannerMessage,
                   bannerMessage.isEmpty == false {
                    errorBanner(bannerMessage)
                        .padding(.horizontal, SymphonyDesignStyle.Spacing.xl)
                        .padding(.top, SymphonyDesignStyle.Spacing.md)
                }

                ScrollView {
                    VStack(spacing: SymphonyDesignStyle.Spacing.md) {
                        if viewModel.cards.isEmpty {
                            emptyState
                        } else {
                            ForEach(Array(viewModel.cards.enumerated()), id: \.element.id) { index, card in
                                bindingCard(for: card, staggerIndex: index)
                            }
                        }
                    }
                    .padding(.horizontal, SymphonyDesignStyle.Spacing.xl)
                    .padding(.vertical, SymphonyDesignStyle.Spacing.lg)
                }
            }
        }
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xs) {
                Text(viewModel.title)
                    .font(SymphonyDesignStyle.Typography.title)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)

                Text(viewModel.subtitle)
                    .font(SymphonyDesignStyle.Typography.body)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
            }

            Spacer()

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, SymphonyDesignStyle.Spacing.xl)
        .symphonyStaggerIn(index: 0, isVisible: appeared)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)

            Text("No Bindings")
                .font(SymphonyDesignStyle.Typography.headline)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)

            Text("Run the setup wizard to create a workspace binding.")
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(SymphonyDesignStyle.Spacing.xxl)
        .symphonyStaggerIn(index: 1, isVisible: appeared)
    }

    // MARK: - Binding Card

    private func bindingCard(
        for card: SymphonyWorkspaceBindingManagementViewModel.Card,
        staggerIndex: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.md) {
            cardHeader(for: card)
            cardDetails(for: card)

            SymphonyDividerView()

            cardActions(for: card)
        }
        .padding(SymphonyDesignStyle.Spacing.lg)
        .symphonyCard()
        .symphonyStaggerIn(index: staggerIndex + 1, isVisible: appeared)
    }

    private func cardHeader(
        for card: SymphonyWorkspaceBindingManagementViewModel.Card
    ) -> some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.sm) {
            HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                SymphonyLabelChipView(
                    card.scopeKindLabel,
                    color: SymphonyDesignStyle.Accent.indigo
                )

                SymphonyLabelChipView(
                    card.trackerKindLabel,
                    color: SymphonyDesignStyle.Accent.teal
                )

                Spacer()

                HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                    Circle()
                        .fill(
                            card.workflowStatusIsHealthy
                                ? SymphonyDesignStyle.Accent.green
                                : SymphonyDesignStyle.Accent.amber
                        )
                        .frame(width: 6, height: 6)

                    Text(card.workflowStatusLabel)
                        .font(SymphonyDesignStyle.Typography.micro)
                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                }
            }

            Text(card.scopeName)
                .font(SymphonyDesignStyle.Typography.headline)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)
        }
    }

    private func cardDetails(
        for card: SymphonyWorkspaceBindingManagementViewModel.Card
    ) -> some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xs) {
            HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                Image(systemName: "folder.fill")
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)

                Text(card.workspacePath)
                    .font(SymphonyDesignStyle.Typography.caption)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                    .lineLimit(1)
            }

            if let failureMessage = card.failureMessage, failureMessage.isEmpty == false {
                HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(SymphonyDesignStyle.Typography.micro)
                        .foregroundStyle(SymphonyDesignStyle.Accent.amber)

                    Text(failureMessage)
                        .font(SymphonyDesignStyle.Typography.caption)
                        .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private func cardActions(
        for card: SymphonyWorkspaceBindingManagementViewModel.Card
    ) -> some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.md) {
            Button {
                onChooseFolder(card)
            } label: {
                HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                    Image(systemName: "folder")
                    Text(card.folderActionLabel)
                }
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(SymphonyDesignStyle.Accent.blue)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                onRemoveBinding(card)
            } label: {
                HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                    Image(systemName: "trash")
                    Text("Remove")
                }
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(SymphonyDesignStyle.Accent.coral)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Error Banner

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
    }
}

// MARK: - Preview

#Preview("With Bindings") {
    SymphonyWorkspaceBindingManagementView(
        viewModel: SymphonyWorkspaceBindingManagementViewModel(
            title: "Workspace Bindings",
            subtitle: "Manage your saved workspace-to-tracker bindings.",
            cards: [
                .init(
                    id: "/Users/dev/NaraIOS",
                    scopeName: "Nara IOS",
                    scopeKind: "team",
                    scopeKindLabel: "Team",
                    scopeIdentifier: "nara-ios",
                    trackerKind: "linear",
                    trackerKindLabel: "Linear",
                    workspacePath: "/Users/dev/NaraIOS",
                    workflowStatusLabel: "Valid",
                    workflowStatusIsHealthy: true,
                    failureMessage: nil,
                    folderActionLabel: "Change Folder",
                    isHealthy: true
                ),
                .init(
                    id: "/Users/dev/NaraServer",
                    scopeName: "Nara Server",
                    scopeKind: "project",
                    scopeKindLabel: "Project",
                    scopeIdentifier: "nara-server",
                    trackerKind: "linear",
                    trackerKindLabel: "Linear",
                    workspacePath: "/Users/dev/NaraServer",
                    workflowStatusLabel: "Missing",
                    workflowStatusIsHealthy: false,
                    failureMessage: "Workflow configuration missing.",
                    folderActionLabel: "Change Folder",
                    isHealthy: false
                )
            ]
        ),
        onChooseFolder: { _ in },
        onRemoveBinding: { _ in },
        onDismiss: {}
    )
    .frame(width: 560, height: 520)
}

#Preview("Empty") {
    SymphonyWorkspaceBindingManagementView(
        viewModel: SymphonyWorkspaceBindingManagementViewModel(
            title: "Workspace Bindings",
            subtitle: "No saved workspace bindings. Run setup to create one."
        ),
        onChooseFolder: { _ in },
        onRemoveBinding: { _ in },
        onDismiss: {}
    )
    .frame(width: 560, height: 520)
}

#Preview("Error") {
    SymphonyWorkspaceBindingManagementView(
        viewModel: SymphonyWorkspaceBindingManagementViewModel(
            title: "Workspace Bindings",
            subtitle: "Could not load workspace bindings.",
            bannerMessage: "Failed to read binding storage file."
        ),
        onChooseFolder: { _ in },
        onRemoveBinding: { _ in },
        onDismiss: {}
    )
    .frame(width: 560, height: 520)
}
