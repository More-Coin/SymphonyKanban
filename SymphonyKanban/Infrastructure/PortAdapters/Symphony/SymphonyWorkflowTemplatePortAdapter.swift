import Foundation

public struct SymphonyWorkflowTemplatePortAdapter: SymphonyWorkflowTemplatePortProtocol {
    public init() {}

    public func makeDefinitionContents(
        for scope: SymphonyTrackerScopeOptionContract
    ) throws -> String {
        let normalizedScopeKind = scope.scopeKind
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let normalizedScopeIdentifier = scope.scopeIdentifier
            .trimmingCharacters(in: .whitespacesAndNewlines)

        switch normalizedScopeKind {
        case "project":
            return """
            ---
            tracker:
              kind: linear
              project_slug: \(normalizedScopeIdentifier)
            ---
            You are working on an issue from Linear.
            """
        case "team":
            return """
            ---
            tracker:
              kind: linear
              team_id: \(normalizedScopeIdentifier)
            ---
            You are working on an issue from Linear.
            """
        default:
            throw SymphonyWorkspaceSelectionApplicationError.unsupportedScopeKind(
                actualKind: normalizedScopeKind
            )
        }
    }

    public func configuredScopeReference(
        from trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) -> SymphonyTrackerScopeReferenceContract? {
        if let projectSlug = trackerConfiguration.projectSlug?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           projectSlug.isEmpty == false {
            return SymphonyTrackerScopeReferenceContract(
                scopeKind: "project",
                scopeIdentifier: projectSlug
            )
        }

        if let teamID = trackerConfiguration.teamID?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           teamID.isEmpty == false {
            return SymphonyTrackerScopeReferenceContract(
                scopeKind: "team",
                scopeIdentifier: teamID
            )
        }

        return nil
    }
}
