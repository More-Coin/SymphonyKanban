import Foundation

public protocol SymphonyWorkerAttemptTelemetryPortProtocol: Sendable {
    func makeRecorder(
        issueID: String,
        issueIdentifier: String,
        attempt: Int?
    ) -> any SymphonyWorkerAttemptTelemetryRecorderPortProtocol
}

public protocol SymphonyWorkerAttemptTelemetryRecorderPortProtocol: Sendable {
    func emit(
        kind: SymphonyWorkerAttemptLogEventContract.Kind,
        timestamp: Date,
        turnCount: Int,
        workspacePath: String?,
        terminalReason: SymphonyWorkerAttemptTerminalReasonContract?,
        message: String?
    )

    func recordRuntimeEvent(
        _ event: SymphonyCodexRuntimeEventContract,
        workspacePath: String?,
        turnCount: Int
    )

    func recordTurnResult(
        _ result: SymphonyCodexTurnExecutionResultContract,
        turnCount: Int
    )

    func liveSessionSnapshot() -> SymphonyLiveSessionContract?
}
