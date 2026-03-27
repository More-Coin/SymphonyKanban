import Foundation

public struct SymphonyServiceConfigContract: Equatable, Sendable {
    public struct Tracker: Equatable, Sendable {
        public let kind: String?
        public let endpoint: String?
        public let projectSlug: String?
        public let activeStateTypes: [String]
        public let terminalStateTypes: [String]

        public var normalizedActiveStateTypes: Set<String> {
            Set(activeStateTypes.map(Self.normalizeStateType))
        }

        public var normalizedTerminalStateTypes: Set<String> {
            Set(terminalStateTypes.map(Self.normalizeStateType))
        }

        public func normalizedStateType(_ stateType: String) -> String {
            Self.normalizeStateType(stateType)
        }

        public func containsActiveStateType(_ stateType: String) -> Bool {
            normalizedActiveStateTypes.contains(Self.normalizeStateType(stateType))
        }

        public func containsTerminalStateType(_ stateType: String) -> Bool {
            normalizedTerminalStateTypes.contains(Self.normalizeStateType(stateType))
        }

        private static func normalizeStateType(_ stateType: String) -> String {
            stateType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
    }

    public struct Polling: Equatable, Sendable {
        public let intervalMs: Int
    }

    public struct Workspace: Equatable, Sendable {
        public let rootPath: String
    }

    public struct Hooks: Equatable, Sendable {
        public let afterCreate: String?
        public let beforeRun: String?
        public let afterRun: String?
        public let beforeRemove: String?
        public let timeoutMs: Int
    }

    public struct Agent: Equatable, Sendable {
        public let maxConcurrentAgents: Int
        public let maxTurns: Int
        public let maxRetryBackoffMs: Int
        public let maxConcurrentAgentsByState: [String: Int]
    }

    public struct Codex: Equatable, Sendable {
        public let command: String
        public let approvalPolicy: String?
        public let threadSandbox: String?
        public let turnSandboxPolicy: SymphonyConfigValueContract?
        public let turnTimeoutMs: Int
        public let readTimeoutMs: Int
        public let stallTimeoutMs: Int
    }

    public let tracker: Tracker
    public let polling: Polling
    public let workspace: Workspace
    public let hooks: Hooks
    public let agent: Agent
    public let codex: Codex

    public init(
        tracker: Tracker,
        polling: Polling,
        workspace: Workspace,
        hooks: Hooks,
        agent: Agent,
        codex: Codex
    ) {
        self.tracker = tracker
        self.polling = polling
        self.workspace = workspace
        self.hooks = hooks
        self.agent = agent
        self.codex = codex
    }

    public var workerStallTimeoutMs: Int {
        codex.stallTimeoutMs
    }
}
