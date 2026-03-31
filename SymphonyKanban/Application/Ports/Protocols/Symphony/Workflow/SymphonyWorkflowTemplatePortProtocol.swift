public protocol SymphonyWorkflowTemplatePortProtocol {
    func makeDefinitionContents(
        for scope: SymphonyTrackerScopeOptionContract
    ) throws -> String

    func configuredScopeReference(
        from trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) -> SymphonyTrackerScopeReferenceContract?
}
