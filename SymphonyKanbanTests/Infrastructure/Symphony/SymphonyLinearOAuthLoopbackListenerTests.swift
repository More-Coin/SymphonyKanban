import Foundation
import Testing
@testable import SymphonyKanban

@Suite(.serialized)
struct SymphonyLinearOAuthLoopbackListenerTests {
    @Test
    func preparedListenerAcceptsCallbackThatArrivesBeforeAwaitBegins() async throws {
        let (gateway, configuration) = try await makePreparedGateway()

        let callbackURL = try #require(
            URL(
                string: "\(configuration.redirectURI)?code=received-code&state=expected-state"
            )
        )
        try await sendLoopbackCallback(to: callbackURL)

        let result = try await gateway.awaitAuthorizationCallback()

        #expect(result.trackerKind == "linear")
        #expect(result.authorizationCode == "received-code")
        #expect(result.state == "expected-state")
        #expect(result.errorCode == nil)
    }

    @Test
    func awaitLinearCallbackTimesOutWhenNoBrowserRedirectArrives() async throws {
        let (gateway, _) = try await makePreparedGateway()

        await #expect(throws: SymphonyTrackerAuthInfrastructureError.self) {
            _ = try await gateway.awaitLinearCallback(timeout: .milliseconds(100))
        }
    }

    private func makePreparedGateway() async throws -> (
        gateway: SymphonyLinearOAuthLoopbackGateway,
        configuration: LinearOAuthLoopbackListenerConfiguration
    ) {
        for _ in 0..<20 {
            let configuration = LinearOAuthLoopbackListenerConfiguration(
                host: "127.0.0.1",
                port: UInt16.random(in: 20_000...60_000),
                path: LinearOAuthLoopbackConfiguration.path,
                timeoutInterval: 1,
                timeout: .seconds(1)
            )
            let gateway = SymphonyLinearOAuthLoopbackGateway(configuration: configuration)

            do {
                try await gateway.prepareAuthorizationCallbackListener()
                return (gateway, configuration)
            } catch let error as SymphonyTrackerAuthInfrastructureError {
                if case .callbackListenerFailed(let details) = error,
                   details.localizedCaseInsensitiveContains("address already in use") {
                    continue
                }

                throw error
            }
        }

        throw SymphonyTrackerAuthInfrastructureError.callbackListenerFailed(
            details: "Unable to reserve a loopback listener port for tests."
        )
    }

    private func sendLoopbackCallback(
        to callbackURL: URL,
        attempts: Int = 50
    ) async throws {
        var lastError: (any Error)?

        for attempt in 0..<attempts {
            do {
                _ = try await URLSession.shared.data(from: callbackURL)
                return
            } catch {
                lastError = error

                guard attempt < attempts - 1 else {
                    throw error
                }

                try await Task.sleep(for: .milliseconds(100))
            }
        }

        throw lastError ?? URLError(.cannotConnectToHost)
    }
}
