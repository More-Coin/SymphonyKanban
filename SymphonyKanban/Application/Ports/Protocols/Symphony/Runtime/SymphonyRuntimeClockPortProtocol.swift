import Foundation

public protocol SymphonyRuntimeClockPortProtocol: Sendable {
    func now() -> Date
    func nowMs() -> Int64
}
