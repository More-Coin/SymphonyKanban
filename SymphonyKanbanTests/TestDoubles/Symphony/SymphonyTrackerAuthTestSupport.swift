import Foundation
@testable import SymphonyKanban

final class SymphonyTrackerAuthPortSpy: @unchecked Sendable, SymphonyTrackerAuthPortProtocol {
    private let lock = NSLock()
    private var status: SymphonyTrackerAuthStatusContract

    init(
        status: SymphonyTrackerAuthStatusContract = SymphonyTrackerAuthStatusContract(
            trackerKind: "linear",
            state: .connected,
            statusMessage: "Connected to Linear."
        )
    ) {
        self.status = status
    }

    func queryStatus(
        for _: SymphonyServiceConfigContract.Tracker
    ) throws -> SymphonyTrackerAuthStatusContract {
        lock.withLock { status }
    }

    func startAuthorization(
        for trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) throws -> SymphonyTrackerAuthStartResultContract {
        SymphonyTrackerAuthStartResultContract(
            trackerKind: trackerConfiguration.kind ?? "linear",
            browserLaunchURL: "https://linear.app/oauth/authorize"
        )
    }

    func completeAuthorization(
        _ callback: SymphonyTrackerAuthCallbackContract,
        for trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> SymphonyTrackerAuthStatusContract {
        let nextStatus = SymphonyTrackerAuthStatusContract(
            trackerKind: trackerConfiguration.kind ?? callback.trackerKind,
            state: .connected,
            statusMessage: "Connected to Linear."
        )
        setStatus(nextStatus)
        return nextStatus
    }

    func disconnect(
        for trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> SymphonyTrackerAuthStatusContract {
        let nextStatus = SymphonyTrackerAuthStatusContract(
            trackerKind: trackerConfiguration.kind ?? "linear",
            state: .disconnected,
            statusMessage: "Disconnected."
        )
        setStatus(nextStatus)
        return nextStatus
    }

    func setStatus(
        _ status: SymphonyTrackerAuthStatusContract
    ) {
        lock.withLock {
            self.status = status
        }
    }
}

typealias TrackerAuthPortSpy = SymphonyTrackerAuthPortSpy

struct LinearOAuthSecureStoreValueSpy: LinearOAuthSecureStoreProtocol {
    var session: LinearOAuthSessionModel?
    var pendingAuthorization: LinearOAuthPendingAuthorizationModel?

    init(
        session: LinearOAuthSessionModel? = nil,
        pendingAuthorization: LinearOAuthPendingAuthorizationModel? = nil
    ) {
        self.session = session
        self.pendingAuthorization = pendingAuthorization
    }

    func loadSession() throws -> LinearOAuthSessionModel? {
        session
    }

    func saveSession(_ session: LinearOAuthSessionModel) throws {
        _ = session
    }

    func clearSession() throws {}

    func loadPendingAuthorization() throws -> LinearOAuthPendingAuthorizationModel? {
        pendingAuthorization
    }

    func savePendingAuthorization(_ pendingAuthorization: LinearOAuthPendingAuthorizationModel) throws {
        _ = pendingAuthorization
    }

    func clearPendingAuthorization() throws {}
}

typealias LinearOAuthSecureStoreSpy = LinearOAuthSecureStoreValueSpy
