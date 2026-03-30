import Foundation

public struct SymphonyTrackerScopeService: Sendable {
    private let fetchTeamsUseCase: FetchSymphonyTrackerTeamsUseCase
    private let fetchProjectsUseCase: FetchSymphonyTrackerProjectsUseCase

    public init(
        fetchTeamsUseCase: FetchSymphonyTrackerTeamsUseCase,
        fetchProjectsUseCase: FetchSymphonyTrackerProjectsUseCase
    ) {
        self.fetchTeamsUseCase = fetchTeamsUseCase
        self.fetchProjectsUseCase = fetchProjectsUseCase
    }

    public func queryAvailableScopes(
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> SymphonyTrackerScopeDiscoveryResultContract {
        async let teams = fetchTeamsUseCase.fetch(using: trackerConfiguration)
        async let projects = fetchProjectsUseCase.fetch(using: trackerConfiguration)

        let combinedOptions = try await (teams + projects)
            .sorted(by: optionOrdering)

        return SymphonyTrackerScopeDiscoveryResultContract(
            options: combinedOptions
        )
    }

    private func optionOrdering(
        _ lhs: SymphonyTrackerScopeOptionContract,
        _ rhs: SymphonyTrackerScopeOptionContract
    ) -> Bool {
        let kindOrder = kindRank(for: lhs.scopeKind) - kindRank(for: rhs.scopeKind)
        if kindOrder != 0 {
            return kindOrder < 0
        }

        let nameComparison = lhs.scopeName.localizedCaseInsensitiveCompare(rhs.scopeName)
        if nameComparison != .orderedSame {
            return nameComparison == .orderedAscending
        }

        return lhs.scopeIdentifier.localizedCaseInsensitiveCompare(rhs.scopeIdentifier) == .orderedAscending
    }

    private func kindRank(
        for scopeKind: String
    ) -> Int {
        switch scopeKind.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "team":
            return 0
        case "project":
            return 1
        default:
            return 2
        }
    }
}
