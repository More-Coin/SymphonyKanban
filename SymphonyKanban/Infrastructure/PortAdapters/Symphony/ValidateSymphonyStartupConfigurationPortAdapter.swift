import Foundation

public struct ValidateSymphonyStartupConfigurationPortAdapter:
    SymphonyStartupConfigurationValidatorPortProtocol
{
    public init() {}

    public func validate(
        _ configuration: SymphonyServiceConfigContract
    ) throws {
        guard let trackerKind = configuration.tracker.kind?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !trackerKind.isEmpty else {
            throw SymphonyStartupApplicationError.missingTrackerKind
        }

        guard trackerKind.lowercased() == "linear" else {
            throw SymphonyStartupApplicationError.unsupportedTrackerKind(actualKind: trackerKind)
        }

        let projectSlug = configuration.tracker.projectSlug?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let teamID = configuration.tracker.teamID?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let hasProjectSlug = projectSlug?.isEmpty == false
        let hasTeamID = teamID?.isEmpty == false

        guard hasProjectSlug || hasTeamID else {
            throw SymphonyStartupApplicationError.missingTrackerScopeIdentifier
        }

        guard !(hasProjectSlug && hasTeamID) else {
            throw SymphonyStartupApplicationError.ambiguousTrackerScopeIdentifier
        }

        guard !configuration.codex.command
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty else {
            throw SymphonyStartupApplicationError.missingAgentCommand
        }
    }
}
