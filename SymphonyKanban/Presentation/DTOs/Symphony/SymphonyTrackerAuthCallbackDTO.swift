import Foundation

public struct SymphonyTrackerAuthCallbackDTO {
    private let callbackURL: URL

    public init(callbackURL: URL) {
        self.callbackURL = callbackURL
    }

    public func callbackContract(
        trackerKind fallbackTrackerKind: String
    ) throws -> SymphonyTrackerAuthCallbackContract {
        guard let components = URLComponents(
            url: callbackURL,
            resolvingAgainstBaseURL: false
        ) else {
            throw SymphonyTrackerAuthPresentationError.invalidCallbackURL
        }

        let queryItems = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { item in
                (item.name, item.value ?? "")
            }
        )

        let trackerKind = resolvedTrackerKind(
            host: components.host,
            path: components.path,
            fallbackTrackerKind: fallbackTrackerKind
        )

        guard trackerKind.isEmpty == false else {
            throw SymphonyTrackerAuthPresentationError.invalidCallbackURL
        }

        return SymphonyTrackerAuthCallbackContract(
            trackerKind: trackerKind,
            authorizationCode: normalized(queryItems["code"]),
            state: normalized(queryItems["state"]),
            errorCode: normalized(queryItems["error"]),
            errorDescription: normalized(queryItems["error_description"])
        )
    }

    private func resolvedTrackerKind(
        host: String?,
        path: String,
        fallbackTrackerKind: String
    ) -> String {
        if let host = normalized(host),
           host == "linear" {
            return host
        }

        let pathTrackerKind = path
            .split(separator: "/")
            .map(String.init)
            .first {
                normalized($0) == "linear"
            }

        if let pathTrackerKind {
            return pathTrackerKind
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
        }

        return fallbackTrackerKind
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func normalized(
        _ value: String?
    ) -> String? {
        guard let value = value?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }

        return value
    }
}
