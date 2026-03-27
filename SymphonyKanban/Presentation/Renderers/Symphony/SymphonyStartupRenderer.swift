import Foundation

public struct SymphonyStartupRenderer {
    public init() {}

    public func render(_ result: SymphonyStartupResultContract) -> Int32 {
        print(
            startupLifecycleLine(
                outcome: "completed",
                details: "workflow_path=\"\(escapedValue(result.resolvedWorkflowPath))\""
            )
        )
        return EXIT_SUCCESS
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
