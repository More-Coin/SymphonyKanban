import CryptoKit
import Foundation

struct LinearOAuthAuthorizationRequestDTO {
    let authorizationURL: URL
    let pendingAuthorization: LinearOAuthPendingAuthorizationModel
}

struct LinearOAuthAuthorizationRequestBuilder {
    func makeRequest(
        using configuration: SymphonyTrackerOAuthProviderConfigurationContract
    ) throws -> LinearOAuthAuthorizationRequestDTO {
        let state = Self.randomToken()
        let codeVerifier = Self.randomToken()
        let codeChallenge = Self.codeChallenge(for: codeVerifier)

        guard var components = URLComponents(string: configuration.authorizeEndpoint) else {
            throw SymphonyTrackerAuthInfrastructureError.authorizationURLBuildFailed
        }

        components.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: configuration.scopes.joined(separator: ",")),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        guard let authorizationURL = components.url else {
            throw SymphonyTrackerAuthInfrastructureError.authorizationURLBuildFailed
        }

        return LinearOAuthAuthorizationRequestDTO(
            authorizationURL: authorizationURL,
            pendingAuthorization: LinearOAuthPendingAuthorizationModel(
                state: state,
                codeVerifier: codeVerifier,
                createdAt: Date()
            )
        )
    }

    private static func randomToken() -> String {
        let raw = Data((0..<32).map { _ in UInt8.random(in: UInt8.min...UInt8.max) })
        return base64URLEncoded(raw)
    }

    private static func codeChallenge(
        for verifier: String
    ) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return base64URLEncoded(Data(digest))
    }

    private static func base64URLEncoded(
        _ data: Data
    ) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

struct LinearOAuthTokenExchangeRequestDTO {
    let configuration: SymphonyTrackerOAuthProviderConfigurationContract
    let request: SymphonyTrackerOAuthTokenExchangeContract
}

struct LinearOAuthRefreshTokenRequestDTO {
    let configuration: SymphonyTrackerOAuthProviderConfigurationContract
    let request: SymphonyTrackerOAuthRefreshContract
}

struct LinearOAuthRevokeTokenRequestDTO {
    let configuration: SymphonyTrackerOAuthProviderConfigurationContract
    let request: SymphonyTrackerOAuthRevocationContract
}

struct LinearOAuthTokenResponseDTO: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String?
    let tokenType: String
    let expiresIn: Int?
    let scope: [String]

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case scope
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accessToken = try container.decode(String.self, forKey: .accessToken)
        self.refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        self.tokenType = try container.decode(String.self, forKey: .tokenType)
        self.expiresIn = try container.decodeIfPresent(Int.self, forKey: .expiresIn)

        if let scopeString = try? container.decode(String.self, forKey: .scope) {
            self.scope = scopeString
                .split(whereSeparator: \.isWhitespace)
                .map(String.init)
        } else {
            self.scope = try container.decodeIfPresent([String].self, forKey: .scope) ?? []
        }
    }

}

struct LinearOAuthTokenResponseDTOTranslator {
    func toContract(
        _ response: LinearOAuthTokenResponseDTO
    ) -> SymphonyTrackerOAuthTokenResponseContract {
        SymphonyTrackerOAuthTokenResponseContract(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            tokenType: response.tokenType,
            expiresIn: response.expiresIn,
            scope: response.scope
        )
    }
}

struct LinearOAuthTokenTransportRequestBuilder {
    func makeAuthorizationCodeRequest(
        _ request: SymphonyTrackerOAuthTokenExchangeContract,
        using configuration: SymphonyTrackerOAuthProviderConfigurationContract,
        timeoutInterval: TimeInterval
    ) throws -> URLRequest {
        try makeAuthorizationCodeRequest(
            LinearOAuthTokenExchangeRequestDTO(
                configuration: configuration,
                request: request
            ),
            timeoutInterval: timeoutInterval
        )
    }

    func makeAuthorizationCodeRequest(
        _ requestDefinition: LinearOAuthTokenExchangeRequestDTO,
        timeoutInterval: TimeInterval
    ) throws -> URLRequest {
        try makeRequest(
            endpoint: requestDefinition.configuration.tokenEndpoint,
            body: authorizationCodePayload(from: requestDefinition),
            timeoutInterval: timeoutInterval
        )
    }

    func makeRefreshTokenRequest(
        _ request: SymphonyTrackerOAuthRefreshContract,
        using configuration: SymphonyTrackerOAuthProviderConfigurationContract,
        timeoutInterval: TimeInterval
    ) throws -> URLRequest {
        try makeRefreshTokenRequest(
            LinearOAuthRefreshTokenRequestDTO(
                configuration: configuration,
                request: request
            ),
            timeoutInterval: timeoutInterval
        )
    }

    func makeRefreshTokenRequest(
        _ requestDefinition: LinearOAuthRefreshTokenRequestDTO,
        timeoutInterval: TimeInterval
    ) throws -> URLRequest {
        try makeRequest(
            endpoint: requestDefinition.configuration.tokenEndpoint,
            body: refreshTokenPayload(from: requestDefinition),
            timeoutInterval: timeoutInterval
        )
    }

    func makeRevokeTokenRequest(
        _ request: SymphonyTrackerOAuthRevocationContract,
        using configuration: SymphonyTrackerOAuthProviderConfigurationContract,
        timeoutInterval: TimeInterval
    ) throws -> URLRequest {
        try makeRevokeTokenRequest(
            LinearOAuthRevokeTokenRequestDTO(
                configuration: configuration,
                request: request
            ),
            timeoutInterval: timeoutInterval
        )
    }

    func makeRevokeTokenRequest(
        _ requestDefinition: LinearOAuthRevokeTokenRequestDTO,
        timeoutInterval: TimeInterval
    ) throws -> URLRequest {
        try makeRequest(
            endpoint: requestDefinition.configuration.revokeEndpoint,
            body: revokeTokenPayload(from: requestDefinition),
            timeoutInterval: timeoutInterval
        )
    }

    private func makeRequest(
        endpoint: String,
        body: [String: String],
        timeoutInterval: TimeInterval
    ) throws -> URLRequest {
        guard let url = URL(string: endpoint) else {
            throw SymphonyTrackerAuthInfrastructureError.tokenExchangeRequestFailed(
                details: "The configured OAuth endpoint is invalid: \(endpoint)"
            )
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeoutInterval
        request.httpBody = formURLEncodedData(from: body)
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func authorizationCodePayload(
        from request: LinearOAuthTokenExchangeRequestDTO
    ) -> [String: String] {
        var payload: [String: String] = [
            "grant_type": "authorization_code",
            "client_id": request.configuration.clientID,
            "redirect_uri": request.configuration.redirectURI,
            "code": request.request.authorizationCode,
            "code_verifier": request.request.codeVerifier
        ]

        if let clientSecret = request.configuration.clientSecret {
            payload["client_secret"] = clientSecret
        }

        return payload
    }

    private func refreshTokenPayload(
        from request: LinearOAuthRefreshTokenRequestDTO
    ) -> [String: String] {
        var payload: [String: String] = [
            "grant_type": "refresh_token",
            "client_id": request.configuration.clientID,
            "refresh_token": request.request.refreshToken
        ]

        if let clientSecret = request.configuration.clientSecret {
            payload["client_secret"] = clientSecret
        }

        return payload
    }

    private func revokeTokenPayload(
        from request: LinearOAuthRevokeTokenRequestDTO
    ) -> [String: String] {
        var payload: [String: String] = [
            "client_id": request.configuration.clientID,
            "token": request.request.token,
            "token_type_hint": request.request.tokenTypeHint
        ]

        if let clientSecret = request.configuration.clientSecret {
            payload["client_secret"] = clientSecret
        }

        return payload
    }

    private func formURLEncodedData(
        from body: [String: String]
    ) -> Data {
        let payload = body
            .sorted { $0.key < $1.key }
            .map { key, value in
                "\(Self.percentEncoded(key))=\(Self.percentEncoded(value))"
            }
            .joined(separator: "&")

        return Data(payload.utf8)
    }

    private static func percentEncoded(
        _ value: String
    ) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(
            CharacterSet(charactersIn: "-._~")
        )

        return value.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? value
    }
}
