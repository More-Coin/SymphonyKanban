import Foundation
@testable import SymphonyKanban

enum SymphonyCodexRunnerGatewayTestSupport {
    static func makeGateway(using transport: CodexRunnerFakeTransport) -> SymphonyCodexRunnerGateway {
        SymphonyCodexRunnerGateway(
            connectionFactory: { _ in transport.connection() },
            dateProvider: { Date(timeIntervalSince1970: 1_711_111_111) }
        )
    }

    static func makeStartupContract(
        readTimeoutMs: Int = 5_000,
        turnTimeoutMs: Int = 3_600_000
    ) -> SymphonyCodexSessionStartupContract {
        let workspacePath = "/tmp/symphony_workspaces/ABC-123"

        return SymphonyCodexSessionStartupContract(
            initializeRequest: .init(
                clientInfo: .init(
                    name: "symphony",
                    title: "Symphony",
                    version: "1.0"
                ),
                capabilities: .init(
                    experimentalAPI: true,
                    optOutNotificationMethods: ["item/agentMessage/delta"]
                )
            ),
            threadStartRequest: .init(
                currentWorkingDirectoryPath: workspacePath,
                approvalPolicy: "never",
                sandbox: "workspaceWrite",
                serviceName: "symphony"
            ),
            initialTurnRequest: .init(
                inputText: "Resolve ABC-123.",
                currentWorkingDirectoryPath: workspacePath,
                title: "ABC-123: Fix build",
                approvalPolicy: "unlessTrusted",
                sandboxPolicy: makeDefaultTurnSandboxPolicy(workspacePath: workspacePath)
            ),
            approvalPosture: .trustedSingleTenantDefault,
            command: "codex app-server",
            readTimeoutMs: readTimeoutMs,
            turnTimeoutMs: turnTimeoutMs
        )
    }

    static func makeDefaultTurnSandboxPolicy(
        workspacePath: String
    ) -> SymphonyCodexTurnSandboxPolicyContract {
        SymphonyCodexTurnSandboxPolicyContract(
            type: "workspaceWrite",
            writableRoots: [workspacePath],
            networkAccess: false
        )
    }

    static func stdoutLine(_ line: String) -> SymphonyCodexTransportOutputEvent {
        .stdout(Data((line + "\n").utf8))
    }
}

final class CodexRunnerEventRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [SymphonyCodexRuntimeEventContract] = []

    func record(_ event: SymphonyCodexRuntimeEventContract) {
        lock.lock()
        stored.append(event)
        lock.unlock()
    }

    func values() -> [SymphonyCodexRuntimeEventContract] {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }
}

final class CodexRunnerFakeTransport: @unchecked Sendable {
    let pid: String?

    private let lock = NSLock()
    private var outputs: [SymphonyCodexTransportOutputEvent]
    private var writtenLines: [String] = []

    init(
        outputs: [SymphonyCodexTransportOutputEvent],
        pid: String? = "12345"
    ) {
        self.outputs = outputs
        self.pid = pid
    }

    func sendLine(_ line: String) throws {
        lock.lock()
        writtenLines.append(line)
        lock.unlock()
    }

    func nextOutput(timeoutMs _: Int) -> SymphonyCodexTransportOutputEvent? {
        lock.lock()
        defer { lock.unlock() }
        guard !outputs.isEmpty else {
            return nil
        }

        return outputs.removeFirst()
    }

    func terminate() {}

    func connection() -> SymphonyCodexRunnerGateway.Connection {
        SymphonyCodexRunnerGateway.Connection(
            pid: pid,
            sendLine: { [self] line in
                try sendLine(line)
            },
            nextOutput: { [self] timeoutMs in
                nextOutput(timeoutMs: timeoutMs)
            },
            terminate: { [self] in
                terminate()
            }
        )
    }

    func sentPayloads() throws -> [CodexRunnerSentPayload] {
        lock.lock()
        let lines = writtenLines
        lock.unlock()
        return try lines.map(CodexRunnerSentPayload.init)
    }
}

final class CodexRunnerCancellationAwareTransport: @unchecked Sendable {
    let pid: String?

    private let lock = NSLock()
    private let semaphore = DispatchSemaphore(value: 0)
    private var outputs: [SymphonyCodexTransportOutputEvent]
    private var waitingForOutput = false
    private var terminated = false
    private var writtenLines: [String] = []

    init(
        outputs: [SymphonyCodexTransportOutputEvent],
        pid: String? = "12345"
    ) {
        self.outputs = outputs
        self.pid = pid
        if !outputs.isEmpty {
            for _ in outputs {
                semaphore.signal()
            }
        }
    }

    func sendLine(_ line: String) throws {
        lock.lock()
        writtenLines.append(line)
        lock.unlock()
    }

    func nextOutput(timeoutMs: Int) -> SymphonyCodexTransportOutputEvent? {
        lock.lock()
        waitingForOutput = outputs.isEmpty && !terminated
        lock.unlock()

        let deadline = DispatchTime.now() + .milliseconds(timeoutMs)
        guard semaphore.wait(timeout: deadline) == .success else {
            lock.lock()
            waitingForOutput = false
            lock.unlock()
            return nil
        }

        lock.lock()
        waitingForOutput = false
        defer { lock.unlock() }
        guard !outputs.isEmpty else {
            return nil
        }

        return outputs.removeFirst()
    }

    func terminate() {
        lock.lock()
        guard !terminated else {
            lock.unlock()
            return
        }

        terminated = true
        outputs.append(.exited(15))
        lock.unlock()
        semaphore.signal()
    }

    func isWaitingForOutput() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return waitingForOutput
    }

    func connection() -> SymphonyCodexRunnerGateway.Connection {
        SymphonyCodexRunnerGateway.Connection(
            pid: pid,
            sendLine: { [self] line in
                try sendLine(line)
            },
            nextOutput: { [self] timeoutMs in
                nextOutput(timeoutMs: timeoutMs)
            },
            terminate: { [self] in
                terminate()
            }
        )
    }
}

struct CodexRunnerSentPayload {
    let method: String?
    let idString: String?
    let params: [String: Any]?
    let result: [String: Any]?
    let error: [String: Any]?

    init(_ line: String) throws {
        enum InvalidPayload: Error {
            case invalidUTF8
            case invalidObject
        }

        guard let data = line.data(using: .utf8) else {
            throw InvalidPayload.invalidUTF8
        }

        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw InvalidPayload.invalidObject
        }

        method = object["method"] as? String
        if let stringID = object["id"] as? String {
            idString = stringID
        } else if let intID = object["id"] as? Int {
            idString = String(intID)
        } else {
            idString = nil
        }
        params = object["params"] as? [String: Any]
        result = object["result"] as? [String: Any]
        error = object["error"] as? [String: Any]
    }
}
