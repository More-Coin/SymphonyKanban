import Foundation

public struct SymphonyIssueCatalogService {
    private let fetchIssuesUseCase: FetchSymphonyIssuesUseCase

    public init(
        fetchIssuesUseCase: FetchSymphonyIssuesUseCase
    ) {
        self.fetchIssuesUseCase = fetchIssuesUseCase
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
}
