import Foundation

public struct SymphonyIssueCatalogWorkflowService {
    private let fetchIssuesUseCase: FetchSymphonyIssuesUseCase
    private let updateIssueUseCase: UpdateSymphonyIssueUseCase

    public init(
        fetchIssuesUseCase: FetchSymphonyIssuesUseCase,
        updateIssueUseCase: UpdateSymphonyIssueUseCase
    ) {
        self.fetchIssuesUseCase = fetchIssuesUseCase
        self.updateIssueUseCase = updateIssueUseCase
    }

    @MainActor
    public func queryIssues(
        activeBindings: [SymphonyActiveWorkspaceBindingContextContract]
    ) async throws -> SymphonyIssueCollectionContract {
        var bindingResults: [SymphonyIssueCatalogBindingResultContract] = []
        bindingResults.reserveCapacity(activeBindings.count)

        for bindingContext in activeBindings {
            if bindingContext.isReady == false || bindingContext.workflowConfiguration == nil {
                bindingResults.append(
                    SymphonyIssueCatalogBindingResultContract(
                        bindingContext: bindingContext,
                        issues: [],
                        loadState: .failed,
                        loadError: bindingContext.startupFailure
                    )
                )
                continue
            }

            let trackerConfiguration = bindingContext.workflowConfiguration!.serviceConfig.tracker
            let stateTypes = requestedStateTypes(using: trackerConfiguration)

            do {
                let collection: SymphonyIssueCollectionContract
                if stateTypes.isEmpty {
                    collection = try await fetchIssuesUseCase.fetchCandidateIssues(
                        using: trackerConfiguration
                    )
                } else {
                    collection = try await fetchIssuesUseCase.fetchIssues(
                        stateTypes: stateTypes,
                        using: trackerConfiguration
                    )
                }

                bindingResults.append(
                    SymphonyIssueCatalogBindingResultContract(
                        bindingContext: bindingContext,
                        issues: collection.issues,
                        loadState: .loaded
                    )
                )
            } catch {
                bindingResults.append(
                    SymphonyIssueCatalogBindingResultContract(
                        bindingContext: bindingContext,
                        issues: [],
                        loadState: .failed,
                        loadError: failureSummary(from: error)
                    )
                )
            }
        }

        return SymphonyIssueCollectionContract(bindingResults: bindingResults)
    }

    @MainActor
    public func updateIssue(
        _ request: SymphonyIssueUpdateRequestContract,
        activeBindings: [SymphonyActiveWorkspaceBindingContextContract]
    ) async throws -> SymphonyIssueCollectionContract {
        guard request.stateChange != nil else {
            throw SymphonyIssueUpdateApplicationError.missingStateChange(
                issueIdentifier: request.issueIdentifier
            )
        }

        let updateContext = try await resolveUpdateContext(
            issueIdentifier: request.issueIdentifier,
            activeBindings: activeBindings
        )

        _ = try await updateIssueUseCase.updateIssue(
            request,
            currentIssue: updateContext.issue,
            using: updateContext.trackerConfiguration
        )

        return try await queryIssues(activeBindings: activeBindings)
    }

    @MainActor
    public func cancelIssue(
        issueIdentifier: String,
        activeBindings: [SymphonyActiveWorkspaceBindingContextContract]
    ) async throws -> SymphonyIssueCollectionContract {
        let updateContext = try await resolveUpdateContext(
            issueIdentifier: issueIdentifier,
            activeBindings: activeBindings
        )

        guard isTerminal(issue: updateContext.issue) == false else {
            throw SymphonyIssueUpdateApplicationError.issueAlreadyTerminal(
                issueIdentifier: issueIdentifier,
                stateType: updateContext.issue.stateType
            )
        }

        _ = try await updateIssueUseCase.updateIssue(
            SymphonyIssueUpdateRequestContract(
                issueIdentifier: issueIdentifier,
                stateChange: SymphonyIssueStateChangeContract(targetStateType: "canceled")
            ),
            currentIssue: updateContext.issue,
            using: updateContext.trackerConfiguration
        )

        return try await queryIssues(activeBindings: activeBindings)
    }

    private func failureSummary(
        from error: any Error
    ) -> SymphonyFailureSummaryContract {
        if let structuredError = error as? any StructuredErrorProtocol {
            return SymphonyFailureSummaryContract(
                message: structuredError.message,
                details: structuredError.details
            )
        }

        return SymphonyFailureSummaryContract(message: error.localizedDescription)
    }

    private func requestedStateTypes(
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) -> [String] {
        var ordered: [String] = []
        var seen = Set<String>()

        for stateType in trackerConfiguration.activeStateTypes + trackerConfiguration.terminalStateTypes {
            let normalized = trackerConfiguration.normalizedStateType(stateType)
            guard normalized.isEmpty == false,
                  seen.insert(normalized).inserted else {
                continue
            }

            ordered.append(stateType)
        }

        return ordered
    }

    private func isTerminal(issue: SymphonyIssue) -> Bool {
        let normalizedState = normalize(issue.state)
        let normalizedStateType = normalize(issue.stateType)

        return normalizedState.contains("done")
            || normalizedState.contains("complete")
            || normalizedState.contains("cancel")
            || normalizedStateType.contains("complete")
            || normalizedStateType.contains("cancel")
    }

    private func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
    }

    @MainActor
    private func resolveUpdateContext(
        issueIdentifier: String,
        activeBindings: [SymphonyActiveWorkspaceBindingContextContract]
    ) async throws -> (
        issue: SymphonyIssue,
        trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) {
        let currentCollection = try await queryIssues(activeBindings: activeBindings)
        let targetBindingResult = currentCollection.bindingResults.first { bindingResult in
            bindingResult.issues.contains { $0.identifier == issueIdentifier }
        }

        guard let targetBindingResult,
              let currentIssue = targetBindingResult.issues.first(where: { $0.identifier == issueIdentifier }),
              let trackerConfiguration = targetBindingResult.bindingContext.workflowConfiguration?.serviceConfig.tracker else {
            throw SymphonyIssueUpdateApplicationError.issueNotFound(
                issueIdentifier: issueIdentifier
            )
        }

        return (currentIssue, trackerConfiguration)
    }
}

public typealias SymphonyIssueCatalogService = SymphonyIssueCatalogWorkflowService
