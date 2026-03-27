public enum SymphonyTrackerAuthServiceRequestContract: Sendable {
    case queryStatus(SymphonyServiceConfigContract.Tracker)
    case startAuthorization(SymphonyServiceConfigContract.Tracker)
    case completeAuthorization(
        trackerConfiguration: SymphonyServiceConfigContract.Tracker,
        callback: SymphonyTrackerAuthCallbackContract
    )
    case disconnect(SymphonyServiceConfigContract.Tracker)
}

public enum SymphonyTrackerAuthServiceResultContract: Sendable, Equatable {
    case status(SymphonyTrackerAuthStatusContract)
    case start(SymphonyTrackerAuthStartResultContract)

    public var status: SymphonyTrackerAuthStatusContract? {
        if case let .status(value) = self {
            return value
        }

        return nil
    }

    public var start: SymphonyTrackerAuthStartResultContract? {
        if case let .start(value) = self {
            return value
        }

        return nil
    }
}
