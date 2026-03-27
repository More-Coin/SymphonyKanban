import Foundation

public struct ArchitectureDiagnostic: Sendable, Equatable {
    public let ruleID: String
    public let path: String
    public let line: Int
    public let column: Int
    public let message: String

    public init(ruleID: String, path: String, line: Int, column: Int, message: String) {
        self.ruleID = ruleID
        self.path = path
        self.line = line
        self.column = column
        self.message = message
    }
}
