public struct SymphonyStartupStatusViewModel: Equatable, Sendable {
    public enum State: String, Equatable, Sendable {
        case ready
        case setupRequired
        case failed
    }

    public let state: State
    public let title: String
    public let message: String
    public let currentWorkingDirectoryPath: String
    public let explicitWorkflowPath: String?
    public let activeBindingCount: Int
    public let readyBindingCount: Int
    public let failedBindingCount: Int
    public let boundScopeNames: [String]
    public let resolvedWorkflowPaths: [String]
    public let trackerStatusLabels: [String]

    public init(
        state: State,
        title: String,
        message: String,
        currentWorkingDirectoryPath: String,
        explicitWorkflowPath: String?,
        activeBindingCount: Int,
        readyBindingCount: Int,
        failedBindingCount: Int,
        boundScopeNames: [String],
        resolvedWorkflowPaths: [String],
        trackerStatusLabels: [String]
    ) {
        self.state = state
        self.title = title
        self.message = message
        self.currentWorkingDirectoryPath = currentWorkingDirectoryPath
        self.explicitWorkflowPath = explicitWorkflowPath
        self.activeBindingCount = activeBindingCount
        self.readyBindingCount = readyBindingCount
        self.failedBindingCount = failedBindingCount
        self.boundScopeNames = boundScopeNames
        self.resolvedWorkflowPaths = resolvedWorkflowPaths
        self.trackerStatusLabels = trackerStatusLabels
    }

    public var isReady: Bool {
        state == .ready
    }

    public var requiresSetup: Bool {
        state == .setupRequired
    }
}
