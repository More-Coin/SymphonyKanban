import Foundation

public struct SymphonyIssueDispatchOrderingPolicy: SymphonyIssueDispatchOrderingPolicyProtocol {
    public init() {}

    public func ordered(_ issues: [SymphonyIssue]) -> [SymphonyIssue] {
        issues.sorted(by: areInIncreasingOrder)
    }

    private func areInIncreasingOrder(lhs: SymphonyIssue, rhs: SymphonyIssue) -> Bool {
        if lhs.priority != rhs.priority {
            return comparePriorities(lhs.priority, rhs.priority)
        }

        if lhs.createdAt != rhs.createdAt {
            return compareCreatedDates(lhs.createdAt, rhs.createdAt)
        }

        if lhs.identifier != rhs.identifier {
            return lhs.identifier < rhs.identifier
        }

        return lhs.id < rhs.id
    }

    private func comparePriorities(_ lhs: Int?, _ rhs: Int?) -> Bool {
        switch (lhs, rhs) {
        case let (left?, right?):
            return left < right
        case (.some, nil):
            return true
        case (nil, .some):
            return false
        case (nil, nil):
            return false
        }
    }

    private func compareCreatedDates(_ lhs: Date?, _ rhs: Date?) -> Bool {
        switch (lhs, rhs) {
        case let (left?, right?):
            return left < right
        case (.some, nil):
            return true
        case (nil, .some):
            return false
        case (nil, nil):
            return false
        }
    }
}
