public struct SymphonyCodexCommandResolutionContract: Equatable, Sendable {
    public let configuredCommand: String
    public let effectiveCommand: String
    public let executableName: String
    public let executablePath: String?
    public let detailMessage: String?

    public init(
        configuredCommand: String,
        effectiveCommand: String,
        executableName: String,
        executablePath: String?,
        detailMessage: String?
    ) {
        self.configuredCommand = configuredCommand
        self.effectiveCommand = effectiveCommand
        self.executableName = executableName
        self.executablePath = executablePath
        self.detailMessage = detailMessage
    }
}
