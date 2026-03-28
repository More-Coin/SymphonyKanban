import Foundation
import Network

struct LinearOAuthLoopbackHTTPResponseDTO {
    let statusCode: Int
    let body: String
    let callbackResult: Result<SymphonyTrackerAuthCallbackContract, Error>
}

struct LinearOAuthLoopbackCallbackTransportParser {
    func parseCallback(
        data: Data?,
        error: NWError?
    ) -> Result<SymphonyTrackerAuthCallbackContract, Error> {
        if let error {
            return .failure(
                SymphonyTrackerAuthPresentationError.callbackListenerFailed(
                    details: error.localizedDescription
                )
            )
        }

        guard let data,
              let request = String(data: data, encoding: .utf8),
              let requestLine = request.components(separatedBy: "\r\n").first else {
            return .failure(SymphonyTrackerAuthPresentationError.invalidCallbackURL)
        }

        let parts = requestLine.split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count >= 2,
              parts[0] == "GET" else {
            return .failure(SymphonyTrackerAuthPresentationError.invalidCallbackURL)
        }

        let requestTarget = String(parts[1])
        guard let components = URLComponents(
            string: "http://\(LinearOAuthLoopbackConfiguration.host):\(LinearOAuthLoopbackConfiguration.port)\(requestTarget)"
        ),
        components.path == LinearOAuthLoopbackConfiguration.path else {
            return .failure(SymphonyTrackerAuthPresentationError.invalidCallbackURL)
        }

        let queryItems = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )

        return .success(
            SymphonyTrackerAuthCallbackContract(
                trackerKind: "linear",
                authorizationCode: normalized(queryItems["code"]),
                state: normalized(queryItems["state"]),
                errorCode: normalized(queryItems["error"]),
                errorDescription: normalized(queryItems["error_description"])
            )
        )
    }

    private func normalized(
        _ value: String?
    ) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }

        return value
    }
}

struct LinearOAuthLoopbackHTTPResponseBuilder {
    func makeResponse(
        from callbackResult: Result<SymphonyTrackerAuthCallbackContract, Error>
    ) -> LinearOAuthLoopbackHTTPResponseDTO {
        switch callbackResult {
        case .success:
            return LinearOAuthLoopbackHTTPResponseDTO(
                statusCode: 200,
                body: """
                <!DOCTYPE html>
                <html lang="en">
                <head>
                  <meta charset="utf-8">
                  <title>Symphony Connected</title>
                </head>
                <body>
                  <h1>Linear authorization received</h1>
                  <p>You can close this tab and return to Symphony.</p>
                </body>
                </html>
                """,
                callbackResult: callbackResult
            )
        case .failure:
            return LinearOAuthLoopbackHTTPResponseDTO(
                statusCode: 400,
                body: """
                <!DOCTYPE html>
                <html lang="en">
                <head>
                  <meta charset="utf-8">
                  <title>Symphony Authorization Failed</title>
                </head>
                <body>
                  <h1>Linear authorization failed</h1>
                  <p>Return to Symphony and try connecting again.</p>
                </body>
                </html>
                """,
                callbackResult: callbackResult
            )
        }
    }
}
