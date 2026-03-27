import Foundation

public struct ArchitectureDiagnosticOrderingPolicy {
    public init() {}

    public func ordered(_ diagnostics: [ArchitectureDiagnostic]) -> [ArchitectureDiagnostic] {
        diagnostics.sorted(by: areInIncreasingOrder)
    }

    private func areInIncreasingOrder(lhs: ArchitectureDiagnostic, rhs: ArchitectureDiagnostic) -> Bool {
        if lhs.path != rhs.path {
            return lhs.path < rhs.path
        }
        if lhs.line != rhs.line {
            return lhs.line < rhs.line
        }
        if lhs.column != rhs.column {
            return lhs.column < rhs.column
        }
        if lhs.ruleID != rhs.ruleID {
            return lhs.ruleID < rhs.ruleID
        }
        return lhs.message < rhs.message
    }
}
