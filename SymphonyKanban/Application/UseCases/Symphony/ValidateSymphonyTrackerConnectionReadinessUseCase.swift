import Foundation

public struct ValidateSymphonyTrackerConnectionReadinessUseCase: Sendable {
    private let trackerAuthPort: any SymphonyTrackerAuthPortProtocol

    public init(
        trackerAuthPort: any SymphonyTrackerAuthPortProtocol
    ) {
        self.trackerAuthPort = trackerAuthPort
    }

    public func validate(
        _ trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) throws -> SymphonyTrackerAuthStatusContract {
        let trackerKind = trackerConfiguration.kind?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let status = try trackerAuthPort.queryStatus(for: trackerConfiguration)

        switch status.state {
        case .connected:
            return status
        case .disconnected, .connecting:
            throw SymphonyStartupApplicationError.trackerAuthNotConnected(
                trackerKind: trackerKind
            )
        case .staleSession:
            throw SymphonyStartupApplicationError.trackerSessionStale(
                trackerKind: trackerKind
            )
        }
    }
}
