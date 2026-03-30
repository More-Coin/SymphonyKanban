import Foundation

@MainActor
public struct SymphonyAuthController {
    private let trackerAuthService: SymphonyTrackerAuthService
    private let presenter: SymphonyAuthPresenter
    private let trackerConfiguration: SymphonyServiceConfigContract.Tracker
    private let previewViewModel: SymphonyAuthViewModel?

    public init(
        trackerAuthService: SymphonyTrackerAuthService,
        presenter: SymphonyAuthPresenter? = nil,
        trackerConfiguration: SymphonyServiceConfigContract.Tracker? = nil,
        previewViewModel: SymphonyAuthViewModel? = nil
    ) {
        self.trackerAuthService = trackerAuthService
        self.presenter = presenter ?? SymphonyAuthPresenter()
        self.trackerConfiguration = trackerConfiguration ?? .init(
            kind: "linear",
            endpoint: nil,
            projectSlug: nil,
            activeStateTypes: [],
            terminalStateTypes: []
        )
        self.previewViewModel = previewViewModel
    }

    public func withPreviewViewModel(
        _ previewViewModel: SymphonyAuthViewModel
    ) -> SymphonyAuthController {
        SymphonyAuthController(
            trackerAuthService: trackerAuthService,
            presenter: presenter,
            trackerConfiguration: trackerConfiguration,
            previewViewModel: previewViewModel
        )
    }

    public func queryViewModel() async -> SymphonyAuthViewModel {
        if let previewViewModel {
            return previewViewModel
        }

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
        using callback: SymphonyTrackerAuthCallbackContract
    ) async -> SymphonyAuthViewModel {
        do {
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
            guard let details = structuredError.details,
                  !details.isEmpty else {
                return structuredError.message
            }

            return "\(structuredError.message) \(details)"
        }

        return error.localizedDescription
    }
}
