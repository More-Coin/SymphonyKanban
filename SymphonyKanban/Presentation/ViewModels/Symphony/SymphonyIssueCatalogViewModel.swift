public struct SymphonyIssueCatalogViewModel: Equatable, Sendable {
    public let issuesByIdentifier: [String: SymphonyIssue]
    public let boardViewModel: SymphonyKanbanBoardViewModel
    public let listViewModel: SymphonyIssueListViewModel

    public init(
        issuesByIdentifier: [String: SymphonyIssue],
        boardViewModel: SymphonyKanbanBoardViewModel,
        listViewModel: SymphonyIssueListViewModel
    ) {
        self.issuesByIdentifier = issuesByIdentifier
        self.boardViewModel = boardViewModel
        self.listViewModel = listViewModel
    }
}
