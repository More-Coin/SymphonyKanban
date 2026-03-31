import Foundation

public struct SymphonyIssueTrackerSourceSelectionPolicy: Sendable {
    public enum Selection {
        case live
        case mock
    }

    public init() {}

    public func selectSource(
        trackerConfiguration: SymphonyServiceConfigContract.Tracker,
        authStatus: SymphonyTrackerAuthStatusContract?
    ) -> Selection {
        let trackerKind = trackerConfiguration.kind?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let projectSlug = trackerConfiguration.projectSlug?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let teamID = trackerConfiguration.teamID?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard trackerKind == "linear",
              (projectSlug?.isEmpty == false || teamID?.isEmpty == false),
              authStatus?.state == .connected else {
            return .mock
        }

        return .live
    }
}
