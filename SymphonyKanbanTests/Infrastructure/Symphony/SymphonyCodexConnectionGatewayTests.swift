import Foundation
import Testing
@testable import SymphonyKanban

struct SymphonyCodexConnectionGatewayTests {
    @Test
    func queryStatusReturnsConnectedWhenResolvedExecutableIsLoggedInAndAppServerIsAvailable() {
        let gateway = SymphonyCodexConnectionGateway { executableURL, arguments in
            if executableURL.path == "/opt/homebrew/bin/codex",
               arguments == ["login", "status"] {
                return .init(
                    terminationStatus: 0,
                    standardOutput: "Logged in using ChatGPT\n",
                    standardError: ""
                )
            }

            if executableURL.path == "/opt/homebrew/bin/codex",
               arguments == ["app-server", "--help"] {
                return .init(
                    terminationStatus: 0,
                    standardOutput: "Usage: codex app-server [OPTIONS]\n",
                    standardError: ""
                )
            }

            Issue.record("Unexpected command: \(executableURL.path) \(arguments)")
            return .init(terminationStatus: 1, standardOutput: "", standardError: "unexpected")
        }

        let status = gateway.queryStatus(
            using: SymphonyCodexCommandResolutionContract(
                configuredCommand: "codex app-server",
                effectiveCommand: "/opt/homebrew/bin/codex app-server",
                executableName: "codex",
                executablePath: "/opt/homebrew/bin/codex",
                detailMessage: nil
            )
        )

        #expect(status.state == .connected)
        #expect(status.isReady)
        #expect(status.executablePath == "/opt/homebrew/bin/codex")
    }

    @Test
    func queryStatusReturnsNotAuthenticatedWhenLoginStatusDoesNotReportLoggedIn() {
        let gateway = SymphonyCodexConnectionGateway { executableURL, arguments in
            if executableURL.path == "/opt/homebrew/bin/codex",
               arguments == ["login", "status"] {
                return .init(
                    terminationStatus: 1,
                    standardOutput: "",
                    standardError: "Not logged in\n"
                )
            }

            Issue.record("Unexpected command: \(executableURL.path) \(arguments)")
            return .init(terminationStatus: 1, standardOutput: "", standardError: "unexpected")
        }

        let status = gateway.queryStatus(
            using: SymphonyCodexCommandResolutionContract(
                configuredCommand: "codex app-server",
                effectiveCommand: "/opt/homebrew/bin/codex app-server",
                executableName: "codex",
                executablePath: "/opt/homebrew/bin/codex",
                detailMessage: nil
            )
        )

        #expect(status.state == .notAuthenticated)
        #expect(status.isReady == false)
        #expect(status.detailMessage == "Not logged in")
    }

    @Test
    func queryStatusReturnsCLIUnavailableWhenExecutableWasNotResolved() {
        let gateway = SymphonyCodexConnectionGateway { executableURL, arguments in
            Issue.record("Unexpected command: \(executableURL.path) \(arguments)")
            return .init(terminationStatus: 1, standardOutput: "", standardError: "unexpected")
        }

        let status = gateway.queryStatus(
            using: SymphonyCodexCommandResolutionContract(
                configuredCommand: "codex app-server",
                effectiveCommand: "codex app-server",
                executableName: "codex",
                executablePath: nil,
                detailMessage: "The configured executable `codex` could not be resolved from the login shell PATH."
            )
        )

        #expect(status.state == .cliUnavailable)
        #expect(status.isReady == false)
        #expect(status.statusMessage.contains("login shell PATH"))
    }
}
