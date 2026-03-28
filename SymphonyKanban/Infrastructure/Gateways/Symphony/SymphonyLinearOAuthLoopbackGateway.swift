import Foundation
import Network

actor SymphonyLinearOAuthLoopbackGateway: SymphonyTrackerAuthCallbackPortProtocol {
    private let listenerQueue = DispatchQueue(label: "com.jido.SymphonyKanban.linear-oauth-loopback")
    private static let requestParser = LinearOAuthLoopbackCallbackTransportParser()
    private static let responseBuilder = LinearOAuthLoopbackHTTPResponseBuilder()

    func awaitAuthorizationCallback() async throws -> SymphonyTrackerAuthCallbackContract {
        try await awaitLinearCallback()
    }

    func awaitLinearCallback(
        timeout: Duration = LinearOAuthLoopbackConfiguration.timeout
    ) async throws -> SymphonyTrackerAuthCallbackContract {
        let listener = try Self.makeListener()

        return try await withThrowingTaskGroup(of: SymphonyTrackerAuthCallbackContract.self) { group in
            group.addTask {
                try await self.receiveCallback(using: listener)
            }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw SymphonyTrackerAuthPresentationError.callbackTimedOut
            }

            defer {
                group.cancelAll()
                listener.cancel()
            }

            guard let result = try await group.next() else {
                throw SymphonyTrackerAuthPresentationError.callbackListenerFailed(
                    details: "The OAuth callback listener ended without producing a result."
                )
            }

            return result
        }
    }

    private func receiveCallback(
        using listener: NWListener
    ) async throws -> SymphonyTrackerAuthCallbackContract {
        try await withCheckedThrowingContinuation { continuation in
            let continuationGateway = SymphonyLinearOAuthLoopbackContinuationGateway(
                continuation: continuation
            )

            listener.stateUpdateHandler = { currentState in
                switch currentState {
                case .failed(let error):
                    continuationGateway.resume(
                        with: .failure(
                            SymphonyTrackerAuthPresentationError.callbackListenerFailed(
                                details: error.localizedDescription
                            )
                        )
                    )
                case .cancelled:
                    continuationGateway.resume(
                        with: .failure(
                            SymphonyTrackerAuthPresentationError.callbackListenerFailed(
                                details: "The OAuth callback listener was cancelled."
                            )
                        )
                    )
                default:
                    break
                }
            }

            listener.newConnectionHandler = { connection in
                Self.handleConnection(connection, continuationGateway: continuationGateway)
            }

            listener.start(queue: listenerQueue)
        }
    }

    private static func handleConnection(
        _ connection: NWConnection,
        continuationGateway: SymphonyLinearOAuthLoopbackContinuationGateway
    ) {
        connection.start(queue: continuationGateway.queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8_192) {
            data, _, _, error in
            let parsedCallback = requestParser.parseCallback(data: data, error: error)
            let response = responseBuilder.makeResponse(from: parsedCallback)
            sendHTTPResponse(
                on: connection,
                statusCode: response.statusCode,
                body: response.body
            )
            continuationGateway.resume(with: response.callbackResult)
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

    private static func makeListener() throws -> NWListener {
        guard let port = NWEndpoint.Port(rawValue: LinearOAuthLoopbackConfiguration.port) else {
            throw SymphonyTrackerAuthPresentationError.callbackListenerFailed(
                details: "The configured localhost callback port is invalid."
            )
        }

        do {
            return try NWListener(using: .tcp, on: port)
        } catch {
            throw SymphonyTrackerAuthPresentationError.callbackListenerFailed(
                details: error.localizedDescription
            )
        }
    }

    private final class SymphonyLinearOAuthLoopbackContinuationGateway: @unchecked Sendable {
        let queue = DispatchQueue(label: "com.jido.SymphonyKanban.linear-oauth-loopback.connection")

        private let lock = NSLock()
        private var continuation: CheckedContinuation<SymphonyTrackerAuthCallbackContract, Error>?

        init(
            continuation: CheckedContinuation<SymphonyTrackerAuthCallbackContract, Error>
        ) {
            self.continuation = continuation
        }

        func resume(
            with result: Result<SymphonyTrackerAuthCallbackContract, Error>
        ) {
            lock.lock()
            let continuation = self.continuation
            self.continuation = nil
            lock.unlock()

            guard let continuation else {
                return
            }

            continuation.resume(with: result)
        }
    }
}
