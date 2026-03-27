public struct SymphonyWorkspaceKeyPolicy {
    public init() {}

    public func makeWorkspaceKey(from issueIdentifier: String) -> SymphonyWorkspaceKey {
        let sanitizedScalars = issueIdentifier.unicodeScalars.map { scalar -> Character in
            if isAllowedWorkspaceScalar(scalar) {
                return Character(scalar)
            }

            return "_"
        }

        return SymphonyWorkspaceKey(value: String(sanitizedScalars))
    }

    private func isAllowedWorkspaceScalar(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 48...57, 65...90, 97...122:
            return true
        case 45, 46, 95:
            return true
        default:
            return false
        }
    }
}
