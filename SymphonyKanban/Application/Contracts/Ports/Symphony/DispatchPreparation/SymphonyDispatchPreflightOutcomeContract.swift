public enum SymphonyDispatchPreflightOutcomeContract: Equatable, Sendable {
    case ready(SymphonyWorkflowConfigurationResultContract)
    case blocked(SymphonyDispatchPreflightBlockerError)
}
