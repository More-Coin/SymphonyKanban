import Foundation

public struct SymphonyMockIssueTrackerPortAdapter: SymphonyIssueTrackerPortProtocol, Sendable {
    public init() {}

    public func fetchCandidateIssues(
        using _: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        Self.mockIssues
    }

    public func fetchIssues(
        byStateTypes _: [String],
        using _: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        Self.mockIssues
    }

    public func fetchIssueStates(
        byIDs issueIDs: [String],
        using _: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        let normalizedIssueIDs = Set(
            issueIDs.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        )
        guard normalizedIssueIDs.isEmpty == false else {
            return []
        }

        return Self.mockIssues.filter {
            normalizedIssueIDs.contains($0.id) || normalizedIssueIDs.contains($0.identifier)
        }
    }

    public func updateIssue(
        _ request: SymphonyIssueUpdateRequestContract,
        currentIssue: SymphonyIssue,
        using _: SymphonyServiceConfigContract.Tracker
    ) async throws -> SymphonyIssueUpdateResultContract {
        _ = currentIssue

        guard let stateChange = request.stateChange else {
            throw SymphonyIssueUpdateApplicationError.missingStateChange(
                issueIdentifier: request.issueIdentifier
            )
        }

        let matchedIssue = Self.mockIssues.first {
            $0.identifier == request.issueIdentifier || $0.id == request.issueIdentifier
        }

        guard let matchedIssue else {
            throw SymphonyIssueUpdateApplicationError.issueNotFound(
                issueIdentifier: request.issueIdentifier
            )
        }

        return SymphonyIssueUpdateResultContract(
            issueID: matchedIssue.id,
            issueIdentifier: matchedIssue.identifier,
            appliedStateID: "mock-\(stateChange.targetStateType)"
        )
    }

    static let mockIssues: [SymphonyIssue] = [
        SymphonyIssue(
            id: "issue-130",
            identifier: "KAN-130",
            title: "Scaffold clean architecture layer boundaries",
            description: "Lay down the initial layer seams and guardrails for the Symphony feature set.",
            priority: 1,
            state: "Done",
            stateType: "completed",
            branchName: nil,
            url: "https://linear.app/example/KAN-130",
            labels: ["infra"],
            blockedBy: [],
            createdAt: nil,
            updatedAt: nil
        ),
        SymphonyIssue(
            id: "issue-135",
            identifier: "KAN-135",
            title: "Set up design token system",
            description: "Introduce shared typography, spacing, and color tokens for the new UI surfaces.",
            priority: 2,
            state: "Done",
            stateType: "completed",
            branchName: nil,
            url: "https://linear.app/example/KAN-135",
            labels: ["symphony"],
            blockedBy: [],
            createdAt: nil,
            updatedAt: nil
        ),
        SymphonyIssue(
            id: "issue-142",
            identifier: "KAN-142",
            title: "Rebuild Symphony dashboard pipeline",
            description: "Rebuild the dashboard presentation slice around controller, presenter, and page-level view models.",
            priority: 2,
            state: "Doing",
            stateType: "started",
            branchName: "feature/dashboard-pipeline",
            url: "https://linear.app/example/KAN-142",
            labels: ["symphony", "dashboard"],
            blockedBy: [],
            createdAt: nil,
            updatedAt: nil
        ),
        SymphonyIssue(
            id: "issue-177",
            identifier: "KAN-177",
            title: "Wire issue detail renderer",
            description: "Shape runtime detail output through a dedicated presenter and renderer pair.",
            priority: 3,
            state: "Review",
            stateType: "started",
            branchName: "feature/issue-detail-renderer",
            url: "https://linear.app/example/KAN-177",
            labels: ["symphony", "detail"],
            blockedBy: [],
            createdAt: nil,
            updatedAt: nil
        ),
        SymphonyIssue(
            id: "issue-181",
            identifier: "KAN-181",
            title: "Harden refresh route selection handling",
            description: "Tighten route refresh behavior so selection survives state reloads.",
            priority: 2,
            state: "Blocked",
            stateType: "started",
            branchName: "feature/refresh-selection",
            url: "https://linear.app/example/KAN-181",
            labels: ["symphony", "refresh"],
            blockedBy: [],
            createdAt: nil,
            updatedAt: nil
        ),
        SymphonyIssue(
            id: "issue-190",
            identifier: "KAN-190",
            title: "Add kanban column drag-and-drop reordering",
            description: "Support manual reordering across board columns with drag-and-drop interactions.",
            priority: 1,
            state: "Ready",
            stateType: "unstarted",
            branchName: nil,
            url: "https://linear.app/example/KAN-190",
            labels: ["kanban", "ux"],
            blockedBy: [],
            createdAt: nil,
            updatedAt: nil
        ),
        SymphonyIssue(
            id: "issue-195",
            identifier: "KAN-195",
            title: "Implement sidebar navigation collapse",
            description: "Allow the Symphony sidebar to collapse cleanly on narrower layouts.",
            priority: 4,
            state: "Backlog",
            stateType: "backlog",
            branchName: nil,
            url: "https://linear.app/example/KAN-195",
            labels: ["navigation"],
            blockedBy: [],
            createdAt: nil,
            updatedAt: nil
        ),
        SymphonyIssue(
            id: "issue-198",
            identifier: "KAN-198",
            title: "Wire agent health-check heartbeat endpoint",
            description: "Publish a heartbeat endpoint so the UI can monitor agent health in near real time.",
            priority: 2,
            state: "Ready",
            stateType: "unstarted",
            branchName: nil,
            url: "https://linear.app/example/KAN-198",
            labels: ["symphony", "infra"],
            blockedBy: [],
            createdAt: nil,
            updatedAt: nil
        ),
        SymphonyIssue(
            id: "issue-200",
            identifier: "KAN-200",
            title: "Design token color contrast audit",
            description: "Audit the design token palette to ensure contrast stays accessible across the app.",
            priority: 3,
            state: "Done",
            stateType: "completed",
            branchName: nil,
            url: "https://linear.app/example/KAN-200",
            labels: ["design", "a11y"],
            blockedBy: [],
            createdAt: nil,
            updatedAt: nil
        ),
        SymphonyIssue(
            id: "issue-205",
            identifier: "KAN-205",
            title: "Add rate limit backpressure to runtime loop",
            description: "Teach the runtime scheduler to back off when upstream rate limits are getting tight.",
            priority: 1,
            state: "In Progress",
            stateType: "started",
            branchName: nil,
            url: "https://linear.app/example/KAN-205",
            labels: ["runtime", "reliability"],
            blockedBy: [],
            createdAt: nil,
            updatedAt: nil
        ),
        SymphonyIssue(
            id: "issue-210",
            identifier: "KAN-210",
            title: "Create agent management dashboard view",
            description: "Add the management surface for tracking assigned agents and their capabilities.",
            priority: 2,
            state: "Ready",
            stateType: "unstarted",
            branchName: nil,
            url: "https://linear.app/example/KAN-210",
            labels: ["agents", "dashboard"],
            blockedBy: [],
            createdAt: nil,
            updatedAt: nil
        ),
        SymphonyIssue(
            id: "issue-215",
            identifier: "KAN-215",
            title: "Integrate Linear webhook for real-time updates",
            description: "Handle webhook deliveries so Symphony reacts to Linear issue changes without polling alone.",
            priority: 3,
            state: "Backlog",
            stateType: "backlog",
            branchName: nil,
            url: "https://linear.app/example/KAN-215",
            labels: ["linear", "integration"],
            blockedBy: [],
            createdAt: nil,
            updatedAt: nil
        ),
        SymphonyIssue(
            id: "issue-220",
            identifier: "KAN-220",
            title: "Fix retry queue exponential backoff timing",
            description: "Correct the retry schedule so repeated failures respect the configured backoff policy.",
            priority: 2,
            state: "Done",
            stateType: "completed",
            branchName: nil,
            url: "https://linear.app/example/KAN-220",
            labels: ["runtime", "bugfix"],
            blockedBy: [],
            createdAt: nil,
            updatedAt: nil
        )
    ]
}
