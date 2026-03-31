public protocol SymphonyTrackerOAuthPortProtocol: Sendable {
    func exchangeAuthorizationCode(
        _ request: SymphonyTrackerOAuthTokenExchangeContract,
        using configuration: SymphonyTrackerOAuthProviderConfigurationContract
    ) async throws -> SymphonyTrackerOAuthTokenResponseContract

    func refreshAccessToken(
        _ request: SymphonyTrackerOAuthRefreshContract,
        using configuration: SymphonyTrackerOAuthProviderConfigurationContract
    ) async throws -> SymphonyTrackerOAuthTokenResponseContract

    func revokeToken(
        _ request: SymphonyTrackerOAuthRevocationContract,
        using configuration: SymphonyTrackerOAuthProviderConfigurationContract
    ) async throws
}
