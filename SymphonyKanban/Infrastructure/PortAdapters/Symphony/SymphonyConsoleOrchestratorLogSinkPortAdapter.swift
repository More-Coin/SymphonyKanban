import Foundation

public struct SymphonyConsoleOrchestratorLogSinkPortAdapter:
    SymphonyOrchestratorLogSinkPortProtocol,
    SymphonyWorkerAttemptLogSinkPortProtocol,
    SymphonyRuntimeStatusSinkPortProtocol {
    public typealias Sink = @Sendable (String) throws -> Void

    private let standardOutputSink: Sink
    private let standardErrorSink: Sink

    public init(
        standardOutputSink: @escaping Sink = { print($0) },
        standardErrorSink: @escaping Sink = { message in
            fputs("\(message)\n", stderr)
        }
    ) {
        self.standardOutputSink = standardOutputSink
        self.standardErrorSink = standardErrorSink
    }

    public func emit(_ event: SymphonyOrchestratorLogEventContract) {
        let line = format(event)
        switch event.kind {
        case .warning:
            write(
                line,
                preferredSink: standardErrorSink,
                preferredSinkName: "stderr",
                fallbackSink: standardOutputSink,
                fallbackSinkName: "stdout",
                surface: "orchestrator_log"
            )
        default:
            write(
                line,
                preferredSink: standardOutputSink,
                preferredSinkName: "stdout",
                fallbackSink: standardErrorSink,
                fallbackSinkName: "stderr",
                surface: "orchestrator_log"
            )
        }
    }

    public func emit(_ event: SymphonyWorkerAttemptLogEventContract) {
        let line = format(event)
        switch event.kind {
        case .startupFailure, .timeout, .cancellation, .abnormalExit, .policyFailure, .unsupportedToolEvent, .userInputRequired:
            write(
                line,
                preferredSink: standardErrorSink,
                preferredSinkName: "stderr",
                fallbackSink: standardOutputSink,
                fallbackSinkName: "stdout",
                surface: "worker_log"
            )
        case .attemptStarted, .attemptCompleted:
            write(
                line,
                preferredSink: standardOutputSink,
                preferredSinkName: "stdout",
                fallbackSink: standardErrorSink,
                fallbackSinkName: "stderr",
                surface: "worker_log"
            )
        }
    }

    public func emit(_ snapshot: SymphonyRuntimeStatusSnapshotContract) {
        write(
            formatSummary(snapshot),
            preferredSink: standardOutputSink,
            preferredSinkName: "stdout",
            fallbackSink: standardErrorSink,
            fallbackSinkName: "stderr",
            surface: "runtime_status"
        )

        for row in snapshot.running {
            write(
                formatRunningRow(row),
                preferredSink: standardOutputSink,
                preferredSinkName: "stdout",
                fallbackSink: standardErrorSink,
                fallbackSinkName: "stderr",
                surface: "runtime_status"
            )
        }

        for row in snapshot.retrying {
            write(
                formatRetryRow(row),
                preferredSink: standardOutputSink,
                preferredSinkName: "stdout",
                fallbackSink: standardErrorSink,
                fallbackSinkName: "stderr",
                surface: "runtime_status"
            )
        }

        if let codexRateLimits = snapshot.codexRateLimits {
            write(
                formatRateLimitLine(codexRateLimits),
                preferredSink: standardOutputSink,
                preferredSinkName: "stdout",
                fallbackSink: standardErrorSink,
                fallbackSinkName: "stderr",
                surface: "runtime_status"
            )
        }
    }

    private func format(_ event: SymphonyOrchestratorLogEventContract) -> String {
        var components = [
            "component=symphony",
            "event=\(event.kind.rawValue)",
            "outcome=\(event.outcome)"
        ]

        if let issueID = event.issueID {
            components.append("issue_id=\(issueID)")
        }
        if let issueIdentifier = event.issueIdentifier {
            components.append("issue_identifier=\(issueIdentifier)")
        }
        if let sessionID = event.sessionID {
            components.append("session_id=\(sessionID)")
        }
        if let message = event.message {
            components.append("message=\"\(escaped(message))\"")
        }

        for key in event.details.keys.sorted() {
            guard let value = event.details[key] else {
                continue
            }
            components.append("\(key)=\"\(escaped(value))\"")
        }

        return components.joined(separator: " ")
    }

    private func format(_ event: SymphonyWorkerAttemptLogEventContract) -> String {
        var components = [
            "component=symphony",
            "event=\(event.kind.rawValue)",
            "issue_id=\(event.issueID)",
            "issue_identifier=\(event.issueIdentifier)",
            "turn_count=\(event.turnCount)"
        ]

        if let attempt = event.attempt {
            components.append("attempt=\(attempt)")
        }
        if let workspacePath = event.workspacePath {
            components.append("workspace_path=\"\(escaped(workspacePath))\"")
        }
        if let sessionID = event.sessionID {
            components.append("session_id=\(sessionID)")
        }
        if let threadID = event.threadID {
            components.append("thread_id=\(threadID)")
        }
        if let turnID = event.turnID {
            components.append("turn_id=\(turnID)")
        }
        if let terminalReason = event.terminalReason {
            components.append("terminal_reason=\(terminalReason.rawValue)")
        }
        if let message = event.message {
            components.append("message=\"\(escaped(message))\"")
        }

        return components.joined(separator: " ")
    }

    private func escaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    private func formatSummary(_ snapshot: SymphonyRuntimeStatusSnapshotContract) -> String {
        [
            "component=symphony",
            "event=runtime_status",
            "outcome=\(snapshot.outcome)",
            "generated_at=\"\(iso8601String(from: snapshot.generatedAt))\"",
            "running_count=\(snapshot.running.count)",
            "retrying_count=\(snapshot.retrying.count)",
            "claimed_count=\(snapshot.claimedCount)",
            "completed_count=\(snapshot.completedCount)",
            "input_tokens=\(snapshot.codexTotals.inputTokens)",
            "output_tokens=\(snapshot.codexTotals.outputTokens)",
            "total_tokens=\(snapshot.codexTotals.totalTokens)",
            "seconds_running=\(formatSeconds(snapshot.codexTotals.secondsRunning))"
        ].joined(separator: " ")
    }

    private func formatRunningRow(_ row: SymphonyRuntimeStatusRunningRowContract) -> String {
        var components = [
            "component=symphony",
            "event=runtime_status_row",
            "outcome=running",
            "issue_id=\(row.issueID)",
            "issue_identifier=\(row.issueIdentifier)",
            "state=\"\(escaped(row.state))\"",
            "started_at=\"\(iso8601String(from: row.startedAt))\""
        ]

        if let sessionID = row.sessionID {
            components.append("session_id=\(sessionID)")
        }
        if let turnCount = row.turnCount {
            components.append("turn_count=\(turnCount)")
        }
        if let retryAttempt = row.retryAttempt {
            components.append("retry_attempt=\(retryAttempt)")
        }

        return components.joined(separator: " ")
    }

    private func formatRetryRow(_ row: SymphonyRuntimeStatusRetryRowContract) -> String {
        var components = [
            "component=symphony",
            "event=runtime_status_row",
            "outcome=retrying",
            "issue_id=\(row.issueID)",
            "issue_identifier=\(row.issueIdentifier)",
            "attempt=\(row.attempt)",
            "due_at_ms=\(row.dueAtMs)"
        ]

        if let error = row.error {
            components.append("error=\"\(escaped(error))\"")
        }

        return components.joined(separator: " ")
    }

    private func formatRateLimitLine(
        _ codexRateLimits: SymphonyCodexRateLimitSnapshotContract
    ) -> String {
        [
            "component=symphony",
            "event=runtime_status_rate_limit",
            "outcome=present",
            "rate_limit=\"\(escaped(compactDescription(for: codexRateLimits.payload)))\""
        ].joined(separator: " ")
    }

    private func write(
        _ line: String,
        preferredSink: Sink,
        preferredSinkName: String,
        fallbackSink: Sink,
        fallbackSinkName: String,
        surface: String
    ) {
        do {
            try preferredSink(line)
        } catch {
            let warningLine = [
                "component=symphony",
                "event=warning",
                "outcome=sink_failed",
                "surface=\(surface)",
                "failed_sink=\(preferredSinkName)",
                "fallback_sink=\(fallbackSinkName)",
                "reason=\"\(escaped(String(describing: error)))\""
            ].joined(separator: " ")

            do {
                try fallbackSink(warningLine)
            } catch {
                // Drop the warning if every configured sink has failed.
            }
        }
    }

    private func compactDescription(for value: SymphonyConfigValueContract) -> String {
        switch value {
        case .string(let string):
            return truncated(string)
        case .integer(let integer):
            return String(integer)
        case .double(let double):
            return String(double)
        case .bool(let bool):
            return String(bool)
        case .null:
            return "null"
        case .array(let values):
            let joined = values.prefix(3).map(compactDescription(for:)).joined(separator: ",")
            let suffix = values.count > 3 ? ",..." : ""
            return "[\(joined)\(suffix)]"
        case .object(let values):
            let joined = values.keys.sorted().prefix(4).map { key in
                "\(key):\(compactDescription(for: values[key] ?? .null))"
            }.joined(separator: ",")
            let suffix = values.count > 4 ? ",..." : ""
            return "{\(joined)\(suffix)}"
        }
    }

    private func truncated(_ value: String, limit: Int = 120) -> String {
        guard value.count > limit else {
            return value
        }

        return String(value.prefix(limit)) + "..."
    }

    private func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    private func formatSeconds(_ value: Double) -> String {
        String(format: "%.3f", value)
    }
}
