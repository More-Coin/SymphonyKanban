public struct SymphonyIssueCatalogViewModel: Equatable, Sendable {
    public let displayMode: SymphonyIssueCatalogDisplayModeContract
    public let issuesByIdentifier: [String: SymphonyIssue]
    public let boardViewModel: SymphonyKanbanBoardViewModel
    public let listViewModel: SymphonyIssueListViewModel
    public let activeBindingCount: Int
    public let loadedBindingCount: Int
    public let failedBindingCount: Int

    public init(
        displayMode: SymphonyIssueCatalogDisplayModeContract,
        issuesByIdentifier: [String: SymphonyIssue],
        boardViewModel: SymphonyKanbanBoardViewModel,
        listViewModel: SymphonyIssueListViewModel,
        activeBindingCount: Int,
        loadedBindingCount: Int,
        failedBindingCount: Int
    ) {
        self.displayMode = displayMode
        self.issuesByIdentifier = issuesByIdentifier
        self.boardViewModel = boardViewModel
        self.listViewModel = listViewModel
        self.activeBindingCount = activeBindingCount
        self.loadedBindingCount = loadedBindingCount
        self.failedBindingCount = failedBindingCount
    }
}
