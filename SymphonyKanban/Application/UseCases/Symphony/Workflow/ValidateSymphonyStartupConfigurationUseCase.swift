public struct ValidateSymphonyStartupConfigurationUseCase {
    private let startupConfigurationValidatorPort: any SymphonyStartupConfigurationValidatorPortProtocol

    public init(
        startupConfigurationValidatorPort: any SymphonyStartupConfigurationValidatorPortProtocol
    ) {
        self.startupConfigurationValidatorPort = startupConfigurationValidatorPort
    }

    public func validate(
        _ configuration: SymphonyServiceConfigContract
    ) throws -> SymphonyServiceConfigContract {
        try startupConfigurationValidatorPort.validate(configuration)
        return configuration
    }
}
