import Testing
@testable import SymphonyKanban

struct SymphonyCodexConnectionPresenterTests {
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
