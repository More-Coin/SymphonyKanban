public struct SymphonyCodexClientInfoContract: Equatable, Sendable {
    public let name: String
    public let title: String?
    public let version: String

    public init(
        name: String,
        title: String? = nil,
        version: String
    ) {
        self.name = name
        self.title = title
        self.version = version
    }
}
