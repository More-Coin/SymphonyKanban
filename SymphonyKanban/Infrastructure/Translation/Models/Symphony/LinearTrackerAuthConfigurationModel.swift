import Foundation

struct LinearTrackerAuthConfigurationModel {
    func fromContract(
        from trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) throws -> String {
        let normalizedTrackerKind = trackerConfiguration.kind?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""

        guard normalizedTrackerKind == "linear" else {
            throw SymphonyTrackerAuthInfrastructureError.unsupportedTrackerKind(
                actualKind: trackerConfiguration.kind ?? ""
            )
        }

        return normalizedTrackerKind
    }
}
