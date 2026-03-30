import Foundation

struct LinearOAuthLoopbackListenerConfiguration: Sendable, Equatable {
    let host: String
    let port: UInt16
    let path: String
    let timeoutInterval: TimeInterval
    let timeout: Duration

    var redirectURI: String {
        "http://\(host):\(port)\(path)"
    }
}

enum LinearOAuthLoopbackConfiguration {
    static let defaultListenerConfiguration = LinearOAuthLoopbackListenerConfiguration(
        host: "127.0.0.1",
        port: 8765,
        path: "/linear/oauth/callback",
        timeoutInterval: 180,
        timeout: .seconds(180)
    )

    static let redirectURI = defaultListenerConfiguration.redirectURI
    static let host = defaultListenerConfiguration.host
    static let port = defaultListenerConfiguration.port
    static let path = defaultListenerConfiguration.path
    static let timeoutInterval = defaultListenerConfiguration.timeoutInterval
    static let timeout = defaultListenerConfiguration.timeout
}
