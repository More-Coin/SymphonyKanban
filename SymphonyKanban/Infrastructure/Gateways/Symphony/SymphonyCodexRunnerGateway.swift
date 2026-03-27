import Foundation

public final class SymphonyCodexRunnerGateway: SymphonyCodexRunnerPortProtocol, @unchecked Sendable {
    final class Connection: @unchecked Sendable {
        let pid: String?

        private let sendLineHandler: @Sendable (String) throws -> Void
        private let nextOutputHandler: @Sendable (Int) -> SymphonyCodexTransportOutputEvent?
        private let terminateHandler: @Sendable () -> Void

        init(
            pid: String?,
            sendLine: @escaping @Sendable (String) throws -> Void,
            nextOutput: @escaping @Sendable (Int) -> SymphonyCodexTransportOutputEvent?,
            terminate: @escaping @Sendable () -> Void
        ) {
            self.pid = pid
            self.sendLineHandler = sendLine
            self.nextOutputHandler = nextOutput
            self.terminateHandler = terminate
        }

        func sendLine(_ line: String) throws {
            try sendLineHandler(line)
        }

        func nextOutput(timeoutMs: Int) -> SymphonyCodexTransportOutputEvent? {
            nextOutputHandler(timeoutMs)
        }

        func terminate() {
            terminateHandler()
        }
    }

    private final class TransportQueue: @unchecked Sendable {
        private let lock = NSLock()
        private let semaphore = DispatchSemaphore(value: 0)
        private var events: [SymphonyCodexTransportOutputEvent] = []

        func push(_ event: SymphonyCodexTransportOutputEvent) {
            lock.lock()
            events.append(event)
            lock.unlock()
            semaphore.signal()
        }

        func next(timeoutMs: Int) -> SymphonyCodexTransportOutputEvent? {
            let deadline = DispatchTime.now() + .milliseconds(timeoutMs)
            guard semaphore.wait(timeout: deadline) == .success else {
                return nil
            }

            lock.lock()
            defer { lock.unlock() }
            guard !events.isEmpty else {
                return nil
            }

            return events.removeFirst()
        }
    }

    typealias ConnectionFactory = @Sendable (SymphonyCodexLaunchConfigurationModel) throws -> Connection
    typealias DateProvider = @Sendable () -> Date

    private struct ActiveSessionState {
        let connection: Connection
        let threadID: String
        let readTimeoutMs: Int
        let turnTimeoutMs: Int
        var cancellationRequested: Bool
    }

    private let connectionFactory: ConnectionFactory
    private let dateProvider: DateProvider
    private let jsonEncoder: JSONEncoder
    private let protocolRequestBuilder = SymphonyCodexProtocolDTOTranslators.Requests()
    private let protocolResponseBuilder = SymphonyCodexProtocolDTOTranslators.Responses()
    private let protocolMessageParser = SymphonyCodexProtocolDTOTranslators.Messages()
    private let compatibilityClassifier = SymphonyCodexCompatibilityClassifier()
    private let serverDirectiveResponseModel = SymphonyCodexServerDirectiveResponseModel()
    private let telemetryExtractor = SymphonyCodexTelemetryExtractorModel()
    private let stateLock = NSLock()
    private var activeSession: ActiveSessionState?
    private var nextRequestID = 1

    public init(
        dateProvider: @escaping @Sendable () -> Date = Date.init,
        jsonEncoder: JSONEncoder = JSONEncoder()
    ) {
        self.connectionFactory = { configuration in
            let process = Process()
            let standardInputPipe = Pipe()
            let standardOutputPipe = Pipe()
            let standardErrorPipe = Pipe()
            let outputQueue = TransportQueue()

            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-lc", configuration.command]
            process.currentDirectoryURL = URL(
                fileURLWithPath: configuration.currentWorkingDirectoryPath,
                isDirectory: true
            )
            process.standardInput = standardInputPipe
            process.standardOutput = standardOutputPipe
            process.standardError = standardErrorPipe

            standardOutputPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else {
                    handle.readabilityHandler = nil
                    return
                }

                outputQueue.push(.stdout(data))
            }

            standardErrorPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else {
                    handle.readabilityHandler = nil
                    return
                }

                outputQueue.push(.stderr(data))
            }

            process.terminationHandler = { terminatedProcess in
                outputQueue.push(.exited(terminatedProcess.terminationStatus))
            }

            do {
                try process.run()
            } catch {
                throw SymphonyCodexRunnerInfrastructureError.responseError(
                    details: error.localizedDescription
                )
            }

            return Connection(
                pid: process.processIdentifier == 0 ? nil : String(process.processIdentifier),
                sendLine: { line in
                    guard let data = "\(line)\n".data(using: .utf8) else {
                        throw SymphonyCodexRunnerInfrastructureError.responseError(
                            details: "A protocol request could not be encoded as UTF-8."
                        )
                    }

                    try standardInputPipe.fileHandleForWriting.write(contentsOf: data)
                },
                nextOutput: { timeoutMs in
                    outputQueue.next(timeoutMs: timeoutMs)
                },
                terminate: {
                    if process.isRunning {
                        process.terminate()
                    }
                }
            )
        }
        self.dateProvider = dateProvider
        self.jsonEncoder = jsonEncoder
    }

    init(
        connectionFactory: @escaping ConnectionFactory,
        dateProvider: @escaping DateProvider = Date.init,
        jsonEncoder: JSONEncoder = JSONEncoder()
    ) {
        self.connectionFactory = connectionFactory
        self.dateProvider = dateProvider
        self.jsonEncoder = jsonEncoder
    }

    public func startSession(
        using startup: SymphonyCodexSessionStartupContract,
        onEvent: @escaping @Sendable (SymphonyCodexRuntimeEventContract) -> Void
    ) async throws -> SymphonyCodexTurnExecutionResultContract {
        clearActiveSession()
        do {
            let launchPath = try validatedLaunchPath(
                threadPath: startup.threadStartRequest.currentWorkingDirectoryPath,
                turnPath: startup.initialTurnRequest.currentWorkingDirectoryPath
            )
            let connection = try launchConnection(
                command: startup.command,
                launchPath: launchPath,
                onEvent: onEvent
            )

            let initialTurnID = try performStartupHandshake(
                using: startup,
                launchPath: launchPath,
                connection: connection,
                onEvent: onEvent
            )

            let threadID = try requireActiveThreadID()
            let session = SymphonyCodexSessionIdentityContract(
                threadID: threadID,
                turnID: initialTurnID
            )
            emitEvent(
                onEvent,
                kind: .sessionStarted,
                session: session,
                pid: connection.pid
            )

            let result = try processTurnStream(
                connection: connection,
                session: session,
                turnTimeoutMs: startup.turnTimeoutMs,
                onEvent: onEvent
            )

            if result.outcome == .completed {
                setActiveSession(
                    ActiveSessionState(
                        connection: connection,
                        threadID: threadID,
                        readTimeoutMs: startup.readTimeoutMs,
                        turnTimeoutMs: startup.turnTimeoutMs,
                        cancellationRequested: false
                    )
                )
            } else {
                clearActiveSession()
            }

            return result
        } catch {
            clearActiveSession()
            throw boundaryError(from: error)
        }
    }

    public func continueTurn(
        using request: SymphonyCodexTurnStartContract,
        onEvent: @escaping @Sendable (SymphonyCodexRuntimeEventContract) -> Void
    ) async throws -> SymphonyCodexTurnExecutionResultContract {
        do {
            guard let activeSession = currentActiveSession() else {
                throw SymphonyCodexRunnerInfrastructureError.responseError(
                    details: "A live Codex runner session is required before continuing a turn."
                )
            }

            _ = try validatedLaunchPath(
                threadPath: request.currentWorkingDirectoryPath,
                turnPath: request.currentWorkingDirectoryPath
            )

            guard activeSession.threadID == request.threadID else {
                throw SymphonyCodexRunnerInfrastructureError.responseError(
                    details: "The continuation turn thread ID did not match the active Codex thread."
                )
            }

            let turnID = try sendTurnStart(
                using: request,
                connection: activeSession.connection,
                stage: "turn/start (continuation)",
                readTimeoutMs: activeSession.readTimeoutMs,
                onEvent: onEvent
            )
            let session = SymphonyCodexSessionIdentityContract(
                threadID: request.threadID,
                turnID: turnID
            )
            emitEvent(
                onEvent,
                kind: .sessionStarted,
                session: session,
                pid: activeSession.connection.pid
            )

            let result = try processTurnStream(
                connection: activeSession.connection,
                session: session,
                turnTimeoutMs: activeSession.turnTimeoutMs,
                onEvent: onEvent
            )

            if result.outcome != .completed {
                clearActiveSession()
            }

            return result
        } catch {
            clearActiveSession()
            throw boundaryError(from: error)
        }
    }

    public func cancelActiveTurn() -> SymphonyActiveTurnCancellationResultContract {
        stateLock.lock()
        guard var activeSession else {
            stateLock.unlock()
            return SymphonyActiveTurnCancellationResultContract(disposition: .noActiveTurn)
        }

        guard !activeSession.cancellationRequested else {
            stateLock.unlock()
            return SymphonyActiveTurnCancellationResultContract(disposition: .alreadyRequested)
        }

        activeSession.cancellationRequested = true
        let connection = activeSession.connection
        self.activeSession = activeSession
        stateLock.unlock()

        connection.terminate()
        return SymphonyActiveTurnCancellationResultContract(disposition: .requestAccepted)
    }

    private func launchConnection(
        command: String,
        launchPath: String,
        onEvent: @escaping @Sendable (SymphonyCodexRuntimeEventContract) -> Void
    ) throws -> Connection {
        let configuration = SymphonyCodexLaunchConfigurationModel(
            command: command,
            currentWorkingDirectoryPath: launchPath
        )

        do {
            return try connectionFactory(configuration)
        } catch let error as SymphonyCodexRunnerInfrastructureError {
            emitStartupFailure(onEvent, error: error)
            throw error
        } catch {
            let infrastructureError = SymphonyCodexRunnerInfrastructureError.responseError(
                details: error.localizedDescription
            )
            emitStartupFailure(onEvent, error: infrastructureError)
            throw infrastructureError
        }
    }

    private func performStartupHandshake(
        using startup: SymphonyCodexSessionStartupContract,
        launchPath: String,
        connection: Connection,
        onEvent: @escaping @Sendable (SymphonyCodexRuntimeEventContract) -> Void
    ) throws -> String {
        let startupRequestID = nextID()
        try sendRequest(
            protocolRequestBuilder.initializeCall(
                id: startupRequestID,
                from: startup.initializeRequest
            ),
            over: connection
        )
        _ = try waitForResponse(
            id: startupRequestID,
            stage: "initialize",
            readTimeoutMs: startup.readTimeoutMs,
            connection: connection,
            onEvent: onEvent
        )

        try sendNotification(
            protocolRequestBuilder.initializedCall(),
            over: connection
        )

        let requirementsRequestID = nextID()
        try sendRequest(
            protocolRequestBuilder.requirementsProbe(id: requirementsRequestID),
            over: connection
        )
        let requirementsResponse = try waitForResponse(
            id: requirementsRequestID,
            stage: "configRequirements/read",
            readTimeoutMs: startup.readTimeoutMs,
            connection: connection,
            onEvent: onEvent
        )
        try enforceCompatibility(
            startup: startup,
            response: requirementsResponse,
            onEvent: onEvent
        )

        let threadRequestID = nextID()
        try sendRequest(
            protocolRequestBuilder.threadStartCall(
                id: threadRequestID,
                launchPath: launchPath,
                request: startup.threadStartRequest
            ),
            over: connection
        )
        let threadResponse = try waitForResponse(
            id: threadRequestID,
            stage: "thread/start",
            readTimeoutMs: startup.readTimeoutMs,
            connection: connection,
            onEvent: onEvent
        )
        let threadID = try extractThreadID(from: threadResponse)
        setActiveSession(
            ActiveSessionState(
                connection: connection,
                threadID: threadID,
                readTimeoutMs: startup.readTimeoutMs,
                turnTimeoutMs: startup.turnTimeoutMs,
                cancellationRequested: false
            )
        )

        return try sendTurnStart(
            using: SymphonyCodexTurnStartContract(
                threadID: threadID,
                inputText: startup.initialTurnRequest.inputText,
                currentWorkingDirectoryPath: launchPath,
                title: startup.initialTurnRequest.title,
                approvalPolicy: startup.initialTurnRequest.approvalPolicy,
                sandboxPolicy: startup.initialTurnRequest.sandboxPolicy
            ),
            connection: connection,
            stage: "turn/start",
            readTimeoutMs: startup.readTimeoutMs,
            onEvent: onEvent
        )
    }

    private func sendTurnStart(
        using request: SymphonyCodexTurnStartContract,
        connection: Connection,
        stage: String,
        readTimeoutMs: Int,
        onEvent: @escaping @Sendable (SymphonyCodexRuntimeEventContract) -> Void
    ) throws -> String {
        let turnRequestID = nextID()
        try sendRequest(
            protocolRequestBuilder.turnStartCall(
                id: turnRequestID,
                request: request
            ),
            over: connection
        )

        let turnResponse = try waitForResponse(
            id: turnRequestID,
            stage: stage,
            readTimeoutMs: readTimeoutMs,
            connection: connection,
            onEvent: onEvent
        )
        return try extractTurnID(from: turnResponse)
    }

    private func processTurnStream(
        connection: Connection,
        session: SymphonyCodexSessionIdentityContract,
        turnTimeoutMs: Int,
        onEvent: @escaping @Sendable (SymphonyCodexRuntimeEventContract) -> Void
    ) throws -> SymphonyCodexTurnExecutionResultContract {
        let deadline = Date().addingTimeInterval(TimeInterval(turnTimeoutMs) / 1000)
        var stdoutBuffer = SymphonyCodexLineBufferModel()
        var latestUsage: SymphonyCodexUsageSnapshotContract?
        var latestRateLimits: SymphonyCodexRateLimitSnapshotContract?
        while true {
            let remainingMs = max(1, Int(deadline.timeIntervalSinceNow * 1000))

            guard let output = connection.nextOutput(timeoutMs: remainingMs) else {
                let event = makeEvent(
                    kind: .turnEndedWithError,
                    session: session,
                    pid: connection.pid,
                    message: "Timed out waiting for turn completion."
                )
                onEvent(event)
                throw SymphonyAgentRuntimeApplicationError.turnTimeout(
                    timeoutMs: turnTimeoutMs
                )
            }

            switch output {
            case .stderr(let data):
                let stderrLine = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .newlines)
                if let stderrLine, !stderrLine.isEmpty {
                    let event = makeEvent(
                        kind: .otherMessage,
                        session: session,
                        pid: connection.pid,
                        message: stderrLine
                    )
                    onEvent(event)
                }
            case .exited(let exitCode):
                let cancellationRequested = isCancellationRequested(for: session.threadID)
                let event = makeEvent(
                    kind: cancellationRequested ? .turnCancelled : .turnEndedWithError,
                    session: session,
                    pid: connection.pid,
                    message: cancellationRequested
                        ? "The turn was cancelled."
                        : "Codex app-server exited with status \(exitCode)."
                )
                onEvent(event)
                if cancellationRequested {
                    throw SymphonyAgentRuntimeApplicationError.turnCancelled(
                        details: event.message
                    )
                }
                throw SymphonyAgentRuntimeApplicationError.processExit(
                    exitCode: exitCode,
                    details: event.message
                )
            case .stdout(let data):
                let lines = try stdoutBuffer.append(data)

                for line in lines where !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    do {
                        let message = try protocolMessageParser.parseLine(line)
                        let telemetry = telemetryExtractor.toContract(from: message.params ?? message.result)
                        if let usage = telemetry.usage {
                            latestUsage = usage
                        }
                        if let rateLimits = telemetry.rateLimits {
                            latestRateLimits = rateLimits
                        }

                        switch try handleParsedServerDirective(
                            message,
                            connection: connection
                        ) {
                        case .approval(let requestKind, let decision):
                            emitEvent(
                                onEvent,
                                kind: .approvalAutoApproved,
                                session: session,
                                pid: connection.pid,
                                requestKind: requestKind,
                                message: "Auto-approved \(requestKind.rawValue) with \(decision)."
                            )
                            emitEvent(
                                onEvent,
                                kind: .notification,
                                session: session,
                                pid: connection.pid,
                                message: message.method
                            )
                            continue
                        case .unsupportedToolCall:
                            emitEvent(
                                onEvent,
                                kind: .unsupportedToolCall,
                                session: session,
                                pid: connection.pid,
                                requestKind: .dynamicToolCall,
                                message: "Rejected unsupported dynamic tool call."
                            )
                            emitEvent(
                                onEvent,
                                kind: .notification,
                                session: session,
                                pid: connection.pid,
                                message: message.method
                            )
                            continue
                        case .userInputRequested:
                            let event = makeEvent(
                                kind: .turnInputRequired,
                                session: session,
                                pid: connection.pid,
                                requestKind: .toolRequestUserInput,
                                message: "The Codex app-server requested user input."
                            )
                            onEvent(event)
                            throw SymphonyAgentRuntimeApplicationError.inputRequired(
                                details: event.message
                            )
                        case .unhandled:
                            break
                        }

                        guard let method = message.method else {
                            continue
                        }

                        switch method {
                        case "turn/completed":
                            let status = string(
                                forPath: ["status"],
                                in: message.params
                            ) ?? string(
                                forPath: ["turn", "status"],
                                in: message.params
                            ) ?? string(
                                forPath: ["status"],
                                in: message.result
                            ) ?? string(
                                forPath: ["turn", "status"],
                                in: message.result
                            )

                            let eventKind: SymphonyCodexRuntimeEventContract.Kind = {
                                switch status {
                                case "completed":
                                    return .turnCompleted
                                case "failed":
                                    return .turnFailed
                                case "interrupted" where isCancellationRequested(for: session.threadID):
                                    return .turnCancelled
                                default:
                                    return .turnEndedWithError
                                }
                            }()
                            let event = makeEvent(
                                kind: eventKind,
                                session: session,
                                pid: connection.pid,
                                message: status
                            )
                            onEvent(event)

                            switch status {
                            case "completed":
                                return SymphonyCodexTurnExecutionResultContract(
                                    session: session,
                                    outcome: .completed,
                                    completedAt: dateProvider(),
                                    codexAppServerPID: connection.pid,
                                    lastEvent: event,
                                    usage: latestUsage,
                                    rateLimits: latestRateLimits
                                )
                            case "failed":
                                throw SymphonyAgentRuntimeApplicationError.turnFailed(
                                    details: event.message
                                )
                            case "interrupted" where isCancellationRequested(for: session.threadID):
                                throw SymphonyAgentRuntimeApplicationError.turnCancelled(
                                    details: event.message
                                )
                            case "interrupted":
                                throw SymphonyAgentRuntimeApplicationError.protocolViolation(
                                    details: "The agent runtime interrupted the turn without a cancellation request."
                                )
                            default:
                                throw SymphonyAgentRuntimeApplicationError.protocolViolation(
                                    details: "The agent runtime returned an unexpected turn status."
                                )
                            }
                        case "turn/failed":
                            let event = makeEvent(
                                kind: .turnFailed,
                                session: session,
                                pid: connection.pid,
                                message: "The turn failed."
                            )
                            onEvent(event)
                            throw SymphonyAgentRuntimeApplicationError.turnFailed(
                                details: event.message
                            )
                        case "turn/cancelled":
                            let event = makeEvent(
                                kind: .turnCancelled,
                                session: session,
                                pid: connection.pid,
                                message: "The turn was cancelled."
                            )
                            onEvent(event)
                            throw SymphonyAgentRuntimeApplicationError.turnCancelled(
                                details: event.message
                            )
                        case "thread/tokenUsage/updated":
                            let event = makeEvent(
                                kind: .notification,
                                session: session,
                                pid: connection.pid,
                                message: method
                            )
                            onEvent(event)
                            continue
                        default:
                            let event = makeEvent(
                                kind: .notification,
                                session: session,
                                pid: connection.pid,
                                message: method
                            )
                            onEvent(event)
                            continue
                        }
                    } catch let error as SymphonyCodexRunnerInfrastructureError {
                        let event = makeEvent(
                            kind: .malformed,
                            session: session,
                            pid: connection.pid,
                            message: error.message
                        )
                        onEvent(event)
                        throw error.applicationError
                    }
                }
            }
        }
    }

    private func enforceCompatibility(
        startup: SymphonyCodexSessionStartupContract,
        response: SymphonyCodexProtocolMessageDTO,
        onEvent: @escaping @Sendable (SymphonyCodexRuntimeEventContract) -> Void
    ) throws {
        guard let requirements = SymphonyCodexCompatibilityRequirementsModel.fromContract(response.result) else {
            return
        }

        if let failure = compatibilityClassifier.classify(
            startup: startup,
            requirements: requirements
        ) {
            let error = SymphonyCodexRunnerInfrastructureError.policyIncompatible(
                details: failure.details
            )
            emitStartupFailure(onEvent, error: error)
            throw error
        }
    }

    private func waitForResponse(
        id: Int,
        stage: String,
        readTimeoutMs: Int,
        connection: Connection,
        onEvent: @escaping @Sendable (SymphonyCodexRuntimeEventContract) -> Void
    ) throws -> SymphonyCodexProtocolMessageDTO {
        var stdoutBuffer = SymphonyCodexLineBufferModel()

        while true {
            guard let output = connection.nextOutput(timeoutMs: readTimeoutMs) else {
                let error = SymphonyCodexRunnerInfrastructureError.responseTimeout(
                    stage: stage,
                    timeoutMs: readTimeoutMs
                )
                emitStartupFailure(onEvent, error: error)
                throw error
            }

            switch output {
            case .stderr(let data):
                let message = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .newlines)
                if let message, !message.isEmpty {
                    onEvent(
                        makeEvent(
                            kind: .otherMessage,
                            pid: connection.pid,
                            message: message
                        )
                    )
                }
            case .exited(let exitCode):
                let message = "Codex app-server exited with status \(exitCode) during \(stage)."
                let error: SymphonyCodexRunnerInfrastructureError
                if exitCode == 127 {
                    error = .codexNotFound(command: "bash -lc <codex.command>", details: message)
                } else {
                    error = .portExit(exitCode: exitCode, details: message)
                }
                emitStartupFailure(onEvent, error: error)
                throw error
            case .stdout(let data):
                let lines = try stdoutBuffer.append(data)
                for line in lines where !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let message = try protocolMessageParser.parseLine(line)

                    if let responseID = message.id,
                       responseID == protocolResponseBuilder.identifier(integer: id),
                       message.method == nil {
                        if message.error != nil {
                            let error = SymphonyCodexRunnerInfrastructureError.responseError(
                                details: "The server returned an error during \(stage)."
                            )
                            emitStartupFailure(onEvent, error: error)
                            throw error
                        }

                        return message
                    }

                    switch try handleParsedServerDirective(
                        message,
                        connection: connection
                    ) {
                    case .approval(let requestKind, let decision):
                        emitEvent(
                            onEvent,
                            kind: .approvalAutoApproved,
                            pid: connection.pid,
                            requestKind: requestKind,
                            message: "Auto-approved \(requestKind.rawValue) with \(decision)."
                        )
                    case .unsupportedToolCall:
                        emitEvent(
                            onEvent,
                            kind: .unsupportedToolCall,
                            pid: connection.pid,
                            requestKind: .dynamicToolCall,
                            message: "Rejected unsupported dynamic tool call during \(stage)."
                        )
                    case .userInputRequested:
                        let error = SymphonyCodexRunnerInfrastructureError.responseError(
                            details: "The server requested user input during \(stage)."
                        )
                        emitStartupFailure(onEvent, error: error)
                        throw error
                    case .unhandled:
                        break
                    }

                    if let method = message.method {
                        onEvent(
                            makeEvent(
                                kind: .notification,
                                pid: connection.pid,
                                message: method
                            )
                        )
                    }
                }
            }
        }
    }

    private func validatedLaunchPath(
        threadPath: String,
        turnPath: String
    ) throws -> String {
        let absoluteThreadPath = absolutePath(from: threadPath)
        let absoluteTurnPath = absolutePath(from: turnPath)

        guard !absoluteThreadPath.isEmpty,
              absoluteThreadPath == absoluteTurnPath,
              absoluteThreadPath.hasPrefix("/") else {
            throw SymphonyCodexRunnerInfrastructureError.invalidWorkspaceCWD(
                details: "Expected a single absolute validated workspace path for thread and turn startup."
            )
        }

        return absoluteThreadPath
    }

    private func absolutePath(from path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.path
    }

    private func extractThreadID(from message: SymphonyCodexProtocolMessageDTO) throws -> String {
        guard let threadID = string(forPath: ["thread", "id"], in: message.result) else {
            throw SymphonyCodexRunnerInfrastructureError.responseError(
                details: "The thread/start response did not contain result.thread.id."
            )
        }

        return threadID
    }

    private func extractTurnID(from message: SymphonyCodexProtocolMessageDTO) throws -> String {
        guard let turnID = string(forPath: ["turn", "id"], in: message.result) else {
            throw SymphonyCodexRunnerInfrastructureError.responseError(
                details: "The turn/start response did not contain result.turn.id."
            )
        }

        return turnID
    }

    private func string(
        forPath path: [String],
        in value: SymphonyConfigValueContract?
    ) -> String? {
        var current = value

        for component in path {
            current = current?.dictionaryValue?[component]
        }

        return current?.stringValue
    }

    private func handleParsedServerDirective(
        _ message: SymphonyCodexProtocolMessageDTO,
        connection: Connection
    ) throws -> SymphonyCodexServerDirectiveResponseModel.Action {
        guard let messageID = message.id else {
            return .unhandled
        }

        let action = serverDirectiveResponseModel.fromMessage(message)
        guard let payload = try protocolResponseBuilder.encodedServerDirectivePayload(
            id: messageID,
            action: action,
            using: jsonEncoder
        ) else {
            return .unhandled
        }

        try connection.sendLine(payload)
        return action
    }

    private func sendRequest<Params: Encodable & Sendable>(
        _ request: SymphonyCodexJSONRPCRequestDTO<Params>,
        over connection: Connection
    ) throws {
        try connection.sendLine(
            try protocolRequestBuilder.encodedCall(
                request,
                using: jsonEncoder
            )
        )
    }

    private func sendNotification<Params: Encodable & Sendable>(
        _ notification: SymphonyCodexJSONRPCNotificationDTO<Params>,
        over connection: Connection
    ) throws {
        try connection.sendLine(
            try protocolRequestBuilder.encodedCall(
                notification,
                using: jsonEncoder
            )
        )
    }

    private func makeEvent(
        kind: SymphonyCodexRuntimeEventContract.Kind,
        session: SymphonyCodexSessionIdentityContract? = nil,
        pid: String? = nil,
        requestKind: SymphonyCodexServerRequestKindContract? = nil,
        message: String? = nil
    ) -> SymphonyCodexRuntimeEventContract {
        SymphonyCodexRuntimeEventContract(
            kind: kind,
            timestamp: dateProvider(),
            session: session,
            codexAppServerPID: pid,
            requestKind: requestKind,
            message: message
        )
    }

    private func emitEvent(
        _ onEvent: @escaping @Sendable (SymphonyCodexRuntimeEventContract) -> Void,
        kind: SymphonyCodexRuntimeEventContract.Kind,
        session: SymphonyCodexSessionIdentityContract? = nil,
        pid: String? = nil,
        requestKind: SymphonyCodexServerRequestKindContract? = nil,
        message: String? = nil
    ) {
        onEvent(
            makeEvent(
                kind: kind,
                session: session,
                pid: pid,
                requestKind: requestKind,
                message: message
            )
        )
    }

    private func emitStartupFailure(
        _ onEvent: @escaping @Sendable (SymphonyCodexRuntimeEventContract) -> Void,
        error: SymphonyCodexRunnerInfrastructureError
    ) {
        onEvent(
            makeEvent(
                kind: .startupFailed,
                message: error.code
            )
        )
    }

    private func boundaryError(from error: any Error) -> any Error {
        if let error = error as? SymphonyAgentRuntimeApplicationError {
            return error
        }

        if let error = error as? SymphonyCodexRunnerInfrastructureError {
            return error.applicationError
        }

        return SymphonyAgentRuntimeApplicationError.protocolViolation(
            details: error.localizedDescription
        )
    }

    private func nextID() -> Int {
        stateLock.lock()
        defer { stateLock.unlock() }
        let id = nextRequestID
        nextRequestID += 1
        return id
    }

    private func setActiveSession(_ session: ActiveSessionState) {
        stateLock.lock()
        defer { stateLock.unlock() }
        activeSession = session
    }

    private func currentActiveSession() -> ActiveSessionState? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return activeSession
    }

    private func clearActiveSession() {
        stateLock.lock()
        let existing = activeSession
        activeSession = nil
        stateLock.unlock()
        existing?.connection.terminate()
    }

    private func isCancellationRequested(for threadID: String) -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return activeSession?.threadID == threadID && activeSession?.cancellationRequested == true
    }

    private func requireActiveThreadID() throws -> String {
        guard let threadID = currentActiveSession()?.threadID else {
            throw SymphonyCodexRunnerInfrastructureError.responseError(
                details: "The thread/start response did not establish an active thread ID."
            )
        }

        return threadID
    }
}
