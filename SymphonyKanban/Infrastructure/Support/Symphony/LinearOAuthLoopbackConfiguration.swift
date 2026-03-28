import Foundation

enum LinearOAuthLoopbackConfiguration {
    static let redirectURI = "http://127.0.0.1:8765/linear/oauth/callback"
    static let host = "127.0.0.1"
    static let port: UInt16 = 8765
    static let path = "/linear/oauth/callback"
    static let timeoutInterval: TimeInterval = 180
    static let timeout: Duration = .seconds(180)
}
