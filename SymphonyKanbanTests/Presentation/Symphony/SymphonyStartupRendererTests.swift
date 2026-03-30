import Foundation
import Testing
@testable import SymphonyKanban

@Suite(.serialized)
struct SymphonyStartupRendererTests {
    @Test
    func startupRendererRendersReadyStartupStateAsSuccess() {
        let renderer = SymphonyStartupRenderer()

        let (stdoutOutput, exitCode) = SymphonyStartupFlowTestSupport.captureStandardOutput {
            renderer.render(
                SymphonyStartupResultContract(
                    state: .ready,
                    activeBindingCount: 2,
                    readyBindingCount: 1,
                    failedBindingCount: 1
                )
            )
        }

        #expect(exitCode == EXIT_SUCCESS)
        #expect(
            stdoutOutput.contains(
                "component=symphony event=startup_validation outcome=completed"
            )
        )
        #expect(stdoutOutput.contains("startup_state=ready"))
        #expect(stdoutOutput.contains("active_bindings=2"))
        #expect(stdoutOutput.contains("ready_bindings=1"))
        #expect(stdoutOutput.contains("failed_bindings=1"))
    }

    @Test
    func startupRendererRendersSetupRequiredStateAsBlockedNonZero() {
        let renderer = SymphonyStartupRenderer()

        let (stdoutOutput, exitCode) = SymphonyStartupFlowTestSupport.captureStandardOutput {
            renderer.render(
                SymphonyStartupResultContract(
                    state: .setupRequired,
                    activeBindingCount: 0,
                    readyBindingCount: 0,
                    failedBindingCount: 0
                )
            )
        }

        #expect(exitCode == EXIT_FAILURE)
        #expect(
            stdoutOutput.contains(
                "component=symphony event=startup_validation outcome=blocked"
            )
        )
        #expect(stdoutOutput.contains("startup_state=setupRequired"))
    }
}
