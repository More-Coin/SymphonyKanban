public struct SymphonyTrackerAuthStartResultContract: Equatable, Sendable {
    public let trackerKind: String
    public let browserLaunchURL: String

    public init(
        trackerKind: String,
        browserLaunchURL: String
    ) {
        self.trackerKind = trackerKind
        self.browserLaunchURL = browserLaunchURL
    }
}
