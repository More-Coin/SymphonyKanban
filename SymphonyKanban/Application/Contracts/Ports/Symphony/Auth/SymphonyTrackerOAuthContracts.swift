public struct SymphonyTrackerOAuthProviderConfigurationContract: Equatable, Sendable {
    public let clientID: String
    public let clientSecret: String?
    public let redirectURI: String
    public let authorizeEndpoint: String
    public let tokenEndpoint: String
    public let revokeEndpoint: String
    public let scopes: [String]

    public init(
        clientID: String,
        clientSecret: String?,
        redirectURI: String,
        authorizeEndpoint: String,
        tokenEndpoint: String,
        revokeEndpoint: String,
        scopes: [String]
    ) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
        self.authorizeEndpoint = authorizeEndpoint
        self.tokenEndpoint = tokenEndpoint
        self.revokeEndpoint = revokeEndpoint
        self.scopes = scopes
    }
}

public struct SymphonyTrackerOAuthTokenExchangeContract: Equatable, Sendable {
    public let authorizationCode: String
    public let codeVerifier: String

    public init(
        authorizationCode: String,
        codeVerifier: String
    ) {
        self.authorizationCode = authorizationCode
        self.codeVerifier = codeVerifier
    }
}

public struct SymphonyTrackerOAuthRefreshContract: Equatable, Sendable {
    public let refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

public struct SymphonyTrackerOAuthRevocationContract: Equatable, Sendable {
    public let token: String
    public let tokenTypeHint: String

    public init(
        token: String,
        tokenTypeHint: String
    ) {
        self.token = token
        self.tokenTypeHint = tokenTypeHint
    }
}

public struct SymphonyTrackerOAuthTokenResponseContract: Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String?
    public let tokenType: String
    public let expiresIn: Int?
    public let scope: [String]

    public init(
        accessToken: String,
        refreshToken: String?,
        tokenType: String,
        expiresIn: Int?,
        scope: [String]
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.scope = scope
    }
}
