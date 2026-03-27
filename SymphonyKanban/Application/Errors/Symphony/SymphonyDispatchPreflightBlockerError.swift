import Foundation

public struct SymphonyDispatchPreflightBlockerError: StructuredErrorProtocol, LocalizedError, Equatable, Sendable {
    public let code: String
    public let message: String
    public let retryable: Bool
    public let details: String?

    public init(
        code: String,
        message: String,
        retryable: Bool,
        details: String?
    ) {
        self.code = code
        self.message = message
        self.retryable = retryable
        self.details = details
    }

    public var errorDescription: String? {
        message
    }
}
