import Foundation

struct LinearIssueTrackerAuthorizationProvider {
    private let refreshDefinitionModel = LinearOAuthRefreshDefinitionModel()
    private let secureStore: any LinearOAuthSecureStoreProtocol
    private let oauthGateway: any SymphonyTrackerOAuthPortProtocol
    private let oauthConfigurationModel: LinearOAuthProviderConfigurationModel

    init(
        environment: [String: String],
        secureStore: any LinearOAuthSecureStoreProtocol,
        oauthGateway: any SymphonyTrackerOAuthPortProtocol
    ) {
        self.secureStore = secureStore
        self.oauthGateway = oauthGateway
        self.oauthConfigurationModel = LinearOAuthProviderConfigurationModel(environment: environment)
    }

    func authorizationHeader() async throws -> String {
        let session = try await refreshedSession()
        return "Bearer \(session.accessToken)"
    }

    private func refreshedSession() async throws -> LinearOAuthSessionModel {
        guard let session = try secureStore.loadSession() else {
            throw SymphonyIssueTrackerInfrastructureError.missingTrackerSession
        }

        if session.invalidatedAt != nil {
            throw SymphonyIssueTrackerInfrastructureError.staleTrackerSession(
                details: session.lastErrorDescription
            )
        }

        guard let expiresAt = session.expiresAt else {
            return session
        }

        if expiresAt > Date() {
            return session
        }

        let configuration: SymphonyTrackerOAuthProviderConfigurationContract
        do {
            configuration = try oauthConfigurationModel.toContract()
        } catch {
            try invalidateSession(session, reason: error.localizedDescription)
            throw SymphonyIssueTrackerInfrastructureError.staleTrackerSession(
                details: error.localizedDescription
            )
        }

        let refreshRequest = try refreshDefinitionModel.fromContract(from: session)

        do {
            let refreshed = try await oauthGateway.refreshAccessToken(
                refreshRequest,
                using: configuration
            )

            let refreshedSession = LinearOAuthSessionModel(
                refreshedTokenContract: refreshed,
                existing: session
            )

            try secureStore.saveSession(refreshedSession)
            return refreshedSession
        } catch {
            try invalidateSession(session, reason: error.localizedDescription)
            throw SymphonyIssueTrackerInfrastructureError.staleTrackerSession(
                details: error.localizedDescription
            )
        }
    }

    private func invalidateSession(
        _ session: LinearOAuthSessionModel,
        reason: String
    ) throws {
        try secureStore.saveSession(
            LinearOAuthSessionModel(
                invalidated: session,
                reason: reason,
                invalidatedAt: Date()
            )
        )
    }
}
