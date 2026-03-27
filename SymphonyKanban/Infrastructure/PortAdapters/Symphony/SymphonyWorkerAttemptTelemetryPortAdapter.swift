import Foundation

public final class SymphonyWorkerAttemptTelemetryPortAdapter: SymphonyWorkerAttemptTelemetryPortProtocol {
    private let logSink: any SymphonyWorkerAttemptLogSinkPortProtocol

    public init(logSink: any SymphonyWorkerAttemptLogSinkPortProtocol) {
        self.logSink = logSink
    }

    public func makeRecorder(
        issueID: String,
        issueIdentifier: String,
        attempt: Int?
    ) -> any SymphonyWorkerAttemptTelemetryRecorderPortProtocol {
        RecorderPortAdapter(
            logSink: logSink,
            issueID: issueID,
            issueIdentifier: issueIdentifier,
            attempt: attempt
        )
    }

    private final class RecorderPortAdapter: @unchecked Sendable, SymphonyWorkerAttemptTelemetryRecorderPortProtocol {
        private let lock = NSLock()
        private let logSink: any SymphonyWorkerAttemptLogSinkPortProtocol
        private let issueID: String
        private let issueIdentifier: String
        private let attempt: Int?

        private var liveSession: SymphonyLiveSessionContract?

        init(
            logSink: any SymphonyWorkerAttemptLogSinkPortProtocol,
            issueID: String,
            issueIdentifier: String,
            attempt: Int?
        ) {
            self.logSink = logSink
            self.issueID = issueID
            self.issueIdentifier = issueIdentifier
            self.attempt = attempt
        }

        func emit(
            kind: SymphonyWorkerAttemptLogEventContract.Kind,
            timestamp: Date,
            turnCount: Int,
            workspacePath: String?,
            terminalReason: SymphonyWorkerAttemptTerminalReasonContract?,
            message: String?
        ) {
            let liveSession = liveSessionSnapshot()
            logSink.emit(
                SymphonyWorkerAttemptLogEventContract(
                    kind: kind,
                    timestamp: timestamp,
                    issueID: issueID,
                    issueIdentifier: issueIdentifier,
                    attempt: attempt,
                    turnCount: turnCount,
                    workspacePath: workspacePath,
                    sessionID: liveSession?.sessionID,
                    threadID: liveSession?.threadID,
                    turnID: liveSession?.turnID,
                    terminalReason: terminalReason,
                    message: message
                )
            )
        }

        func recordRuntimeEvent(
            _ event: SymphonyCodexRuntimeEventContract,
            workspacePath: String?,
            turnCount: Int
        ) {
            let logKind: SymphonyWorkerAttemptLogEventContract.Kind? = switch event.kind {
            case .startupFailed:
                .startupFailure
            case .unsupportedToolCall:
                .unsupportedToolEvent
            case .turnInputRequired:
                .userInputRequired
            default:
                nil
            }

            guard let logKind else {
                return
            }

            logSink.emit(
                SymphonyWorkerAttemptLogEventContract(
                    kind: logKind,
                    timestamp: event.timestamp,
                    issueID: issueID,
                    issueIdentifier: issueIdentifier,
                    attempt: attempt,
                    turnCount: turnCount,
                    workspacePath: workspacePath,
                    sessionID: event.session?.sessionID,
                    threadID: event.session?.threadID,
                    turnID: event.session?.turnID,
                    message: event.message
                )
            )
        }

        func recordTurnResult(
            _ result: SymphonyCodexTurnExecutionResultContract,
            turnCount: Int
        ) {
            let usage = result.usage
            let event = result.lastEvent
            let session = result.session

            lock.lock()
            liveSession = SymphonyLiveSessionContract(
                sessionID: session.sessionID,
                threadID: session.threadID,
                turnID: session.turnID,
                codexAppServerPID: result.codexAppServerPID,
                lastCodexEvent: event?.kind.rawValue,
                lastCodexTimestamp: event?.timestamp,
                lastCodexMessage: event?.message,
                codexInputTokens: usage?.inputTokens ?? 0,
                codexOutputTokens: usage?.outputTokens ?? 0,
                codexTotalTokens: usage?.totalTokens ?? 0,
                lastReportedInputTokens: usage?.inputTokens ?? 0,
                lastReportedOutputTokens: usage?.outputTokens ?? 0,
                lastReportedTotalTokens: usage?.totalTokens ?? 0,
                turnCount: turnCount
            )
            lock.unlock()
        }

        func liveSessionSnapshot() -> SymphonyLiveSessionContract? {
            lock.lock()
            defer { lock.unlock() }
            return liveSession
        }
    }
}
