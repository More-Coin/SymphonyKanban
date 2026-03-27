import Foundation

public struct SymphonyLinearTrackerAuthPortAdapter:
    SymphonyTrackerAuthPortProtocol
{
    private let configurationModel: LinearOAuthProviderConfigurationModel
    private let trackerConfigurationModel = LinearTrackerAuthConfigurationModel()
    private let authorizationRequestBuilder = LinearOAuthAuthorizationRequestBuilder()
    private let secureStore: any LinearOAuthSecureStoreProtocol
    private let gateway: any SymphonyTrackerOAuthPortProtocol

    public init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        self.init(
            environment: environment,
            secureStore: LinearOAuthSecureStore(),
            gateway: SymphonyLinearOAuthGateway()
        )
    }

    init(
        environment: [String: String],
        secureStore: any LinearOAuthSecureStoreProtocol,
        gateway: any SymphonyTrackerOAuthPortProtocol
    ) {
        self.configurationModel = LinearOAuthProviderConfigurationModel(environment: environment)
        self.secureStore = secureStore
        self.gateway = gateway
    }

    public func queryStatus(
        for trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) throws -> SymphonyTrackerAuthStatusContract {
        let normalizedTrackerKind = try trackerConfigurationModel.fromContract(
            from: trackerConfiguration
        )
        let session = try secureStore.loadSession()
        let pendingAuthorization = try secureStore.loadPendingAuthorization()

        if pendingAuthorization != nil, session == nil {
            return SymphonyTrackerAuthStatusContract(
                trackerKind: normalizedTrackerKind,
                state: .connecting,
                statusMessage: "Waiting for the OAuth callback."
            )
        }

        guard let session else {
            return SymphonyTrackerAuthStatusContract(
                trackerKind: normalizedTrackerKind,
                state: .disconnected,
                statusMessage: "No stored tracker session was found."
            )
        }

        if session.invalidatedAt != nil {
            return SymphonyTrackerAuthStatusContract(
                trackerKind: normalizedTrackerKind,
                state: .staleSession,
                statusMessage: session.lastErrorDescription ?? "The stored session is no longer valid.",
                connectedAt: session.connectedAt,
                expiresAt: session.expiresAt,
                accountLabel: nil
            )
        }

        if let expiresAt = session.expiresAt,
           expiresAt <= Date(),
           session.refreshToken == nil {
            return SymphonyTrackerAuthStatusContract(
                trackerKind: normalizedTrackerKind,
                state: .staleSession,
                statusMessage: "The stored tracker session expired and cannot be refreshed.",
                connectedAt: session.connectedAt,
                expiresAt: expiresAt,
                accountLabel: nil
            )
        }

        return SymphonyTrackerAuthStatusContract(
            trackerKind: normalizedTrackerKind,
            state: .connected,
            statusMessage: session.lastErrorDescription ?? "Connected to Linear.",
            connectedAt: session.connectedAt,
            expiresAt: session.expiresAt,
            accountLabel: nil
        )
    }

    public func startAuthorization(
        for trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) throws -> SymphonyTrackerAuthStartResultContract {
        let normalizedTrackerKind = try trackerConfigurationModel.fromContract(
            from: trackerConfiguration
        )
        let configuration = try configurationModel.toContract()
        let authorizationRequest = try authorizationRequestBuilder.makeRequest(
            using: configuration
        )

        try secureStore.savePendingAuthorization(authorizationRequest.pendingAuthorization)

        return SymphonyTrackerAuthStartResultContract(
            trackerKind: normalizedTrackerKind,
            browserLaunchURL: authorizationRequest.authorizationURL.absoluteString
        )
    }

    public func completeAuthorization(
        _ request: SymphonyTrackerAuthCallbackContract,
        for trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> SymphonyTrackerAuthStatusContract {
        let normalizedTrackerKind = try trackerConfigurationModel.fromContract(
            from: SymphonyServiceConfigContract.Tracker(
                kind: trackerConfiguration.kind ?? request.trackerKind,
                endpoint: trackerConfiguration.endpoint,
                projectSlug: trackerConfiguration.projectSlug,
                activeStates: trackerConfiguration.activeStates,
                terminalStates: trackerConfiguration.terminalStates
            )
        )

        if let errorCode = request.errorCode?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !errorCode.isEmpty {
            try? secureStore.clearPendingAuthorization()
            throw SymphonyTrackerAuthInfrastructureError.authorizationDenied(
                errorCode: errorCode,
                errorDescription: request.errorDescription
            )
        }

        guard let state = request.state?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !state.isEmpty else {
            throw SymphonyTrackerAuthInfrastructureError.missingAuthorizationState
        }

        guard let authorizationCode = request.authorizationCode?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !authorizationCode.isEmpty else {
            throw SymphonyTrackerAuthInfrastructureError.missingAuthorizationCode
        }

        guard let pendingAuthorization = try secureStore.loadPendingAuthorization() else {
            throw SymphonyTrackerAuthInfrastructureError.missingPendingAuthorization
        }

        guard pendingAuthorization.state == state else {
            throw SymphonyTrackerAuthInfrastructureError.authorizationStateMismatch
        }

        let configuration = try configurationModel.toContract()
        let tokenResponse = try await gateway.exchangeAuthorizationCode(
            SymphonyTrackerOAuthTokenExchangeContract(
                authorizationCode: authorizationCode,
                codeVerifier: pendingAuthorization.codeVerifier
            ),
            using: configuration
        )

        let session = LinearOAuthSessionModel(
            tokenContract: tokenResponse,
            connectedAt: Date()
        )

        try secureStore.saveSession(session)
        try secureStore.clearPendingAuthorization()

        return SymphonyTrackerAuthStatusContract(
            trackerKind: normalizedTrackerKind,
            state: .connected,
            statusMessage: "Connected to Linear.",
            connectedAt: session.connectedAt,
            expiresAt: session.expiresAt,
            accountLabel: nil
        )
    }

    public func disconnect(
        for trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> SymphonyTrackerAuthStatusContract {
        let normalizedTrackerKind = try trackerConfigurationModel.fromContract(
            from: trackerConfiguration
        )
        try secureStore.clearPendingAuthorization()
        try secureStore.clearSession()

        return SymphonyTrackerAuthStatusContract(
            trackerKind: normalizedTrackerKind,
            state: .disconnected,
            statusMessage: "The stored tracker session was removed."
        )
    }
}
