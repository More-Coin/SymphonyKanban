import Foundation

public struct SymphonySetupScopeSelectionPresenter {
    public init() {}

    public func presentLoading(
        trackerKind: String
    ) -> SymphonySetupScopeSelectionViewModel {
        SymphonySetupScopeSelectionViewModel(
            state: .loading,
            title: "Select Scope",
            message: "Loading live \(trackerDisplayName(for: trackerKind)) teams and projects."
        )
    }

    public func present(
        _ result: SymphonyTrackerScopeDiscoveryResultContract,
        trackerKind: String
    ) -> SymphonySetupScopeSelectionViewModel {
        let options = result.options.map(makeOption(from:))

        return SymphonySetupScopeSelectionViewModel(
            state: options.isEmpty ? .empty : .loaded,
            title: "Select Scope",
            message: options.isEmpty
                ? "No teams or projects are available for this \(trackerDisplayName(for: trackerKind)) account."
                : "Choose the single team or project this workspace should track.",
            options: options
        )
    }

    public func presentError(
        _ error: any Error,
        trackerKind: String
    ) -> SymphonySetupScopeSelectionViewModel {
        SymphonySetupScopeSelectionViewModel(
            state: .failed,
            title: "Select Scope",
            message: "Live scope discovery could not be completed for \(trackerDisplayName(for: trackerKind)).",
            errorMessage: structuredMessage(for: error)
        )
    }

    private func makeOption(
        from option: SymphonyTrackerScopeOptionContract
    ) -> SymphonySetupScopeSelectionViewModel.Option {
        let normalizedKind = option.scopeKind
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return SymphonySetupScopeSelectionViewModel.Option(
            id: option.id,
            scopeKind: normalizedKind,
            scopeKindLabel: normalizedKind == "project" ? "Project" : "Team",
            scopeIdentifier: option.scopeIdentifier,
            scopeName: option.scopeName,
            detailText: option.detailText
        )
    }

    private func trackerDisplayName(
        for trackerKind: String
    ) -> String {
        trackerKind.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "linear"
            ? "Linear"
            : trackerKind.capitalized
    }

    private func structuredMessage(
        for error: any Error
    ) -> String {
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
