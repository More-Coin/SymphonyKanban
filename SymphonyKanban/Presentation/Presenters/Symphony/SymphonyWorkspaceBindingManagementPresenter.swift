import Foundation

public struct SymphonyWorkspaceBindingManagementPresenter {
    public init() {}

    public func present(
        _ activeBindings: [SymphonyActiveWorkspaceBindingContextContract],
        bannerMessage: String? = nil
    ) -> SymphonyWorkspaceBindingManagementViewModel {
        let cards = activeBindings.map(makeCard(from:))

        return SymphonyWorkspaceBindingManagementViewModel(
            title: "Workspace Bindings",
            subtitle: cards.isEmpty
                ? "No saved workspace bindings. Run setup to create one."
                : "Manage your saved workspace-to-tracker bindings.",
            bannerMessage: bannerMessage,
            cards: cards
        )
    }

    public func presentError(
        _ error: any Error
    ) -> SymphonyWorkspaceBindingManagementViewModel {
        SymphonyWorkspaceBindingManagementViewModel(
            title: "Workspace Bindings",
            subtitle: "Could not load workspace bindings.",
            bannerMessage: structuredMessage(for: error)
        )
    }

    private func makeCard(
        from context: SymphonyActiveWorkspaceBindingContextContract
    ) -> SymphonyWorkspaceBindingManagementViewModel.Card {
        let binding = context.workspaceBinding
        let hasWorkflow = context.workflowConfiguration != nil
        let hasFailure = context.startupFailure != nil

        return SymphonyWorkspaceBindingManagementViewModel.Card(
            id: binding.workspacePath,
            scopeName: binding.scopeName,
            scopeKind: binding.scopeKind,
            scopeKindLabel: scopeKindDisplayLabel(binding.scopeKind),
            scopeIdentifier: binding.scopeIdentifier,
            trackerKind: binding.trackerKind,
            trackerKindLabel: trackerKindDisplayLabel(binding.trackerKind),
            workspacePath: binding.workspacePath,
            workflowStatusLabel: hasWorkflow ? "Valid" : "Missing",
            workflowStatusIsHealthy: hasWorkflow,
            failureMessage: context.startupFailure?.message,
            folderActionLabel: "Change Folder",
            isHealthy: !hasFailure
        )
    }

    private func trackerKindDisplayLabel(_ trackerKind: String) -> String {
        trackerKind.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "linear"
            ? "Linear"
            : trackerKind.capitalized
    }

    private func scopeKindDisplayLabel(_ scopeKind: String) -> String {
        let normalized = scopeKind.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized == "project" ? "Project" : "Team"
    }

    private func structuredMessage(for error: any Error) -> String {
        if let structuredError = error as? any StructuredErrorProtocol {
            guard let details = structuredError.details,
                  details.isEmpty == false else {
                return structuredError.message
            }
            return "\(structuredError.message) \(details)"
        }
        return error.localizedDescription
    }
}
