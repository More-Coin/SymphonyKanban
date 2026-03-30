import Foundation
import Network

actor SymphonyLinearOAuthLoopbackGateway: SymphonyTrackerAuthCallbackPortProtocol {
    private let listenerQueue = DispatchQueue(label: "com.jido.SymphonyKanban.linear-oauth-loopback")
    private static let requestParser = LinearOAuthLoopbackCallbackTransportParser()
    private static let responseBuilder = LinearOAuthLoopbackHTTPResponseBuilder()
    private let configuration: LinearOAuthLoopbackListenerConfiguration
    private var preparedSession: PreparedCallbackSession?

    init(
        configuration: LinearOAuthLoopbackListenerConfiguration = LinearOAuthLoopbackConfiguration.defaultListenerConfiguration
    ) {
        self.configuration = configuration
    }

    func prepareAuthorizationCallbackListener() async throws {
        cancelPreparedSession()

        let listener = try Self.makeListener(using: configuration)
        let callbackStreamGateway = Self.makeCallbackStreamGateway()
        let continuationGateway = SymphonyLinearOAuthLoopbackContinuationGateway(
            callbackStreamGateway: callbackStreamGateway
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            continuationGateway.installReadyContinuation(continuation)

            listener.stateUpdateHandler = { currentState in
                switch currentState {
                case .ready:
                    continuationGateway.resumeReady()
                case .failed(let error):
                    let failure = Self.listenerFailure(details: error.localizedDescription)
                    continuationGateway.failReady(with: failure)
                    continuationGateway.finishCallbacks(with: failure)
                case .cancelled:
                    let failure = Self.listenerFailure(
                        details: "The OAuth callback listener was cancelled."
                    )
                    continuationGateway.failReady(with: failure)
                    continuationGateway.finishCallbacks(with: failure)
                default:
                    break
                }
            }

            listener.newConnectionHandler = { connection in
                Self.handleConnection(
                    connection,
                    continuationGateway: continuationGateway,
                    configuration: self.configuration
                )
            }

            listener.start(queue: listenerQueue)
        }

        preparedSession = PreparedCallbackSession(
            listener: listener,
            callbackStream: callbackStreamGateway.stream
        )
    }

    func awaitAuthorizationCallback() async throws -> SymphonyTrackerAuthCallbackContract {
        if preparedSession == nil {
            try await prepareAuthorizationCallbackListener()
        }

        return try await awaitPreparedAuthorizationCallback()
    }

    func cancelAuthorizationCallbackListener() async {
        cancelPreparedSession()
    }

    func awaitLinearCallback(
        timeout: Duration? = nil
    ) async throws -> SymphonyTrackerAuthCallbackContract {
        try await prepareAuthorizationCallbackListener()
        return try await awaitPreparedAuthorizationCallback(timeout: timeout ?? configuration.timeout)
    }

    private func awaitPreparedAuthorizationCallback(
        timeout: Duration? = nil
    ) async throws -> SymphonyTrackerAuthCallbackContract {
        guard let preparedSession else {
            throw Self.listenerFailure(
                details: "The OAuth callback listener was not prepared."
            )
        }

        let effectiveTimeout = timeout ?? configuration.timeout

        return try await withThrowingTaskGroup(of: SymphonyTrackerAuthCallbackContract.self) { group in
            group.addTask {
                var iterator = preparedSession.callbackStream.makeAsyncIterator()
                guard let callback = try await iterator.next() else {
                    throw Self.listenerFailure(
                        details: "The OAuth callback listener ended without producing a result."
                    )
                }
                return callback
            }
            group.addTask {
                try await Task.sleep(for: effectiveTimeout)
                throw SymphonyTrackerAuthInfrastructureError.callbackTimedOut
            }

            defer {
                group.cancelAll()
                cancelPreparedSession()
            }

            guard let result = try await group.next() else {
                throw Self.listenerFailure(
                    details: "The OAuth callback listener ended without producing a result."
                )
            }

            return result
        }
    }

    private static func handleConnection(
        _ connection: NWConnection,
        continuationGateway: SymphonyLinearOAuthLoopbackContinuationGateway,
        configuration: LinearOAuthLoopbackListenerConfiguration
    ) {
        connection.start(queue: continuationGateway.queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8_192) {
            data, _, _, error in
            let parsedCallback = requestParser.parseCallback(
                data: data,
                error: error,
                using: configuration
            )
            let response = responseBuilder.makeResponse(from: parsedCallback)
            sendHTTPResponse(
                on: connection,
                statusCode: response.statusCode,
                body: response.body
            )
            switch response.callbackResult {
            case .success(let callback):
                continuationGateway.yield(callback)
                continuationGateway.finishCallbacks()
            case .failure(let error):
                continuationGateway.finishCallbacks(with: error)
            }
        }
    }

    private static func sendHTTPResponse(
        on connection: NWConnection,
        statusCode: Int,
        body: String
    ) {
        let statusText = statusCode == 200 ? "OK" : "Bad Request"
        let response = """
        HTTP/1.1 \(statusCode) \(statusText)\r
        Content-Type: text/html; charset=utf-8\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        \r
        \(body)
        """

        connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private static func makeListener(
        using configuration: LinearOAuthLoopbackListenerConfiguration
    ) throws -> NWListener {
        guard let port = NWEndpoint.Port(rawValue: configuration.port) else {
            throw listenerFailure(
                details: "The configured localhost callback port is invalid."
            )
        }

        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            return try NWListener(using: parameters, on: port)
        } catch {
            throw listenerFailure(
                details: error.localizedDescription
            )
        }
    }

    private func cancelPreparedSession() {
        preparedSession?.listener.cancel()
        preparedSession = nil
    }

    private static func makeCallbackStreamGateway() -> CallbackStreamGateway {
        var continuation: AsyncThrowingStream<SymphonyTrackerAuthCallbackContract, Error>.Continuation?
        let stream = AsyncThrowingStream<SymphonyTrackerAuthCallbackContract, Error> {
            continuation = $0
        }

        return CallbackStreamGateway(
            stream: stream,
            continuation: continuation
        )
    }

    private static func listenerFailure(
        details: String
    ) -> SymphonyTrackerAuthInfrastructureError {
        .callbackListenerFailed(details: details)
    }

    private struct PreparedCallbackSession {
        let listener: NWListener
        let callbackStream: AsyncThrowingStream<SymphonyTrackerAuthCallbackContract, Error>
    }

    private struct CallbackStreamGateway {
        let stream: AsyncThrowingStream<SymphonyTrackerAuthCallbackContract, Error>
        let continuation: AsyncThrowingStream<SymphonyTrackerAuthCallbackContract, Error>.Continuation?
    }

    private final class SymphonyLinearOAuthLoopbackContinuationGateway: @unchecked Sendable {
        let queue = DispatchQueue(label: "com.jido.SymphonyKanban.linear-oauth-loopback.connection")

        private let lock = NSLock()
        private let callbackStreamGateway: CallbackStreamGateway
        private var readyContinuation: CheckedContinuation<Void, Error>?

        init(
            callbackStreamGateway: CallbackStreamGateway
        ) {
            self.callbackStreamGateway = callbackStreamGateway
        }

        func installReadyContinuation(
            _ continuation: CheckedContinuation<Void, Error>
        ) {
            lock.lock()
            readyContinuation = continuation
            lock.unlock()
        }

        func resumeReady() {
            lock.lock()
            let continuation = readyContinuation
            readyContinuation = nil
            lock.unlock()

            guard let continuation else {
                return
            }

            continuation.resume()
        }

        func failReady(
            with error: any Error
        ) {
            lock.lock()
            let continuation = readyContinuation
            readyContinuation = nil
            lock.unlock()

            guard let continuation else {
                return
            }

            continuation.resume(throwing: error)
        }

        func yield(
            _ callback: SymphonyTrackerAuthCallbackContract
        ) {
            callbackStreamGateway.continuation?.yield(callback)
        }

        func finishCallbacks() {
            callbackStreamGateway.continuation?.finish()
        }

        func finishCallbacks(
            with error: any Error
        ) {
            callbackStreamGateway.continuation?.finish(throwing: error)
        }
    }
}
