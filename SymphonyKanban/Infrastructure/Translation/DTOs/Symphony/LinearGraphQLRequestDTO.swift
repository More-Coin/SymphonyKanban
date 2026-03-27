import Foundation

struct LinearGraphQLRequestDTO: Sendable {
    let query: String
    let variables: [String: LinearGraphQLVariableDTO]
}

enum LinearGraphQLVariableDTO: Sendable {
    case string(String)
    case stringArray([String])
    case null
}

struct LinearGraphQLTransportRequestBuilder {
    func makeRequest(
        _ requestDefinition: LinearIssueTrackerRequestDefinition,
        using jsonEncoder: JSONEncoder,
        timeoutInterval: TimeInterval
    ) throws -> URLRequest {
        guard let url = URL(string: requestDefinition.endpoint) else {
            throw SymphonyIssueTrackerInfrastructureError.linearAPIRequest(
                details: "The Linear endpoint URL is invalid: \(requestDefinition.endpoint)"
            )
        }

        let body = try jsonEncoder.encode(
            LinearGraphQLTransportPayload(from: requestDefinition.payload)
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(requestDefinition.authorizationHeader, forHTTPHeaderField: "Authorization")
        request.setValue(requestDefinition.operationName, forHTTPHeaderField: "X-GraphQL-Operation-Name")
        request.httpBody = body
        return request
    }
}

private struct LinearGraphQLTransportPayload: Encodable, Sendable {
    let query: String
    let variables: [String: LinearGraphQLTransportVariable]

    init(from request: LinearGraphQLRequestDTO) {
        self.query = request.query
        self.variables = request.variables.mapValues(LinearGraphQLTransportVariable.init)
    }
}

private enum LinearGraphQLTransportVariable: Encodable, Sendable {
    case string(String)
    case stringArray([String])
    case null

    init(_ value: LinearGraphQLVariableDTO) {
        switch value {
        case .string(let string):
            self = .string(string)
        case .stringArray(let values):
            self = .stringArray(values)
        case .null:
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .stringArray(let values):
            try container.encode(values)
        case .null:
            try container.encodeNil()
        }
    }
}
