public protocol StructuredErrorProtocol: Error, Sendable {
    var code: String { get }
    var message: String { get }
    var retryable: Bool { get }
    var details: String? { get }
}
