public struct SymphonyIssueCollectionContract: Equatable, Sendable {
    public let bindingResults: [SymphonyIssueCatalogBindingResultContract]
    public let issues: [SymphonyIssue]
    public let activeBindingCount: Int
    public let loadedBindingCount: Int
    public let failedBindingCount: Int

    public init(
        bindingResults: [SymphonyIssueCatalogBindingResultContract],
        issues: [SymphonyIssue]? = nil
    ) {
        self.bindingResults = bindingResults
        self.issues = issues ?? bindingResults.flatMap(\.issues)
        self.activeBindingCount = bindingResults.count
        self.loadedBindingCount = bindingResults.filter { $0.loadState == .loaded }.count
        self.failedBindingCount = bindingResults.filter { $0.loadState == .failed }.count
    }

    public init(issues: [SymphonyIssue]) {
        self.bindingResults = []
        self.issues = issues
        self.activeBindingCount = 0
        self.loadedBindingCount = 0
        self.failedBindingCount = 0
    }
}
