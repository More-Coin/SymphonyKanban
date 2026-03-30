public struct SymphonyIssueCatalogBindingResultContract: Equatable, Sendable, Identifiable {
    public let bindingContext: SymphonyActiveWorkspaceBindingContextContract
    public let issues: [SymphonyIssue]
    public let loadState: SymphonyIssueCatalogBindingLoadStateContract
    public let loadError: SymphonyFailureSummaryContract?

    public init(
        bindingContext: SymphonyActiveWorkspaceBindingContextContract,
        issues: [SymphonyIssue],
        loadState: SymphonyIssueCatalogBindingLoadStateContract,
        loadError: SymphonyFailureSummaryContract? = nil
    ) {
        self.bindingContext = bindingContext
        self.issues = issues
        self.loadState = loadState
        self.loadError = loadError
    }

    public var id: String {
        bindingContext.id
    }
}
