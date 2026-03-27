import Foundation
@testable import SymphonyKanban

enum SymphonyLinearIssueTrackerGatewayTestSupport {
    static func trackerConfiguration() -> SymphonyServiceConfigContract.Tracker {
        SymphonyServiceConfigContract.Tracker(
            kind: "linear",
            endpoint: "https://api.linear.app/graphql",
            apiKey: "linear-token",
            projectSlug: "project-slug",
            activeStates: ["Todo", "In Progress"],
            terminalStates: ["Done", "Canceled"]
        )
    }

    static func httpResponse(statusCode: Int, body: String) -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(
            url: URL(string: "https://api.linear.app/graphql")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!

        return (Data(body.utf8), response)
    }

    static func requestBody(_ request: URLRequest) throws -> (query: String, variables: [String: Any]) {
        enum InvalidRequestBody: Error {
            case missingBody
            case invalidObject
            case missingQuery
            case missingVariables
        }

        guard let body = request.httpBody else {
            throw InvalidRequestBody.missingBody
        }

        guard let object = try JSONSerialization.jsonObject(with: body) as? [String: Any] else {
            throw InvalidRequestBody.invalidObject
        }

        guard let query = object["query"] as? String else {
            throw InvalidRequestBody.missingQuery
        }

        guard let variables = object["variables"] as? [String: Any] else {
            throw InvalidRequestBody.missingVariables
        }

        return (query, variables)
    }

    static func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: value)!
    }
}

actor LinearRequestExecutorSpy {
    private var remainingResults: [Result<(Data, HTTPURLResponse), Error>]
    private var recordedRequests: [URLRequest] = []

    init(results: [Result<(Data, HTTPURLResponse), Error>]) {
        self.remainingResults = results
    }

    func execute(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        recordedRequests.append(request)

        guard !remainingResults.isEmpty else {
            struct UnexpectedRequestError: Error {}
            throw UnexpectedRequestError()
        }

        return try remainingResults.removeFirst().get()
    }

    func requests() -> [URLRequest] {
        recordedRequests
    }
}
