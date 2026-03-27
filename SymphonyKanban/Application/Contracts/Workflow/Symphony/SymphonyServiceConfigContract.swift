import Foundation

public struct SymphonyServiceConfigContract: Equatable, Sendable {
    public struct Tracker: Equatable, Sendable {
        public let kind: String?
        public let endpoint: String?
        public let projectSlug: String?
        public let activeStates: [String]
        public let terminalStates: [String]

        public var normalizedActiveStates: Set<String> {
            Set(activeStates.map(Self.normalizeState))
        }

        public var normalizedTerminalStates: Set<String> {
            Set(terminalStates.map(Self.normalizeState))
        }

        public func normalizedState(_ state: String) -> String {
            Self.normalizeState(state)
        }

        public func containsActiveState(_ state: String) -> Bool {
            normalizedActiveStates.contains(Self.normalizeState(state))
        }

        public func containsTerminalState(_ state: String) -> Bool {
            normalizedTerminalStates.contains(Self.normalizeState(state))
        }

        private static func normalizeState(_ state: String) -> String {
            state.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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
