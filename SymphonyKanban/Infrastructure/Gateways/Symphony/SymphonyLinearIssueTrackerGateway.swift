import Foundation

private func symphonyDefaultLinearRequestExecutor(
    _ request: URLRequest
) async throws -> (Data, HTTPURLResponse) {
    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw SymphonyIssueTrackerInfrastructureError.linearUnknownPayload(
            details: "The Linear request did not return an HTTPURLResponse."
        )
    }

    return (data, httpResponse)
}

public struct SymphonyLinearIssueTrackerGateway:
    SymphonyIssueTrackerReadPortProtocol,
    SymphonyTrackerScopeReadPortProtocol,
    @unchecked Sendable
{
    public typealias RequestExecutor = @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

    private static let defaultTimeoutInterval: TimeInterval = 30

    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    private let requestExecutor: RequestExecutor
    private let authorizationProvider: LinearIssueTrackerAuthorizationProvider
    private let configurationModel = LinearTrackerConfigurationModel()
    private let requestDefinitionModel = LinearIssueTrackerRequestDefinitionModel()
    private let requestBuilder = LinearGraphQLTransportRequestBuilder()

    init(
        jsonDecoder: JSONDecoder = JSONDecoder(),
        jsonEncoder: JSONEncoder = JSONEncoder(),
        requestExecutor: @escaping RequestExecutor,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.init(
            jsonDecoder: jsonDecoder,
            jsonEncoder: jsonEncoder,
            requestExecutor: requestExecutor,
            environment: environment,
            secureStore: LinearOAuthSecureStore(),
            oauthGateway: SymphonyLinearOAuthGateway()
        )
    }

    init(
        jsonDecoder: JSONDecoder,
        jsonEncoder: JSONEncoder,
        requestExecutor: @escaping RequestExecutor,
        environment: [String: String],
        secureStore: any LinearOAuthSecureStoreProtocol,
        oauthGateway: any SymphonyTrackerOAuthPortProtocol
    ) {
        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder
        self.requestExecutor = requestExecutor
        self.authorizationProvider = LinearIssueTrackerAuthorizationProvider(
            environment: environment,
            secureStore: secureStore,
            oauthGateway: oauthGateway
        )
    }

    init(
        jsonDecoder: JSONDecoder = JSONDecoder(),
        jsonEncoder: JSONEncoder = JSONEncoder(),
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.init(
            jsonDecoder: jsonDecoder,
            jsonEncoder: jsonEncoder,
            requestExecutor: symphonyDefaultLinearRequestExecutor,
            environment: environment,
            secureStore: LinearOAuthSecureStore(),
            oauthGateway: SymphonyLinearOAuthGateway()
        )
    }

    public func fetchCandidateIssues(
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        let normalizedTracker = try configurationModel.fromContract(from: trackerConfiguration)
        let authorizationHeader = try await authorizationProvider.authorizationHeader()
        var afterCursor: String?
        var issues: [SymphonyIssue] = []

        while true {
            let requestDefinition = requestDefinitionModel.makeCandidateIssuesRequestDefinition(
                using: normalizedTracker,
                authorizationHeader: authorizationHeader,
                afterCursor: afterCursor
            )
            let request = try requestBuilder.makeRequest(
                requestDefinition,
                using: jsonEncoder,
                timeoutInterval: Self.defaultTimeoutInterval
            )
            let response = try await performResponse(for: request)

            guard let connection = response.data?.issues,
                  let nodes = connection.nodes,
                  let pageInfo = connection.pageInfo,
                  let hasNextPage = pageInfo.hasNextPage else {
                throw SymphonyIssueTrackerInfrastructureError.linearUnknownPayload(
                    details: "The issue connection payload was missing `nodes` or `pageInfo`."
                )
            }

            issues.append(contentsOf: try nodes.map { try $0.toDomain() })

            guard hasNextPage else {
                return issues
            }

            guard let endCursor = pageInfo.endCursor?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  !endCursor.isEmpty else {
                throw SymphonyIssueTrackerInfrastructureError.linearMissingEndCursor
            }

            afterCursor = endCursor
        }
    }

    public func fetchIssues(
        byStateTypes stateTypes: [String],
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        let normalizedStateTypes = stateTypes
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !normalizedStateTypes.isEmpty else {
            return []
        }

        let normalizedTracker = try configurationModel.fromContract(from: trackerConfiguration)
        let authorizationHeader = try await authorizationProvider.authorizationHeader()
        var afterCursor: String?
        var issues: [SymphonyIssue] = []

        while true {
            let requestDefinition = requestDefinitionModel.makeIssuesByStatesRequestDefinition(
                using: normalizedTracker,
                authorizationHeader: authorizationHeader,
                stateTypes: normalizedStateTypes,
                afterCursor: afterCursor
            )
            let request = try requestBuilder.makeRequest(
                requestDefinition,
                using: jsonEncoder,
                timeoutInterval: Self.defaultTimeoutInterval
            )
            let response = try await performResponse(for: request)

            guard let connection = response.data?.issues,
                  let nodes = connection.nodes,
                  let pageInfo = connection.pageInfo,
                  let hasNextPage = pageInfo.hasNextPage else {
                throw SymphonyIssueTrackerInfrastructureError.linearUnknownPayload(
                    details: "The issue connection payload was missing `nodes` or `pageInfo`."
                )
            }

            issues.append(contentsOf: try nodes.map { try $0.toDomain() })

            guard hasNextPage else {
                return issues
            }

            guard let endCursor = pageInfo.endCursor?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  !endCursor.isEmpty else {
                throw SymphonyIssueTrackerInfrastructureError.linearMissingEndCursor
            }

            afterCursor = endCursor
        }
    }

    public func fetchIssueStates(
        byIDs issueIDs: [String],
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        let normalizedIssueIDs = issueIDs
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !normalizedIssueIDs.isEmpty else {
            return []
        }

        let normalizedTracker = try configurationModel.fromContract(
            from: trackerConfiguration,
            requireProjectSlug: false
        )
        let authorizationHeader = try await authorizationProvider.authorizationHeader()
        let requestDefinition = requestDefinitionModel.makeIssueStatesByIDsRequestDefinition(
            using: normalizedTracker,
            authorizationHeader: authorizationHeader,
            issueIDs: normalizedIssueIDs
        )
        let request = try requestBuilder.makeRequest(
            requestDefinition,
            using: jsonEncoder,
            timeoutInterval: Self.defaultTimeoutInterval
        )
        let response = try await performResponse(for: request)

        guard let nodes = response.data?.issues?.nodes else {
            throw SymphonyIssueTrackerInfrastructureError.linearUnknownPayload(
                details: "The issue state response was missing `data.issues.nodes`."
            )
        }

        return try nodes.map { try $0.toDomain() }
    }

    public func fetchTeams(
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyTrackerScopeOptionContract] {
        let normalizedTracker = try configurationModel.fromContract(
            from: trackerConfiguration,
            requireProjectSlug: false
        )
        let authorizationHeader = try await authorizationProvider.authorizationHeader()
        let requestDefinition = requestDefinitionModel.makeTeamsRequestDefinition(
            using: normalizedTracker,
            authorizationHeader: authorizationHeader
        )
        let request = try requestBuilder.makeRequest(
            requestDefinition,
            using: jsonEncoder,
            timeoutInterval: Self.defaultTimeoutInterval
        )
        let response = try await performResponse(for: request)

        guard let nodes = response.data?.teams?.nodes else {
            throw SymphonyIssueTrackerInfrastructureError.linearUnknownPayload(
                details: "The team response was missing `data.teams.nodes`."
            )
        }

        return try nodes.map { try $0.toDomain() }
    }

    public func fetchProjects(
        using trackerConfiguration: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyTrackerScopeOptionContract] {
        let normalizedTracker = try configurationModel.fromContract(
            from: trackerConfiguration,
            requireProjectSlug: false
        )
        let authorizationHeader = try await authorizationProvider.authorizationHeader()
        var afterCursor: String?
        var projects: [SymphonyTrackerScopeOptionContract] = []

        while true {
            let requestDefinition = requestDefinitionModel.makeProjectsRequestDefinition(
                using: normalizedTracker,
                authorizationHeader: authorizationHeader,
                afterCursor: afterCursor
            )
            let request = try requestBuilder.makeRequest(
                requestDefinition,
                using: jsonEncoder,
                timeoutInterval: Self.defaultTimeoutInterval
            )
            let response = try await performResponse(for: request)

            guard let connection = response.data?.projects,
                  let nodes = connection.nodes,
                  let pageInfo = connection.pageInfo,
                  let hasNextPage = pageInfo.hasNextPage else {
                throw SymphonyIssueTrackerInfrastructureError.linearUnknownPayload(
                    details: "The project connection payload was missing `nodes` or `pageInfo`."
                )
            }

            projects.append(contentsOf: try nodes.map { try $0.toDomain() })

            guard hasNextPage else {
                return projects
            }

            guard let endCursor = pageInfo.endCursor?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  !endCursor.isEmpty else {
                throw SymphonyIssueTrackerInfrastructureError.linearMissingEndCursor
            }

            afterCursor = endCursor
        }
    }

    private func performResponse(
        for request: URLRequest
    ) async throws -> LinearIssueTrackerResponseModel {
        let data: Data
        let response: HTTPURLResponse

        do {
            (data, response) = try await requestExecutor(request)
        } catch {
            throw SymphonyIssueTrackerInfrastructureError.linearAPIRequest(
                details: error.localizedDescription
            )
        }

        guard (200...299).contains(response.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8)
            throw SymphonyIssueTrackerInfrastructureError.linearAPIStatus(
                statusCode: response.statusCode,
                responseBody: responseBody
            )
        }

        let payload: LinearIssueTrackerResponseModel
        do {
            payload = try jsonDecoder.decode(LinearIssueTrackerResponseModel.self, from: data)
        } catch {
            throw SymphonyIssueTrackerInfrastructureError.linearUnknownPayload(
                details: error.localizedDescription
            )
        }

        if let errors = payload.errors, !errors.isEmpty {
            let messages = errors.compactMap(\.message)
            throw SymphonyIssueTrackerInfrastructureError.linearGraphQLErrors(
                messages: messages.isEmpty ? ["Unknown GraphQL error."] : messages
            )
        }

        return payload
    }
}
