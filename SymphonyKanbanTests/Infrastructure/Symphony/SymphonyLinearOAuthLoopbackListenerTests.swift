import Foundation
import Testing
@testable import SymphonyKanban

@Suite(.serialized)
struct SymphonyLinearOAuthLoopbackListenerTests {
    @Test
    func awaitLinearCallbackParsesAuthorizationCodeFromLoopbackRequest() async throws {
        let gateway = SymphonyLinearOAuthLoopbackGateway()

        async let callback = gateway.awaitLinearCallback(timeout: .seconds(10))

        let callbackURL = try #require(
            URL(
                string: "\(LinearOAuthLoopbackConfiguration.redirectURI)?code=received-code&state=expected-state"
            )
        )
        try await sendLoopbackCallback(to: callbackURL)

        let result = try await callback

        #expect(result.trackerKind == "linear")
        #expect(result.authorizationCode == "received-code")
        #expect(result.state == "expected-state")
        #expect(result.errorCode == nil)
    }

    @Test
    func awaitLinearCallbackTimesOutWhenNoBrowserRedirectArrives() async throws {
        let gateway = SymphonyLinearOAuthLoopbackGateway()

        await #expect(throws: SymphonyTrackerAuthPresentationError.self) {
            _ = try await gateway.awaitLinearCallback(timeout: .milliseconds(100))
        }
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
