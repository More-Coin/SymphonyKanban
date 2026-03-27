import Foundation

@MainActor
public struct SymphonyAuthController {
    private let trackerAuthService: SymphonyTrackerAuthService
    private let presenter: SymphonyAuthPresenter
    private let trackerConfiguration: SymphonyServiceConfigContract.Tracker

    public init(
        trackerAuthService: SymphonyTrackerAuthService,
        presenter: SymphonyAuthPresenter? = nil,
        trackerConfiguration: SymphonyServiceConfigContract.Tracker? = nil
    ) {
        self.trackerAuthService = trackerAuthService
        self.presenter = presenter ?? SymphonyAuthPresenter()
        self.trackerConfiguration = trackerConfiguration ?? .init(
            kind: "linear",
            endpoint: nil,
            projectSlug: nil,
            activeStates: [],
            terminalStates: []
        )
    }

    public func queryViewModel() async -> SymphonyAuthViewModel {
        do {
            return presenter.present(
                try await executeStatus(.queryStatus(trackerConfiguration))
            )
        } catch {
            return errorViewModel(for: error)
        }
    }

    public func startAuthorization() async throws -> SymphonyTrackerAuthStartResultContract {
        guard case let .start(result) = try await trackerAuthService.execute(
            .startAuthorization(trackerConfiguration)
        ) else {
            preconditionFailure("Start authorization must return a start result.")
        }

        return result
    }

    public func viewModelAfterStartingAuthorization() async -> SymphonyAuthViewModel {
        await queryViewModel()
    }

    public func completeAuthorizationViewModel(
        from callbackURL: URL
    ) async -> SymphonyAuthViewModel {
        do {
            let callback = try SymphonyTrackerAuthCallbackDTO(
                callbackURL: callbackURL
            ).callbackContract(
                trackerKind: trackerConfiguration.kind ?? "linear"
            )
            let status = try await executeStatus(
                .completeAuthorization(
                    trackerConfiguration: trackerConfiguration,
                    callback: callback
                )
            )
            return presenter.present(status)
        } catch {
            return errorViewModel(for: error)
        }
    }

    public func disconnectViewModel() async -> SymphonyAuthViewModel {
        do {
            let status = try await executeStatus(.disconnect(trackerConfiguration))
            return presenter.present(status)
        } catch {
            return errorViewModel(for: error)
        }
    }

    public func errorViewModel(
        for error: any Error
    ) -> SymphonyAuthViewModel {
        presenter.present(
            currentStatusOrFallback(),
            errorMessage: structuredMessage(for: error)
        )
    }

    private func currentStatusOrFallback() -> SymphonyTrackerAuthStatusContract {
        SymphonyTrackerAuthStatusContract(
            trackerKind: trackerConfiguration.kind ?? "linear",
            state: .disconnected,
            statusMessage: "No tracker session is connected."
        )
    }

    private func executeStatus(
        _ request: SymphonyTrackerAuthServiceRequestContract
    ) async throws -> SymphonyTrackerAuthStatusContract {
        guard case let .status(status) = try await trackerAuthService.execute(request) else {
            preconditionFailure("Expected a status result.")
        }

        return status
    }

    private func structuredMessage(
        for error: any Error
    ) -> String {
        if let structuredError = error as? any StructuredErrorProtocol {
            return structuredError.message
        }

        return error.localizedDescription
    }
}
