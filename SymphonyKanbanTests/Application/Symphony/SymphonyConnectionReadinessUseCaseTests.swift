import Testing
@testable import SymphonyKanban

struct SymphonyConnectionReadinessUseCaseTests {
    @Test
    func validateRejectsDisconnectedSessionStatus() {
        let portSpy = TrackerAuthPortSpy(
            status: SymphonyTrackerAuthStatusContract(
                trackerKind: "linear",
                state: .disconnected,
                statusMessage: "No stored tracker session was found."
            )
        )
        let useCase = ValidateSymphonyTrackerConnectionReadinessUseCase(
            trackerAuthPort: portSpy
        )

        do {
            _ = try useCase.validate(Self.linearSource())
            Issue.record("Expected disconnected tracker auth to block startup.")
        } catch let error as SymphonyStartupApplicationError {
            guard case .trackerAuthNotConnected(let trackerKind) = error else {
                Issue.record("Expected trackerAuthNotConnected, received \(error).")
                return
            }

            #expect(trackerKind == "linear")
        } catch {
            Issue.record("Expected SymphonyStartupApplicationError, received \(error).")
        }
    }

    @Test
    func validateRejectsStaleSession() {
        let portSpy = TrackerAuthPortSpy(
            status: SymphonyTrackerAuthStatusContract(
                trackerKind: "linear",
                state: .staleSession,
                statusMessage: "The stored tracker session expired and must be refreshed."
            )
        )
        let useCase = ValidateSymphonyTrackerConnectionReadinessUseCase(
            trackerAuthPort: portSpy
        )

        do {
            _ = try useCase.validate(Self.linearSource())
            Issue.record("Expected a stale tracker session to block startup.")
        } catch let error as SymphonyStartupApplicationError {
            guard case .trackerSessionStale(let trackerKind) = error else {
                Issue.record("Expected trackerSessionStale, received \(error).")
                return
            }

            #expect(trackerKind == "linear")
        } catch {
            Issue.record("Expected SymphonyStartupApplicationError, received \(error).")
        }
    }

    private static func linearSource() -> SymphonyServiceConfigContract.Tracker {
        SymphonyServiceConfigContract.Tracker(
            kind: "linear",
            endpoint: nil,
            projectSlug: "project-slug",
            activeStateTypes: ["backlog", "unstarted", "started"],
            terminalStateTypes: ["completed", "canceled"]
        )
    }
}
