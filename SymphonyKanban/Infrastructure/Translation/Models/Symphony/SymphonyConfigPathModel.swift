import Foundation

struct SymphonyConfigPathModel {
    let environment: [String: String]

    func normalizedConfigAPIKey(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        if let expanded = environmentString(from: value) {
            return expanded.isEmpty ? nil : expanded
        }

        return value.isEmpty ? nil : value
    }

    func normalizedConfigWorkspaceRoot(_ value: String?) -> String? {
        guard let value,
              let expanded = pathLikeValue(from: value),
              !expanded.isEmpty else {
            return nil
        }

        return expanded
    }

    private func environmentString(from value: String) -> String? {
        guard value.hasPrefix("$") else {
            return nil
        }

        let variableName = String(value.dropFirst())
        return environment[variableName]
    }

    private func pathLikeValue(from value: String) -> String? {
        let environmentExpanded = environmentString(from: value) ?? value
        guard !environmentExpanded.isEmpty else {
            return nil
        }

        if environmentExpanded == "~" {
            return NSHomeDirectory()
        }

        if environmentExpanded.hasPrefix("~/") {
            return NSString(string: environmentExpanded).replacingCharacters(
                in: NSRange(location: 0, length: 1),
                with: NSHomeDirectory()
            )
        }

        if environmentExpanded.contains("/") || environmentExpanded.contains("\\") {
            return URL(fileURLWithPath: environmentExpanded).standardizedFileURL.path
        }

        return environmentExpanded
    }
}
