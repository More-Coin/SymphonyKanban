import Foundation

public struct SymphonyConfigResolverPortAdapter: SymphonyConfigResolverPortProtocol {
    private let configPathModel: SymphonyConfigPathModel

    public init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        self.configPathModel = SymphonyConfigPathModel(environment: environment)
    }

    public func resolveConfig(
        from definition: SymphonyWorkflowDefinitionContract
    ) -> SymphonyServiceConfigContract {
        let root = definition.config
        let tracker = object(for: "tracker", in: root)
        let polling = object(for: "polling", in: root)
        let workspace = object(for: "workspace", in: root)
        let hooks = object(for: "hooks", in: root)
        let agent = object(for: "agent", in: root)
        let codex = object(for: "codex", in: root)

        return SymphonyServiceConfigContract(
            tracker: .init(
                kind: string(for: "kind", in: tracker),
                endpoint: resolvedTrackerEndpoint(in: tracker),
                projectSlug: string(for: "project_slug", in: tracker),
                teamID: string(for: "team_id", in: tracker),
                activeStateTypes: stringArray(for: "active_state_types", in: tracker)
                    ?? ["backlog", "unstarted", "started"],
                terminalStateTypes: stringArray(for: "terminal_state_types", in: tracker)
                    ?? ["completed", "canceled"]
            ),
            polling: .init(
                intervalMs: integer(for: "interval_ms", in: polling) ?? 30000
            ),
            workspace: .init(
                rootPath: configPathModel.normalizedConfigWorkspaceRoot(
                    string(for: "root", in: workspace)
                ) ?? URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent("symphony_workspaces")
                    .standardizedFileURL
                    .path
            ),
            hooks: .init(
                afterCreate: string(for: "after_create", in: hooks),
                beforeRun: string(for: "before_run", in: hooks),
                afterRun: string(for: "after_run", in: hooks),
                beforeRemove: string(for: "before_remove", in: hooks),
                timeoutMs: resolvedHooksTimeout(in: hooks)
            ),
            agent: .init(
                maxConcurrentAgents: integer(for: "max_concurrent_agents", in: agent) ?? 10,
                maxTurns: integer(for: "max_turns", in: agent) ?? 20,
                maxRetryBackoffMs: integer(for: "max_retry_backoff_ms", in: agent) ?? 300000,
                maxConcurrentAgentsByState: resolvedPerStateConcurrency(in: agent)
            ),
            codex: .init(
                command: string(for: "command", in: codex) ?? "codex app-server",
                approvalPolicy: string(for: "approval_policy", in: codex),
                threadSandbox: string(for: "thread_sandbox", in: codex),
                turnSandboxPolicy: codex["turn_sandbox_policy"],
                turnTimeoutMs: integer(for: "turn_timeout_ms", in: codex) ?? 3600000,
                readTimeoutMs: integer(for: "read_timeout_ms", in: codex) ?? 5000,
                stallTimeoutMs: integer(for: "stall_timeout_ms", in: codex) ?? 300000
            )
        )
    }

    private func resolvedTrackerEndpoint(
        in config: [String: SymphonyConfigValueContract]
    ) -> String? {
        if let endpoint = string(for: "endpoint", in: config) {
            return endpoint
        }

        guard let trackerKind = string(for: "kind", in: config)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              trackerKind.lowercased() == "linear" else {
            return nil
        }

        return "https://api.linear.app/graphql"
    }

    private func resolvedHooksTimeout(
        in config: [String: SymphonyConfigValueContract]
    ) -> Int {
        guard let timeout = integer(for: "timeout_ms", in: config),
              timeout > 0 else {
            return 60000
        }

        return timeout
    }

    private func resolvedPerStateConcurrency(
        in config: [String: SymphonyConfigValueContract]
    ) -> [String: Int] {
        let mapping = object(for: "max_concurrent_agents_by_state", in: config)
        guard !mapping.isEmpty else {
            return [:]
        }

        var resolved: [String: Int] = [:]
        for (key, value) in mapping {
            guard let integerValue = value.integerValue,
                  integerValue > 0 else {
                continue
            }

            resolved[key.lowercased()] = integerValue
        }

        return resolved
    }

    private func object(
        for key: String,
        in config: [String: SymphonyConfigValueContract]
    ) -> [String: SymphonyConfigValueContract] {
        config[key]?.dictionaryValue ?? [:]
    }

    private func string(
        for key: String,
        in config: [String: SymphonyConfigValueContract]
    ) -> String? {
        config[key]?.stringValue
    }

    private func integer(
        for key: String,
        in config: [String: SymphonyConfigValueContract]
    ) -> Int? {
        config[key]?.integerValue
    }

    private func stringArray(
        for key: String,
        in config: [String: SymphonyConfigValueContract]
    ) -> [String]? {
        guard case .array(let values)? = config[key] else {
            return nil
        }

        return values.compactMap(\.stringValue)
    }

}
