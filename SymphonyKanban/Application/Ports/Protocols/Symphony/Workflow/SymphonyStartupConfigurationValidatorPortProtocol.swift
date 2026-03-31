public protocol SymphonyStartupConfigurationValidatorPortProtocol {
    func validate(
        _ configuration: SymphonyServiceConfigContract
    ) throws
}
