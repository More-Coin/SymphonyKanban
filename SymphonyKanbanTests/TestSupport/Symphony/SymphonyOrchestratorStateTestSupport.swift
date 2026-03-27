import Foundation
@testable import SymphonyKanban

enum SymphonyOrchestratorStateTestSupport {
    static func makeState(
        running: [String: SymphonyRunningEntryContract<String, String>] = [:],
        claimed: Set<String> = [],
        retryAttempts: [String: SymphonyRetryEntryContract<String>] = [:],
        completed: Set<String> = [],
        codexTotals: SymphonyCodexTotalsContract = .init(
            inputTokens: 0,
            outputTokens: 0,
            totalTokens: 0,
            secondsRunning: 0
        )
    ) -> SymphonyRuntimeStateContract<String, String, String> {
        SymphonyRuntimeStateContract(
            pollIntervalMs: 30_000,
            maxConcurrentAgents: 5,
            running: running,
            claimed: claimed,
            retryAttempts: retryAttempts,
            completed: completed,
            codexTotals: codexTotals,
            codexRateLimits: nil
        )
    }

    static func makeServiceConfig(
        maxConcurrentAgents: Int = 5,
        maxConcurrentAgentsByState: [String: Int] = [:],
        maxRetryBackoffMs: Int = 300_000,
        terminalStates: [String] = ["Done", "Canceled", "Cancelled", "Duplicate"]
    ) -> SymphonyServiceConfigContract {
        SymphonyServiceConfigContract(
            tracker: .init(
                kind: "linear",
                endpoint: "https://api.linear.app/graphql",
                apiKey: "token",
                projectSlug: "proj",
                activeStates: ["Todo", "In Progress"],
                terminalStates: terminalStates
            ),
            polling: .init(intervalMs: 30_000),
            workspace: .init(rootPath: "/tmp/symphony_workspaces"),
            hooks: .init(
                afterCreate: nil,
                beforeRun: nil,
                afterRun: nil,
                beforeRemove: nil,
                timeoutMs: 60_000
            ),
            agent: .init(
                maxConcurrentAgents: maxConcurrentAgents,
                maxTurns: 20,
                maxRetryBackoffMs: maxRetryBackoffMs,
                maxConcurrentAgentsByState: maxConcurrentAgentsByState
            ),
            codex: .init(
                command: "codex app-server",
                approvalPolicy: nil,
                threadSandbox: nil,
                turnSandboxPolicy: nil,
                turnTimeoutMs: 3_600_000,
                readTimeoutMs: 5_000,
                stallTimeoutMs: 300_000
            )
        )
    }

    static func makeIssue(
        id: String,
        identifier: String,
        priority: Int?,
        state: String,
        blockedBy: [SymphonyIssueBlockerReference] = [],
        createdAt: Date? = nil
    ) -> SymphonyIssue {
        SymphonyIssue(
            id: id,
            identifier: identifier,
            title: "Issue \(identifier)",
            description: nil,
            priority: priority,
            state: state,
            branchName: nil,
            url: nil,
            labels: [],
            blockedBy: blockedBy,
            createdAt: createdAt,
            updatedAt: nil
        )
    }

    static func makeRunningEntry(
        issue: SymphonyIssue,
        liveSession: SymphonyLiveSessionContract? = nil,
        retryAttempt: Int? = nil,
        startedAt: Date = Date(timeIntervalSince1970: 0)
    ) -> SymphonyRunningEntryContract<String, String> {
        SymphonyRunningEntryContract(
            workerHandle: "worker-\(issue.id)",
            monitorHandle: "monitor-\(issue.id)",
            identifier: issue.identifier,
            issue: issue,
            liveSession: liveSession,
            retryAttempt: retryAttempt,
            startedAt: startedAt
        )
    }

    static func makeRetryEntry(
        issueID: String,
        identifier: String,
        attempt: Int,
        dueAtMs: Int64,
        timerHandle: String,
        error: String?
    ) -> SymphonyRetryEntryContract<String> {
        SymphonyRetryEntryContract(
            issueID: issueID,
            identifier: identifier,
            attempt: attempt,
            dueAtMs: dueAtMs,
            timerHandle: timerHandle,
            error: error
        )
    }
}
