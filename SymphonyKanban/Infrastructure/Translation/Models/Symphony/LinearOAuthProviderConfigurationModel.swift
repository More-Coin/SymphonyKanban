import Foundation

struct LinearOAuthProviderConfigurationModel {
    private let environment: [String: String]

    init(environment: [String: String]) {
        self.environment = environment
    }

    func toContract() throws -> SymphonyTrackerOAuthProviderConfigurationContract {
        guard let clientID = normalizedValue(for: "LINEAR_OAUTH_CLIENT_ID") else {
            throw SymphonyTrackerAuthInfrastructureError.missingOAuthClientID
        }

        guard let redirectURI = normalizedValue(for: "LINEAR_OAUTH_REDIRECT_URI") else {
            throw SymphonyTrackerAuthInfrastructureError.missingOAuthRedirectURI
        }

        guard URL(string: redirectURI) != nil else {
            throw SymphonyTrackerAuthInfrastructureError.invalidOAuthRedirectURI(
                value: redirectURI
            )
        }

        let scopes = normalizedValue(for: "LINEAR_OAUTH_SCOPES")?
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } ?? ["read"]

        return SymphonyTrackerOAuthProviderConfigurationContract(
            clientID: clientID,
            clientSecret: normalizedValue(for: "LINEAR_OAUTH_CLIENT_SECRET"),
            redirectURI: redirectURI,
            authorizeEndpoint: "https://linear.app/oauth/authorize",
            tokenEndpoint: "https://api.linear.app/oauth/token",
            revokeEndpoint: "https://api.linear.app/oauth/revoke",
            scopes: scopes
        )
    }

    private func normalizedValue(
        for key: String
    ) -> String? {
        guard let value = environment[key]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }

        return value
    }
}
