public struct StopSymphonyOrchestratorRuntimeUseCase {
    private let schedulerPort: any SymphonyRuntimeSchedulerPortProtocol
    private let workerExecutionPort: any SymphonyWorkerExecutionPortProtocol
    private let workflowReloadMonitorPort: (any SymphonyWorkflowReloadMonitorPortProtocol)?

    public init(
        schedulerPort: any SymphonyRuntimeSchedulerPortProtocol,
        workerExecutionPort: any SymphonyWorkerExecutionPortProtocol,
        workflowReloadMonitorPort: (any SymphonyWorkflowReloadMonitorPortProtocol)? = nil
    ) {
        self.schedulerPort = schedulerPort
        self.workerExecutionPort = workerExecutionPort
        self.workflowReloadMonitorPort = workflowReloadMonitorPort
    }

    public func stopRuntime(
        using request: SymphonyRuntimeStopRequestContract
    ) -> SymphonyRuntimeStopResultContract {
        if let pollHandle = request.pollHandle {
            schedulerPort.cancel(handle: pollHandle)
        }

        if let workflowReloadHandle = request.workflowReloadHandle {
            workflowReloadMonitorPort?.cancel(handle: workflowReloadHandle)
        }

        for retryTimerHandle in request.retryTimerHandles {
            schedulerPort.cancel(handle: retryTimerHandle)
        }

        for workerHandle in request.workerHandles {
            workerExecutionPort.cancel(workerHandle: workerHandle)
        }

        return SymphonyRuntimeStopResultContract(
            cancelledPoll: request.pollHandle != nil,
            cancelledWorkflowReloadMonitor: request.workflowReloadHandle != nil,
            cancelledRetryCount: request.retryTimerHandles.count,
            cancelledWorkerCount: request.workerHandles.count
        )
    }
}
