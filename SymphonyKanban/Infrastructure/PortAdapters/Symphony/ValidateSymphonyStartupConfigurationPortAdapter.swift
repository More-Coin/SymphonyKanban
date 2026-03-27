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

        guard let trackerAPIKey = configuration.tracker.apiKey?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !trackerAPIKey.isEmpty else {
            throw SymphonyStartupApplicationError.missingTrackerAPIKey
        }

        guard let projectSlug = configuration.tracker.projectSlug?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !projectSlug.isEmpty else {
            throw SymphonyStartupApplicationError.missingTrackerProjectIdentifier
        }

        guard !configuration.codex.command
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty else {
            throw SymphonyStartupApplicationError.missingAgentCommand
        }
    }
}
