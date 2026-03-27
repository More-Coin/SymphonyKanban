import Foundation
import Testing
@testable import SymphonyKanban

struct SymphonyAuthPresenterTests {
    @Test
    func presenterMapsConnectedStatusToDisconnectUI() {
        let presenter = SymphonyAuthPresenter()

        let viewModel = presenter.present(
            SymphonyTrackerAuthStatusContract(
                trackerKind: "linear",
                state: .connected,
                statusMessage: "Connected to Linear.",
                connectedAt: Date(timeIntervalSince1970: 100)
            )
        )

        let linearService = try! #require(viewModel.linearService)
        #expect(viewModel.title == "Linear Connection")
        #expect(linearService.statusLabel == "Connected")
        #expect(linearService.actionLabel == "Disconnect")
        #expect(linearService.isConnected == true)
        #expect(linearService.connectedAtLabel != nil)
    }

    @Test
    func presenterMapsStaleSessionToReconnectUI() {
        let presenter = SymphonyAuthPresenter()

        let viewModel = presenter.present(
            SymphonyTrackerAuthStatusContract(
                trackerKind: "linear",
                state: .staleSession,
                statusMessage: "Stored session expired.",
                expiresAt: Date(timeIntervalSince1970: 200)
            ),
            errorMessage: "Reconnect required."
        )

        let linearService = try! #require(viewModel.linearService)
        #expect(viewModel.bannerMessage == "Reconnect required.")
        #expect(linearService.statusLabel == "Reconnect Required")
        #expect(linearService.actionLabel == "Reconnect")
        #expect(linearService.requiresAttention == true)
        #expect(linearService.expiresAtLabel != nil)
    }
}
