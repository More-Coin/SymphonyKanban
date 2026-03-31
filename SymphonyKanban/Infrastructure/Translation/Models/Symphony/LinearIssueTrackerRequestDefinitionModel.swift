import Foundation

struct LinearIssueTrackerRequestDefinition {
    let endpoint: String
    let authorizationHeader: String
    let operationName: String
    let payload: LinearGraphQLRequestDTO
}

struct LinearIssueTrackerRequestDefinitionModel {
    func makeTeamsRequestDefinition(
        using configuration: LinearNormalizedTrackerConfiguration,
        authorizationHeader: String
    ) -> LinearIssueTrackerRequestDefinition {
        makeRequestDefinition(
            using: configuration,
            authorizationHeader: authorizationHeader,
            operationName: "FetchTeams",
            query: teamsQuery,
            variables: [:]
        )
    }

    func makeProjectsRequestDefinition(
        using configuration: LinearNormalizedTrackerConfiguration,
        authorizationHeader: String,
        afterCursor: String?
    ) -> LinearIssueTrackerRequestDefinition {
        makeRequestDefinition(
            using: configuration,
            authorizationHeader: authorizationHeader,
            operationName: "FetchProjects",
            query: projectsQuery,
            variables: [
                "after": afterCursor.map { .string($0) } ?? .null
            ]
        )
    }

    func makeCandidateIssuesRequestDefinition(
        using configuration: LinearNormalizedTrackerConfiguration,
        authorizationHeader: String,
        afterCursor: String?
    ) -> LinearIssueTrackerRequestDefinition {
        let scopeQuery = issueScopeQueryParts(for: configuration)

        return makeRequestDefinition(
            using: configuration,
            authorizationHeader: authorizationHeader,
            operationName: "FetchCandidateIssues",
            query: candidateIssuesQuery(using: scopeQuery),
            variables: scopeQuery.variables(afterCursor: afterCursor, stateTypes: configuration.activeStateTypes)
        )
    }

    func makeIssuesByStatesRequestDefinition(
        using configuration: LinearNormalizedTrackerConfiguration,
        authorizationHeader: String,
        stateTypes: [String],
        afterCursor: String?
    ) -> LinearIssueTrackerRequestDefinition {
        let scopeQuery = issueScopeQueryParts(for: configuration)

        return makeRequestDefinition(
            using: configuration,
            authorizationHeader: authorizationHeader,
            operationName: "FetchIssuesByStates",
            query: issuesByStatesQuery(using: scopeQuery),
            variables: scopeQuery.variables(afterCursor: afterCursor, stateTypes: stateTypes)
        )
    }

    func makeIssueStatesByIDsRequestDefinition(
        using configuration: LinearNormalizedTrackerConfiguration,
        authorizationHeader: String,
        issueIDs: [String]
    ) -> LinearIssueTrackerRequestDefinition {
        makeRequestDefinition(
            using: configuration,
            authorizationHeader: authorizationHeader,
            operationName: "FetchIssueStatesByIDs",
            query: issueStatesByIDsQuery,
            variables: [
                "issueIds": .stringArray(issueIDs)
            ]
        )
    }

    private func makeRequestDefinition(
        using configuration: LinearNormalizedTrackerConfiguration,
        authorizationHeader: String,
        operationName: String,
        query: String,
        variables: [String: LinearGraphQLVariableDTO]
    ) -> LinearIssueTrackerRequestDefinition {
        LinearIssueTrackerRequestDefinition(
            endpoint: configuration.endpoint,
            authorizationHeader: authorizationHeader,
            operationName: operationName,
            payload: LinearGraphQLRequestDTO(
                query: query,
                variables: variables
            )
        )
    }

    private func candidateIssuesQuery(
        using scopeQuery: LinearIssueScopeQueryParts
    ) -> String {
        """
        query FetchCandidateIssues(\(scopeQuery.operationVariableDeclaration), $stateTypes: [String!], $after: String) {
          issues(
            \(scopeQuery.issueArgumentsClause)
            first: 50
            after: $after
            filter: {
              state: { type: { in: $stateTypes } }
              \(scopeQuery.filterClause)
            }
          ) {
            nodes {
              id
              identifier
              title
              description
              priority
              branchName
              url
              createdAt
              updatedAt
              state { name type }
              labels { nodes { name } }
              inverseRelations {
                nodes {
                  type
                  relatedIssue {
                    id
                    identifier
                    state { name type }
                  }
                }
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
        """
    }

    private func issuesByStatesQuery(
        using scopeQuery: LinearIssueScopeQueryParts
    ) -> String {
        """
        query FetchIssuesByStates(\(scopeQuery.operationVariableDeclaration), $stateTypes: [String!], $after: String) {
          issues(
            \(scopeQuery.issueArgumentsClause)
            first: 50
            after: $after
            filter: {
              state: { type: { in: $stateTypes } }
              \(scopeQuery.filterClause)
            }
          ) {
            nodes {
              id
              identifier
              title
              description
              priority
              branchName
              url
              createdAt
              updatedAt
              state { name type }
              labels { nodes { name } }
              inverseRelations {
                nodes {
                  type
                  relatedIssue {
                    id
                    identifier
                    state { name type }
                  }
                }
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
        """
    }

    private var teamsQuery: String {
        """
        query FetchTeams {
          teams {
            nodes {
              id
              name
              key
            }
          }
        }
        """
    }

    private var projectsQuery: String {
        """
        query FetchProjects($after: String) {
          projects(
            first: 50
            after: $after
            includeArchived: false
          ) {
            nodes {
              id
              name
              slugId
              state
              teams {
                nodes {
                  id
                  name
                  key
                }
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
        """
    }

    private var issueStatesByIDsQuery: String {
        """
        query FetchIssueStatesByIDs($issueIds: [ID!]) {
          issues(
            filter: {
              id: { in: $issueIds }
            }
          ) {
            nodes {
              id
              identifier
              title
              state { name type }
            }
          }
        }
        """
    }

    private func issueScopeQueryParts(
        for configuration: LinearNormalizedTrackerConfiguration
    ) -> LinearIssueScopeQueryParts {
        switch configuration.scope {
        case .project(let slug):
            return LinearIssueScopeQueryParts(
                operationVariableDeclaration: "$projectSlug: String!",
                issueArgumentsClause: "",
                filterClause: "project: { slugId: { eq: $projectSlug } }",
                scopeVariable: ("projectSlug", .string(slug))
            )
        case .team(let id):
            return LinearIssueScopeQueryParts(
                operationVariableDeclaration: "$teamId: ID!",
                issueArgumentsClause: "",
                filterClause: "team: { id: { eq: $teamId } }",
                scopeVariable: ("teamId", .string(id))
            )
        case nil:
            return LinearIssueScopeQueryParts(
                operationVariableDeclaration: "$projectSlug: String!",
                issueArgumentsClause: "",
                filterClause: "project: { slugId: { eq: $projectSlug } }",
                scopeVariable: ("projectSlug", .string(""))
            )
        }
    }
}
