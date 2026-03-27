public struct SymphonyTrackerAuthService: Sendable {
    private let startTrackerAuthUseCase: StartSymphonyTrackerAuthorizationUseCase
    private let completeTrackerAuthUseCase: CompleteSymphonyTrackerAuthorizationUseCase
    private let queryTrackerAuthStatusUseCase: QuerySymphonyTrackerAuthStatusUseCase
    private let disconnectTrackerAuthUseCase: DisconnectSymphonyTrackerUseCase

    public init(
        startTrackerAuthUseCase: StartSymphonyTrackerAuthorizationUseCase,
        completeTrackerAuthUseCase: CompleteSymphonyTrackerAuthorizationUseCase,
        queryTrackerAuthStatusUseCase: QuerySymphonyTrackerAuthStatusUseCase,
        disconnectTrackerAuthUseCase: DisconnectSymphonyTrackerUseCase
    ) {
        self.startTrackerAuthUseCase = startTrackerAuthUseCase
        self.completeTrackerAuthUseCase = completeTrackerAuthUseCase
        self.queryTrackerAuthStatusUseCase = queryTrackerAuthStatusUseCase
        self.disconnectTrackerAuthUseCase = disconnectTrackerAuthUseCase
    }

    public func execute(
        _ request: SymphonyTrackerAuthServiceRequestContract
    ) async throws -> SymphonyTrackerAuthServiceResultContract {
        switch request {
        case .queryStatus(let trackerConfiguration):
            return .status(
                try queryTrackerAuthStatusUseCase.execute(using: trackerConfiguration)
            )
        case .startAuthorization(let trackerConfiguration):
            return .start(
                try startTrackerAuthUseCase.execute(using: trackerConfiguration)
            )
        case .completeAuthorization(let trackerConfiguration, let callback):
            return .status(
                try await completeTrackerAuthUseCase.execute(
                    callback,
                    using: trackerConfiguration
                )
            )
        case .disconnect(let trackerConfiguration):
            return .status(
                try await disconnectTrackerAuthUseCase.execute(using: trackerConfiguration)
            )
        }
    }
}
