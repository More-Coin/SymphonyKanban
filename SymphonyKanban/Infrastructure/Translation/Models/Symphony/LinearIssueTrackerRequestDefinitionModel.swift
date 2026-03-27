import Foundation

struct LinearIssueTrackerRequestDefinition {
    let endpoint: String
    let authorizationHeader: String
    let operationName: String
    let payload: LinearGraphQLRequestDTO
}

struct LinearIssueTrackerRequestDefinitionModel {
    func makeCandidateIssuesRequestDefinition(
        using configuration: LinearNormalizedTrackerConfiguration,
        authorizationHeader: String,
        afterCursor: String?
    ) -> LinearIssueTrackerRequestDefinition {
        makeRequestDefinition(
            using: configuration,
            authorizationHeader: authorizationHeader,
            operationName: "FetchCandidateIssues",
            query: candidateIssuesQuery,
            variables: [
                "projectSlug": .string(configuration.projectSlug),
                "stateTypes": .stringArray(configuration.activeStateTypes),
                "after": afterCursor.map { .string($0) } ?? .null
            ]
        )
    }

    func makeIssuesByStatesRequestDefinition(
        using configuration: LinearNormalizedTrackerConfiguration,
        authorizationHeader: String,
        stateTypes: [String],
        afterCursor: String?
    ) -> LinearIssueTrackerRequestDefinition {
        makeRequestDefinition(
            using: configuration,
            authorizationHeader: authorizationHeader,
            operationName: "FetchIssuesByStates",
            query: issuesByStatesQuery,
            variables: [
                "projectSlug": .string(configuration.projectSlug),
                "stateTypes": .stringArray(stateTypes),
                "after": afterCursor.map { .string($0) } ?? .null
            ]
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

    private var candidateIssuesQuery: String {
        """
        query FetchCandidateIssues($projectSlug: String!, $stateTypes: [String!], $after: String) {
          issues(
            first: 50
            after: $after
            filter: {
              state: { type: { in: $stateTypes } }
              project: { slugId: { eq: $projectSlug } }
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

    private var issuesByStatesQuery: String {
        """
        query FetchIssuesByStates($projectSlug: String!, $stateTypes: [String!], $after: String) {
          issues(
            first: 50
            after: $after
            filter: {
              state: { type: { in: $stateTypes } }
              project: { slugId: { eq: $projectSlug } }
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
}
