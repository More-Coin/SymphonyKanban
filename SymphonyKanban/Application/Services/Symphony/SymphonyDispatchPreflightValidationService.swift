
import Foundation

public struct SymphonyDispatchPreflightValidationService {
    private let resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase
    private let validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase

    public init(
        resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase,
        validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase
    ) {
        self.resolveWorkflowConfigurationUseCase = resolveWorkflowConfigurationUseCase
        self.validateStartupConfigurationUseCase = validateStartupConfigurationUseCase
    }

    public func validateForDispatch(
        _ request: SymphonyWorkflowConfigurationRequestContract
    ) -> SymphonyDispatchPreflightOutcomeContract {
        do {
            let configuration = try resolveWorkflowConfigurationUseCase.resolveValidated(
                request,
                validateStartupConfigurationUseCase: validateStartupConfigurationUseCase
            )
            return .ready(configuration)
        } catch {
            return .blocked(makeBlocker(from: error))
        }
    }

    private func makeBlocker(
        from error: any Error
    ) -> SymphonyDispatchPreflightBlockerError {
        if let structuredError = error as? any StructuredErrorProtocol {
            return SymphonyDispatchPreflightBlockerError(
                code: structuredError.code,
                message: structuredError.message,
                retryable: structuredError.retryable,
                details: structuredError.details
            )
        }

        return SymphonyDispatchPreflightBlockerError(
            code: "symphony.dispatch_preflight.unexpected_error",
            message: "An unexpected error blocked dispatch preflight validation.",
            retryable: false,
            details: error.localizedDescription
        )
    }
}
