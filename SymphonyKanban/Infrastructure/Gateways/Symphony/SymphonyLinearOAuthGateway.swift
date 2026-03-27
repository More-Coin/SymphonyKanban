import Foundation

private func symphonyDefaultLinearOAuthRequestExecutor(
    _ request: URLRequest
) async throws -> (Data, HTTPURLResponse) {
    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw SymphonyTrackerAuthInfrastructureError.tokenExchangeRequestFailed(
            details: "The Linear OAuth request did not return an HTTPURLResponse."
        )
    }

    return (data, httpResponse)
}

struct SymphonyLinearOAuthGateway: SymphonyTrackerOAuthPortProtocol, @unchecked Sendable {
    typealias RequestExecutor = @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

    private static let defaultTimeoutInterval: TimeInterval = 30

    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    private let requestExecutor: RequestExecutor
    private let requestBuilder = LinearOAuthTokenTransportRequestBuilder()
    private let responseTranslator = LinearOAuthTokenResponseDTOTranslator()

    init(
        jsonDecoder: JSONDecoder = JSONDecoder(),
        jsonEncoder: JSONEncoder = JSONEncoder(),
        requestExecutor: @escaping RequestExecutor = symphonyDefaultLinearOAuthRequestExecutor
    ) {
        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder
        self.requestExecutor = requestExecutor
    }

    func exchangeAuthorizationCode(
        _ request: SymphonyTrackerOAuthTokenExchangeContract,
        using configuration: SymphonyTrackerOAuthProviderConfigurationContract
    ) async throws -> SymphonyTrackerOAuthTokenResponseContract {
        let request = try requestBuilder.makeAuthorizationCodeRequest(
            request,
            using: configuration,
            jsonEncoder: jsonEncoder,
            timeoutInterval: Self.defaultTimeoutInterval
        )
        return responseTranslator.toContract(
            try await performTokenResponse(for: request)
        )
    }

    func refreshAccessToken(
        _ request: SymphonyTrackerOAuthRefreshContract,
        using configuration: SymphonyTrackerOAuthProviderConfigurationContract
    ) async throws -> SymphonyTrackerOAuthTokenResponseContract {
        let request = try requestBuilder.makeRefreshTokenRequest(
            request,
            using: configuration,
            jsonEncoder: jsonEncoder,
            timeoutInterval: Self.defaultTimeoutInterval
        )
        return responseTranslator.toContract(
            try await performTokenResponse(for: request)
        )
    }

    func revokeToken(
        _ request: SymphonyTrackerOAuthRevocationContract,
        using configuration: SymphonyTrackerOAuthProviderConfigurationContract
    ) async throws {
        let request = try requestBuilder.makeRevokeTokenRequest(
            request,
            using: configuration,
            jsonEncoder: jsonEncoder,
            timeoutInterval: Self.defaultTimeoutInterval
        )

        let (data, response) = try await performHTTPResponse(for: request)
        guard (200...299).contains(response.statusCode) else {
            throw SymphonyTrackerAuthInfrastructureError.tokenExchangeStatus(
                statusCode: response.statusCode,
                responseBody: String(data: data, encoding: .utf8)
            )
        }
    }

    private func performTokenResponse(
        for request: URLRequest
    ) async throws -> LinearOAuthTokenResponseDTO {
        let (data, response) = try await performHTTPResponse(for: request)

        guard (200...299).contains(response.statusCode) else {
            throw SymphonyTrackerAuthInfrastructureError.tokenExchangeStatus(
                statusCode: response.statusCode,
                responseBody: String(data: data, encoding: .utf8)
            )
        }

        do {
            return try jsonDecoder.decode(LinearOAuthTokenResponseDTO.self, from: data)
        } catch {
            throw SymphonyTrackerAuthInfrastructureError.tokenExchangePayloadInvalid(
                details: error.localizedDescription
            )
        }
    }

    private func performHTTPResponse(
        for request: URLRequest
    ) async throws -> (Data, HTTPURLResponse) {
        do {
            return try await requestExecutor(request)
        } catch let error as SymphonyTrackerAuthInfrastructureError {
            throw error
        } catch {
            throw SymphonyTrackerAuthInfrastructureError.tokenExchangeRequestFailed(
                details: error.localizedDescription
            )
        }
    }
}
