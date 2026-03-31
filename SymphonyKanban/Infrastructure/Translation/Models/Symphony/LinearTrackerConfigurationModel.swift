import Foundation

enum LinearTrackerScope: Equatable {
    case project(slug: String)
    case team(id: String)
}

struct LinearNormalizedTrackerConfiguration {
    let endpoint: String
    let scope: LinearTrackerScope?
    let activeStateTypes: [String]
}

struct LinearTrackerConfigurationModel {
    func fromContract(
        from trackerConfiguration: SymphonyServiceConfigContract.Tracker,
        requireScope: Bool = true
    ) throws -> LinearNormalizedTrackerConfiguration {
        let trackerKind = trackerConfiguration.kind?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard trackerKind?.lowercased() == "linear" else {
            throw SymphonyIssueTrackerInfrastructureError.unsupportedTrackerKind(actualKind: trackerKind)
        }

        let endpoint = trackerConfiguration.endpoint?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEndpoint = (endpoint?.isEmpty == false)
            ? endpoint!
            : "https://api.linear.app/graphql"

        let projectSlug = trackerConfiguration.projectSlug?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let teamID = trackerConfiguration.teamID?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedProjectSlug = projectSlug?.isEmpty == false ? projectSlug : nil
        let normalizedTeamID = teamID?.isEmpty == false ? teamID : nil

        if normalizedProjectSlug != nil && normalizedTeamID != nil {
            throw SymphonyIssueTrackerInfrastructureError.ambiguousTrackerScope
        }

        let scope: LinearTrackerScope?
        if let normalizedProjectSlug {
            scope = .project(slug: normalizedProjectSlug)
        } else if let normalizedTeamID {
            scope = .team(id: normalizedTeamID)
        } else {
            scope = nil
        }

        if requireScope && scope == nil {
            throw SymphonyIssueTrackerInfrastructureError.missingTrackerScope
        }

        return LinearNormalizedTrackerConfiguration(
            endpoint: normalizedEndpoint,
            scope: scope,
            activeStateTypes: trackerConfiguration.activeStateTypes
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
    }
}
