import Foundation

public struct SymphonyRuntimeClockGateway: SymphonyRuntimeClockPortProtocol {
    public init() {}

    public func now() -> Date {
        Date()
    }

    public func nowMs() -> Int64 {
        Int64(now().timeIntervalSince1970 * 1000)
    }
}
