import Foundation

public enum SymphonyStartupApplicationError: StructuredErrorProtocol, LocalizedError {
    case missingTrackerKind
    case unsupportedTrackerKind(actualKind: String)
    case missingTrackerAPIKey
    case missingTrackerProjectIdentifier
    case missingAgentCommand

    public var code: String {
        switch self {
        case .missingTrackerKind:
            return "symphony.startup.missing_tracker_kind"
        case .unsupportedTrackerKind:
            return "symphony.startup.unsupported_tracker_kind"
        case .missingTrackerAPIKey:
            return "symphony.startup.missing_tracker_api_key"
        case .missingTrackerProjectIdentifier:
            return "symphony.startup.missing_tracker_project_identifier"
        case .missingAgentCommand:
            return "symphony.startup.missing_agent_command"
        }
    }

    public var message: String {
        switch self {
        case .missingTrackerKind:
            return "The workflow configuration is missing `tracker.kind`."
        case .unsupportedTrackerKind:
            return "The workflow configuration uses an unsupported tracker kind."
        case .missingTrackerAPIKey:
            return "The workflow configuration is missing a tracker API key."
        case .missingTrackerProjectIdentifier:
            return "The workflow configuration is missing the tracker project identifier."
        case .missingAgentCommand:
            return "The workflow configuration is missing the agent launch command."
        }
    }

    public var retryable: Bool {
        false
    }

    public var details: String? {
        switch self {
        case .missingTrackerKind:
            return "Set the tracker kind in the workflow configuration."
        case .unsupportedTrackerKind(let actualKind):
            return "Received configured tracker kind `\(actualKind)`."
        case .missingTrackerAPIKey:
            return "Set the tracker API key directly or through a non-empty environment variable indirection."
        case .missingTrackerProjectIdentifier:
            return "Set the tracker project identifier in the workflow configuration."
        case .missingAgentCommand:
            return "Set the agent launch command in the workflow configuration."
        }
    }

    public var errorDescription: String? {
        message
    }
}
