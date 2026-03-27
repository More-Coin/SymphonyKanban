import Foundation

struct LinearOAuthSessionLifetimeModel {
    let connectedAt: Date
    let expiresAt: Date?

    static func fromContract(
        _ tokenContract: SymphonyTrackerOAuthTokenResponseContract,
        connectedAt: Date
    ) -> LinearOAuthSessionLifetimeModel {
        LinearOAuthSessionLifetimeModel(
            connectedAt: connectedAt,
            expiresAt: tokenContract.expiresIn.map {
                connectedAt.addingTimeInterval(TimeInterval($0))
            }
        )
    }

    static func fromContract(
        _ tokenContract: SymphonyTrackerOAuthTokenResponseContract,
        existingSession: LinearOAuthSessionModel
    ) -> LinearOAuthSessionLifetimeModel {
        LinearOAuthSessionLifetimeModel(
            connectedAt: existingSession.connectedAt,
            expiresAt: tokenContract.expiresIn.map {
                Date().addingTimeInterval(TimeInterval($0))
            }
        )
    }
}

struct LinearOAuthSessionModel: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String?
    let tokenType: String
    let scope: [String]
    let connectedAt: Date
    let expiresAt: Date?
    let invalidatedAt: Date?
    let lastErrorDescription: String?

    init(
        accessToken: String,
        refreshToken: String?,
        tokenType: String,
        scope: [String],
        connectedAt: Date,
        expiresAt: Date?,
        invalidatedAt: Date?,
        lastErrorDescription: String?
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.scope = scope
        self.connectedAt = connectedAt
        self.expiresAt = expiresAt
        self.invalidatedAt = invalidatedAt
        self.lastErrorDescription = lastErrorDescription
    }

    init(
        tokenContract: SymphonyTrackerOAuthTokenResponseContract,
        connectedAt: Date
    ) {
        let lifetime = LinearOAuthSessionLifetimeModel.fromContract(
            tokenContract,
            connectedAt: connectedAt
        )
        self.init(
            accessToken: tokenContract.accessToken,
            refreshToken: tokenContract.refreshToken,
            tokenType: tokenContract.tokenType,
            scope: tokenContract.scope,
            connectedAt: lifetime.connectedAt,
            expiresAt: lifetime.expiresAt,
            invalidatedAt: nil,
            lastErrorDescription: nil
        )
    }

    init(
        refreshedTokenContract tokenContract: SymphonyTrackerOAuthTokenResponseContract,
        existing session: LinearOAuthSessionModel
    ) {
        let lifetime = LinearOAuthSessionLifetimeModel.fromContract(
            tokenContract,
            existingSession: session
        )
        self.init(
            accessToken: tokenContract.accessToken,
            refreshToken: tokenContract.refreshToken ?? session.refreshToken,
            tokenType: tokenContract.tokenType,
            scope: tokenContract.scope,
            connectedAt: lifetime.connectedAt,
            expiresAt: lifetime.expiresAt,
            invalidatedAt: nil,
            lastErrorDescription: nil
        )
    }

    init(
        invalidated session: LinearOAuthSessionModel,
        reason: String,
        invalidatedAt: Date
    ) {
        self.init(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            tokenType: session.tokenType,
            scope: session.scope,
            connectedAt: session.connectedAt,
            expiresAt: session.expiresAt,
            invalidatedAt: invalidatedAt,
            lastErrorDescription: reason
        )
    }
}

struct LinearOAuthPendingAuthorizationModel: Codable, Equatable, Sendable {
    let state: String
    let codeVerifier: String
    let createdAt: Date
}
