import Foundation

public struct SymphonyStartupRenderer {
    public init() {}

    public func render(_ result: SymphonyStartupResultContract) -> Int32 {
        switch result.state {
        case .ready:
            print(
                startupLifecycleLine(
                    outcome: "completed",
                    details: """
                    startup_state=\(result.state.rawValue) \
                    active_bindings=\(result.activeBindingCount) \
                    ready_bindings=\(result.readyBindingCount) \
                    failed_bindings=\(result.failedBindingCount)
                    """
                )
            )
            return EXIT_SUCCESS
        case .setupRequired:
            print(
                startupLifecycleLine(
                    outcome: "blocked",
                    details: "startup_state=\(result.state.rawValue)"
                )
            )
            return EXIT_FAILURE
        }
    }

    public func renderError(_ error: any Error) -> Int32 {
        if let structuredError = error as? any StructuredErrorProtocol {
            fputs(
                "\(startupLifecycleLine(outcome: "failed", details: structuredFailureDetails(for: structuredError, error: error)))\n",
                stderr
            )
            return EXIT_FAILURE
        }

        fputs(
            """
            \(startupLifecycleLine(
                outcome: "failed",
                details: """
                error_code=symphony.startup.unexpected_error \
                reason="An unexpected startup error occurred." \
                retryable=false
                """
            ))\n
            """,
            stderr
        )
        return EXIT_FAILURE
    }

    private func startupLifecycleLine(outcome: String, details: String) -> String {
        "component=symphony event=startup_validation outcome=\(outcome) \(details)"
    }

    private func structuredFailureDetails(
        for structuredError: any StructuredErrorProtocol,
        error: any Error
    ) -> String {
        var details: [String] = [
            "error_code=\(structuredError.code)",
            "reason=\"\(escapedValue(structuredError.message))\"",
            "retryable=\(structuredError.retryable)"
        ]

        if case let SymphonyWorkflowInfrastructureError.missingWorkflowFile(path) = error {
            details.append("workflow_path=\"\(escapedValue(path))\"")
        }

        return details.joined(separator: " ")
    }
    
    private func escapedValue(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
