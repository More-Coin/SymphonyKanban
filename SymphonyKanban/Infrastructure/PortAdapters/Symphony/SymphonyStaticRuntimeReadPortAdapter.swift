import Foundation

public struct SymphonyStaticRuntimeReadPortAdapter: SymphonyRuntimeDashboardReadPortProtocol, SymphonyRuntimeIssueDetailReadPortProtocol {
    public init() {}

    public func readRuntimeDashboardSnapshot(generatedAt: Date) -> SymphonyRuntimeDashboardSnapshotContract {
        SymphonyRuntimeDashboardSnapshotContract(
            generatedAt: generatedAt,
            outcome: "Monitoring",
            counts: SymphonyRuntimeDashboardSnapshotContract.Counts(
                runningCount: 2,
                retryingCount: 1,
                claimedCount: 4,
                completedCount: 18
            ),
            running: [
                SymphonyRuntimeDashboardSnapshotContract.RunningRow(
                    issueID: "issue-142",
                    issueIdentifier: "KAN-142",
                    state: "Doing",
                    sessionID: "sess-142",
                    turnCount: 9,
                    retryAttempt: nil,
                    lastEvent: "tool_call",
                    lastMessage: "Patched dashboard presenter",
                    startedAt: generatedAt.addingTimeInterval(-3240),
                    lastEventAt: generatedAt.addingTimeInterval(-120),
                    tokens: SymphonyCodexUsageSnapshotContract(
                        inputTokens: 12000,
                        outputTokens: 4000,
                        totalTokens: 16000
                    )
                ),
                SymphonyRuntimeDashboardSnapshotContract.RunningRow(
                    issueID: "issue-177",
                    issueIdentifier: "KAN-177",
                    state: "Review",
                    sessionID: "sess-177",
                    turnCount: 5,
                    retryAttempt: 1,
                    lastEvent: "lint",
                    lastMessage: "Architecture linter passed",
                    startedAt: generatedAt.addingTimeInterval(-5400),
                    lastEventAt: generatedAt.addingTimeInterval(-600),
                    tokens: SymphonyCodexUsageSnapshotContract(
                        inputTokens: 8100,
                        outputTokens: 3300,
                        totalTokens: 11400
                    )
                )
            ],
            retrying: [
                SymphonyRuntimeDashboardSnapshotContract.RetryRow(
                    issueID: "issue-181",
                    issueIdentifier: "KAN-181",
                    attempt: 2,
                    dueAt: generatedAt.addingTimeInterval(420),
                    error: "Linear sync timed out during status reconciliation."
                )
            ],
            codexTotals: SymphonyCodexTotalsContract(
                inputTokens: 34100,
                outputTokens: 10900,
                totalTokens: 45000,
                secondsRunning: 3492
            ),
            rateLimits: SymphonyCodexRateLimitSnapshotContract(
                payload: .object([
                    "requestsRemaining": .integer(87),
                    "tokensRemaining": .integer(412000)
                ])
            ),
            tracked: [
                "model": .string("gpt-5.4"),
                "workflow": .string("dashboard"),
                "workspaceMode": .string("readonly")
            ]
        )
    }

    public func readRuntimeIssueDetailSnapshot(
        issueIdentifier: String,
        generatedAt: Date
    ) -> SymphonyRuntimeIssueDetailSnapshotContract? {
        switch issueIdentifier {
        case "KAN-142":
            return detailSnapshotKAN142(generatedAt: generatedAt)
        case "KAN-177":
            return detailSnapshotKAN177(generatedAt: generatedAt)
        case "KAN-181":
            return detailSnapshotKAN181(generatedAt: generatedAt)
        default:
            return nil
        }
    }

    private func detailSnapshotKAN142(generatedAt: Date) -> SymphonyRuntimeIssueDetailSnapshotContract {
        SymphonyRuntimeIssueDetailSnapshotContract(
            generatedAt: generatedAt,
            issue: SymphonyRuntimeIssueDetailSnapshotContract.IssueSummary(
                issueID: "issue-142",
                issueIdentifier: "KAN-142",
                title: "Rebuild Symphony dashboard pipeline",
                description: "Rebuild the dashboard presentation slice around controller, presenter, and page-level view models.",
                priority: 2,
                state: "Doing",
                branchName: "feature/dashboard-pipeline",
                url: "https://linear.app/example/KAN-142",
                labels: ["symphony", "dashboard"],
                createdAt: generatedAt.addingTimeInterval(-86400 * 2),
                updatedAt: generatedAt.addingTimeInterval(-900)
            ),
            status: "Running",
            workspace: SymphonyRuntimeIssueDetailSnapshotContract.Workspace(
                path: "/tmp/symphony/workspaces/KAN-142"
            ),
            attempts: SymphonyRuntimeIssueDetailSnapshotContract.Attempts(
                restartCount: 2,
                currentRetryAttempt: nil
            ),
            running: SymphonyRuntimeIssueDetailSnapshotContract.RunningDetail(
                sessionID: "sess-142",
                threadID: "thr-142",
                turnID: "turn-9",
                codexAppServerPID: "80121",
                turnCount: 9,
                state: "Running",
                startedAt: generatedAt.addingTimeInterval(-3240),
                lastEvent: "tool_call",
                lastMessage: "Patched dashboard presenter",
                lastEventAt: generatedAt.addingTimeInterval(-120),
                tokens: SymphonyCodexUsageSnapshotContract(
                    inputTokens: 12000,
                    outputTokens: 4000,
                    totalTokens: 16000
                )
            ),
            retry: nil,
            logs: SymphonyRuntimeIssueDetailSnapshotContract.LogCollection(
                codexSessionLogs: [
                    SymphonyRuntimeIssueDetailSnapshotContract.LogLink(
                        label: "Console",
                        path: "/tmp/symphony/logs/KAN-142-console.log",
                        url: nil
                    ),
                    SymphonyRuntimeIssueDetailSnapshotContract.LogLink(
                        label: "Structured Events",
                        path: "/tmp/symphony/logs/KAN-142-events.jsonl",
                        url: nil
                    )
                ]
            ),
            recentEvents: [
                SymphonyRuntimeIssueDetailSnapshotContract.RecentEvent(
                    at: generatedAt.addingTimeInterval(-120),
                    event: "tool_call",
                    message: "Patched dashboard presenter",
                    details: ["file": .string("Presentation/Presenters/Symphony/SymphonyDashboardPresenter.swift")]
                ),
                SymphonyRuntimeIssueDetailSnapshotContract.RecentEvent(
                    at: generatedAt.addingTimeInterval(-420),
                    event: "build",
                    message: "Swift package build completed",
                    details: ["scheme": .string("SymphonyKanban")]
                )
            ],
            lastError: nil,
            tracked: [
                "model": .string("gpt-5.4"),
                "workflow": .string("dashboard"),
                "workspaceMode": .string("readonly")
            ]
        )
    }

    private func detailSnapshotKAN177(generatedAt: Date) -> SymphonyRuntimeIssueDetailSnapshotContract {
        SymphonyRuntimeIssueDetailSnapshotContract(
            generatedAt: generatedAt,
            issue: SymphonyRuntimeIssueDetailSnapshotContract.IssueSummary(
                issueID: "issue-177",
                issueIdentifier: "KAN-177",
                title: "Wire issue detail renderer",
                description: "Shape runtime detail output through a dedicated presenter and renderer pair.",
                priority: 3,
                state: "Review",
                branchName: "feature/issue-detail-renderer",
                url: "https://linear.app/example/KAN-177",
                labels: ["symphony", "detail"],
                createdAt: generatedAt.addingTimeInterval(-86400 * 3),
                updatedAt: generatedAt.addingTimeInterval(-1800)
            ),
            status: "Review",
            workspace: SymphonyRuntimeIssueDetailSnapshotContract.Workspace(
                path: "/tmp/symphony/workspaces/KAN-177"
            ),
            attempts: SymphonyRuntimeIssueDetailSnapshotContract.Attempts(
                restartCount: 1,
                currentRetryAttempt: 1
            ),
            running: SymphonyRuntimeIssueDetailSnapshotContract.RunningDetail(
                sessionID: "sess-177",
                threadID: "thr-177",
                turnID: "turn-5",
                codexAppServerPID: "80410",
                turnCount: 5,
                state: "Review",
                startedAt: generatedAt.addingTimeInterval(-5400),
                lastEvent: "lint",
                lastMessage: "Architecture linter passed",
                lastEventAt: generatedAt.addingTimeInterval(-600),
                tokens: SymphonyCodexUsageSnapshotContract(
                    inputTokens: 8100,
                    outputTokens: 3300,
                    totalTokens: 11400
                )
            ),
            retry: nil,
            logs: SymphonyRuntimeIssueDetailSnapshotContract.LogCollection(
                codexSessionLogs: [
                    SymphonyRuntimeIssueDetailSnapshotContract.LogLink(
                        label: "Review Notes",
                        path: "/tmp/symphony/logs/KAN-177-review.log",
                        url: nil
                    )
                ]
            ),
            recentEvents: [
                SymphonyRuntimeIssueDetailSnapshotContract.RecentEvent(
                    at: generatedAt.addingTimeInterval(-600),
                    event: "lint",
                    message: "Architecture linter passed",
                    details: [:]
                ),
                SymphonyRuntimeIssueDetailSnapshotContract.RecentEvent(
                    at: generatedAt.addingTimeInterval(-1500),
                    event: "build",
                    message: "Xcode build passed cleanly",
                    details: [:]
                )
            ],
            lastError: nil,
            tracked: [
                "model": .string("gpt-5.4"),
                "workflow": .string("issue-detail")
            ]
        )
    }

    private func detailSnapshotKAN181(generatedAt: Date) -> SymphonyRuntimeIssueDetailSnapshotContract {
        SymphonyRuntimeIssueDetailSnapshotContract(
            generatedAt: generatedAt,
            issue: SymphonyRuntimeIssueDetailSnapshotContract.IssueSummary(
                issueID: "issue-181",
                issueIdentifier: "KAN-181",
                title: "Harden refresh route selection handling",
                description: "Tighten route refresh behavior so selection survives state reloads.",
                priority: 2,
                state: "Blocked",
                branchName: "feature/refresh-selection",
                url: "https://linear.app/example/KAN-181",
                labels: ["symphony", "refresh"],
                createdAt: generatedAt.addingTimeInterval(-86400),
                updatedAt: generatedAt.addingTimeInterval(-300)
            ),
            status: "Retry Queued",
            workspace: SymphonyRuntimeIssueDetailSnapshotContract.Workspace(
                path: "/tmp/symphony/workspaces/KAN-181"
            ),
            attempts: SymphonyRuntimeIssueDetailSnapshotContract.Attempts(
                restartCount: 3,
                currentRetryAttempt: 2
            ),
            running: nil,
            retry: SymphonyRuntimeIssueDetailSnapshotContract.RetryDetail(
                attempt: 2,
                dueAt: generatedAt.addingTimeInterval(420),
                error: "Linear sync timed out during status reconciliation."
            ),
            logs: SymphonyRuntimeIssueDetailSnapshotContract.LogCollection(
                codexSessionLogs: [
                    SymphonyRuntimeIssueDetailSnapshotContract.LogLink(
                        label: "Retry Trace",
                        path: "/tmp/symphony/logs/KAN-181-retry.log",
                        url: nil
                    )
                ]
            ),
            recentEvents: [
                SymphonyRuntimeIssueDetailSnapshotContract.RecentEvent(
                    at: generatedAt.addingTimeInterval(-300),
                    event: "retry_scheduled",
                    message: "Queued retry after Linear sync timeout",
                    details: ["attempt": .integer(2)]
                )
            ],
            lastError: SymphonyRuntimeIssueDetailSnapshotContract.ErrorSnapshot(
                code: "LINEAR_TIMEOUT",
                message: "Linear sync timed out during status reconciliation.",
                occurredAt: generatedAt.addingTimeInterval(-300),
                details: [
                    "service": .string("Linear"),
                    "timeoutSeconds": .integer(30)
                ]
            ),
            tracked: [
                "model": .string("gpt-5.4"),
                "workflow": .string("refresh"),
                "workspaceMode": .string("readonly")
            ]
        )
    }
}
