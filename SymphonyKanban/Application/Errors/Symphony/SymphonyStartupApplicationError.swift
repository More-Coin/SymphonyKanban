import Foundation

public enum SymphonyStartupApplicationError: StructuredErrorProtocol, LocalizedError, Equatable {
    case missingTrackerKind
    case unsupportedTrackerKind(actualKind: String)
    case missingTrackerScopeIdentifier
    case ambiguousTrackerScopeIdentifier
    case missingAgentCommand
    case trackerAuthNotConnected(trackerKind: String)
    case trackerSessionStale(trackerKind: String)

    public var code: String {
        switch self {
        case .missingTrackerKind:
            return "symphony.startup.missing_tracker_kind"
        case .unsupportedTrackerKind:
            return "symphony.startup.unsupported_tracker_kind"
        case .missingTrackerScopeIdentifier:
            return "symphony.startup.missing_tracker_scope_identifier"
        case .ambiguousTrackerScopeIdentifier:
            return "symphony.startup.ambiguous_tracker_scope_identifier"
        case .missingAgentCommand:
            return "symphony.startup.missing_agent_command"
        case .trackerAuthNotConnected:
            return "symphony.startup.tracker_auth_not_connected"
        case .trackerSessionStale:
            return "symphony.startup.tracker_session_stale"
        }
    }

    public var message: String {
        switch self {
        case .missingTrackerKind:
            return "The workflow configuration is missing `tracker.kind`."
        case .unsupportedTrackerKind:
            return "The workflow configuration uses an unsupported tracker kind."
        case .missingTrackerScopeIdentifier:
            return "The workflow configuration is missing the tracker scope identifier."
        case .ambiguousTrackerScopeIdentifier:
            return "The workflow configuration must define exactly one tracker scope identifier."
        case .missingAgentCommand:
            return "The workflow configuration is missing the agent launch command."
        case .trackerAuthNotConnected:
            return "The tracker is not connected for this Symphony session."
        case .trackerSessionStale:
            return "The tracker session is stale and must be reconnected."
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
        case .missingTrackerScopeIdentifier:
            return "Set exactly one tracker scope identifier in the workflow configuration."
        case .ambiguousTrackerScopeIdentifier:
            return "Keep only one tracker scope identifier in the workflow configuration."
        case .missingAgentCommand:
            return "Set the agent launch command in the workflow configuration."
        case .trackerAuthNotConnected(let trackerKind):
            return "Start the \(trackerKind) connect flow before launching Symphony."
        case .trackerSessionStale(let trackerKind):
            return "Reconnect \(trackerKind) to refresh the stored session."
        }
    }

    public var errorDescription: String? {
        message
    }
}
