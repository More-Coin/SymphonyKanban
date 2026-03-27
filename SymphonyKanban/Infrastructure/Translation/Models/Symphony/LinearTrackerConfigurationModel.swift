import Foundation

struct LinearNormalizedTrackerConfiguration {
    let endpoint: String
    let apiKey: String
    let projectSlug: String
    let activeStates: [String]
}

struct LinearTrackerConfigurationModel {
    func fromContract(
        from trackerConfiguration: SymphonyServiceConfigContract.Tracker,
        requireProjectSlug: Bool = true
    ) throws -> LinearNormalizedTrackerConfiguration {
        let trackerKind = trackerConfiguration.kind?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard trackerKind?.lowercased() == "linear" else {
            throw SymphonyIssueTrackerInfrastructureError.unsupportedTrackerKind(actualKind: trackerKind)
        }

        guard let apiKey = trackerConfiguration.apiKey?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !apiKey.isEmpty else {
            throw SymphonyIssueTrackerInfrastructureError.missingTrackerAPIKey
        }

        let endpoint = trackerConfiguration.endpoint?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEndpoint = (endpoint?.isEmpty == false)
            ? endpoint!
            : "https://api.linear.app/graphql"

        let projectSlug = trackerConfiguration.projectSlug?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if requireProjectSlug && (projectSlug?.isEmpty != false) {
            throw SymphonyIssueTrackerInfrastructureError.missingTrackerProjectSlug
        }

        return LinearNormalizedTrackerConfiguration(
            endpoint: normalizedEndpoint,
            apiKey: apiKey,
            projectSlug: projectSlug ?? "",
            activeStates: trackerConfiguration.activeStates
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
    }
}
