import Testing
@testable import SymphonyKanban

struct SymphonyCodexConnectionPresenterTests {
    @Test
    func presentBuildsConnectedViewModelWithReadableSummary() {
        let presenter = SymphonyCodexConnectionPresenter()

        let viewModel = presenter.present(
            SymphonyCodexConnectionStatusContract(
                state: .connected,
                command: "codex app-server",
                executableName: "codex",
                executablePath: "/opt/homebrew/bin/codex",
                statusMessage: "Codex is installed, authenticated, and ready for Symphony.",
                detailMessage: "Logged in using ChatGPT"
            )
        )

        #expect(viewModel.isConnected)
        #expect(viewModel.title == "Codex Ready")
        #expect(viewModel.message.contains("CLI path: /opt/homebrew/bin/codex"))
        #expect(viewModel.message.contains("Logged in using ChatGPT"))
    }

    @Test
    func presentBuildsLoginRequiredViewModelWhenSessionIsMissing() {
        let presenter = SymphonyCodexConnectionPresenter()

        let viewModel = presenter.present(
            SymphonyCodexConnectionStatusContract(
                state: .notAuthenticated,
                command: "codex app-server",
                executableName: "codex",
                executablePath: "/opt/homebrew/bin/codex",
                statusMessage: "Codex CLI is installed, but the local Codex session is not authenticated.",
                detailMessage: "Not logged in"
            )
        )

        #expect(viewModel.isConnected == false)
        #expect(viewModel.title == "Codex Login Required")
        #expect(viewModel.message.contains("Not logged in"))
    }
}
