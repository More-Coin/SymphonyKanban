public struct SymphonyCodexCapabilitiesContract: Equatable, Sendable {
    public let experimentalAPI: Bool
    public let optOutNotificationMethods: [String]

    public init(
        experimentalAPI: Bool = false,
        optOutNotificationMethods: [String] = []
    ) {
        self.experimentalAPI = experimentalAPI
        self.optOutNotificationMethods = optOutNotificationMethods
    }
}
