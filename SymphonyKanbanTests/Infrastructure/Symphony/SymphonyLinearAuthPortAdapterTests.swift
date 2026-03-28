import Foundation
import Testing
@testable import SymphonyKanban

struct SymphonyLinearAuthPortAdapterTests {
    @Test
    func queryStatusReturnsConnectingWhenPendingAuthorizationExists() throws {
        let adapter = SymphonyLinearTrackerAuthPortAdapter(
            environment: Self.oauthEnvironment(),
            secureStore: LinearOAuthIssueTrackerSecureStoreSpy(
                pendingAuthorization: LinearOAuthPendingAuthorizationModel(
                    state: "pending-state",
                    codeVerifier: "code-verifier",
                    createdAt: Date(timeIntervalSince1970: 100)
                )
            ),
            gateway: SymphonyLinearOAuthGateway()
        )

        let status = try adapter.queryStatus(for: Self.linearSource())

        #expect(status.state == .connecting)
        #expect(status.statusMessage == "Waiting for the OAuth callback.")
    }

    @Test
    func queryStatusReturnsStaleSessionWhenExpiredSessionCannotRefresh() throws {
        let expiredAt = Date(timeIntervalSince1970: 1_000)
        let adapter = SymphonyLinearTrackerAuthPortAdapter(
            environment: Self.oauthEnvironment(),
            secureStore: LinearOAuthIssueTrackerSecureStoreSpy(
                session: LinearOAuthSessionModel(
                    accessToken: "expired-token",
                    refreshToken: nil,
                    tokenType: "Bearer",
                    scope: ["read"],
                    connectedAt: Date(timeIntervalSince1970: 900),
                    expiresAt: expiredAt,
                    invalidatedAt: nil,
                    lastErrorDescription: nil
                )
            ),
            gateway: SymphonyLinearOAuthGateway()
        )

        let status = try adapter.queryStatus(for: Self.linearSource())

        #expect(status.state == .staleSession)
        #expect(status.expiresAt == expiredAt)
    }

    @Test
    func startAuthorizationPersistsPendingAuthorizationAndReturnsLinearAuthorizeURL() throws {
        let secureStore = LinearOAuthIssueTrackerSecureStoreSpy()
        let adapter = SymphonyLinearTrackerAuthPortAdapter(
            environment: Self.oauthEnvironment(),
            secureStore: secureStore,
            gateway: SymphonyLinearOAuthGateway()
        )

        let result = try adapter.startAuthorization(for: Self.linearSource())
        let pendingAuthorization = try #require(try secureStore.loadPendingAuthorization())
        let authorizationURL = try #require(URL(string: result.browserLaunchURL))
        let components = try #require(URLComponents(url: authorizationURL, resolvingAgainstBaseURL: false))
        let queryItems = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )

        #expect(result.trackerKind == "linear")
        #expect(components.host == "linear.app")
        #expect(queryItems["client_id"] == "client-id")
        #expect(queryItems["redirect_uri"] == LinearOAuthLoopbackConfiguration.redirectURI)
        #expect(queryItems["response_type"] == "code")
        #expect(queryItems["scope"] == "read,issues:read")
        #expect(queryItems["state"] == pendingAuthorization.state)
        #expect(queryItems["code_challenge_method"] == "S256")
        #expect((queryItems["code_challenge"] ?? "").isEmpty == false)
        #expect(pendingAuthorization.codeVerifier.isEmpty == false)
    }

    @Test
    func completeAuthorizationStoresSessionAndClearsPendingAuthorization() async throws {
        let secureStore = LinearOAuthIssueTrackerSecureStoreSpy(
            pendingAuthorization: LinearOAuthPendingAuthorizationModel(
                state: "expected-state",
                codeVerifier: "expected-code-verifier",
                createdAt: Date(timeIntervalSince1970: 100)
            )
        )
        let executor = OAuthRequestExecutorSpy(
            result: .success(Self.oauthHTTPResponse(statusCode: 200, body: """
            {
              "access_token": "new-access-token",
              "refresh_token": "new-refresh-token",
              "token_type": "Bearer",
              "expires_in": 3600,
              "scope": "read issues:read"
            }
            """))
        )
        let adapter = SymphonyLinearTrackerAuthPortAdapter(
            environment: Self.oauthEnvironment(),
            secureStore: secureStore,
            gateway: SymphonyLinearOAuthGateway(
                requestExecutor: { request in
                    try await executor.execute(request)
                }
            )
        )

        let status = try await adapter.completeAuthorization(
            SymphonyTrackerAuthCallbackContract(
                trackerKind: "linear",
                authorizationCode: "received-code",
                state: "expected-state",
                errorCode: nil,
                errorDescription: nil
            ),
            for: Self.linearSource()
        )

        let request = try #require(await executor.request())
        let session = try #require(try secureStore.loadSession())

        #expect(status.state == .connected)
        #expect(status.statusMessage == "Connected to Linear.")
        #expect(request.url?.absoluteString == "https://api.linear.app/oauth/token")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(try Self.requestBody(request)["grant_type"] as? String == "authorization_code")
        #expect(try Self.requestBody(request)["code"] as? String == "received-code")
        #expect(try Self.requestBody(request)["code_verifier"] as? String == "expected-code-verifier")
        #expect(session.accessToken == "new-access-token")
        #expect(session.refreshToken == "new-refresh-token")
        #expect(try secureStore.loadPendingAuthorization() == nil)
    }

    private static func linearSource() -> SymphonyServiceConfigContract.Tracker {
        SymphonyServiceConfigContract.Tracker(
            kind: "linear",
            endpoint: nil,
            projectSlug: "project-slug",
            activeStateTypes: ["backlog", "unstarted", "started"],
            terminalStateTypes: ["completed", "canceled"]
        )
    }

    private static func oauthEnvironment() -> [String: String] {
        [
            "LINEAR_OAUTH_CLIENT_ID": "client-id",
            "LINEAR_OAUTH_SCOPES": "read,issues:read"
        ]
    }

    private static func oauthHTTPResponse(
        statusCode: Int,
        body: String
    ) -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(
            url: URL(string: "https://api.linear.app/oauth/token")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!

        return (Data(body.utf8), response)
    }

    private static func requestBody(
        _ request: URLRequest
    ) throws -> [String: Any] {
        enum InvalidRequestBody: Error {
            case missingBody
            case invalidObject
        }

        guard let body = request.httpBody else {
            throw InvalidRequestBody.missingBody
        }

        guard let object = try JSONSerialization.jsonObject(with: body) as? [String: Any] else {
            throw InvalidRequestBody.invalidObject
        }

        return object
    }
}

actor OAuthRequestExecutorSpy {
    private let result: Result<(Data, HTTPURLResponse), Error>
    private var recordedRequest: URLRequest?

    init(result: Result<(Data, HTTPURLResponse), Error>) {
        self.result = result
    }

    func execute(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        recordedRequest = request
        return try result.get()
    }

    func request() -> URLRequest? {
        recordedRequest
    }
}
