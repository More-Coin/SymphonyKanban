public struct SymphonyWorkspaceSelectionViewModel: Equatable {
    public enum State: Equatable {
        case idle
        case selected
        case failed
    }

    public struct Selection: Equatable, Identifiable {
        public let id: String
        public let workspacePath: String
        public let explicitWorkflowPath: String?
        public let resolvedWorkflowPath: String
        public let workspaceName: String

        public init(
            id: String,
            workspacePath: String,
            explicitWorkflowPath: String?,
            resolvedWorkflowPath: String,
            workspaceName: String
        ) {
            self.id = id
            self.workspacePath = workspacePath
            self.explicitWorkflowPath = explicitWorkflowPath
            self.resolvedWorkflowPath = resolvedWorkflowPath
            self.workspaceName = workspaceName
        }
    }

    public let state: State
    public let title: String
    public let message: String
    public let selection: Selection?
    public let errorMessage: String?

    public init(
        state: State,
        title: String,
        message: String,
        selection: Selection? = nil,
        errorMessage: String? = nil
    ) {
        self.state = state
        self.title = title
        self.message = message
        self.selection = selection
        self.errorMessage = errorMessage
    }
}
