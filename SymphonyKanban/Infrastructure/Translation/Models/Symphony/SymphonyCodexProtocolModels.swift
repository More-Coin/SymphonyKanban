import Foundation

enum SymphonyCodexTransportOutputEvent: Sendable {
    case stdout(Data)
    case stderr(Data)
    case exited(Int32)
}

struct SymphonyCodexLaunchConfigurationModel: Equatable, Sendable {
    let command: String
    let currentWorkingDirectoryPath: String
}

struct SymphonyCodexCommandLineModel: Equatable, Sendable {
    private enum Defaults {
        static let shellPath = "/bin/zsh"
    }

    let configuredCommand: String
    let executableToken: String
    let executableName: String
    let shellPath: String
    let shellLookupCommand: String

    init(
        configuredCommand: String,
        shellPath: String?
    ) {
        let normalizedConfiguredCommand = configuredCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedExecutableToken = normalizedConfiguredCommand
            .split(whereSeparator: \.isWhitespace)
            .first
            .map(String.init) ?? "codex"

        self.configuredCommand = normalizedConfiguredCommand
        self.executableToken = normalizedExecutableToken
        self.executableName = URL(fileURLWithPath: normalizedExecutableToken).lastPathComponent
        self.shellPath = Self.normalizedShellPath(from: shellPath)
        self.shellLookupCommand = "command -v \(Self.shellQuoted(normalizedExecutableToken))"
    }

    var absoluteExecutablePath: String? {
        executableToken.hasPrefix("/") ? executableToken : nil
    }

    func reconstructedCommand(
        with executablePath: String
    ) -> String {
        guard let range = configuredCommand.rangeOfCharacter(from: .whitespacesAndNewlines) else {
            return executablePath
        }

        let suffix = String(configuredCommand[range.lowerBound...])
        return executablePath + suffix
    }

    func normalizedResolvedExecutablePath(
        from rawPath: String,
        currentWorkingDirectoryPath: String
    ) -> String? {
        guard rawPath.isEmpty == false else {
            return nil
        }

        if rawPath.hasPrefix("/") {
            return rawPath
        }

        guard rawPath.contains("/") else {
            return nil
        }

        return URL(
            fileURLWithPath: currentWorkingDirectoryPath,
            isDirectory: true
        )
        .appendingPathComponent(rawPath)
        .standardizedFileURL
        .path
    }

    private static func normalizedShellPath(
        from shellPath: String?
    ) -> String {
        guard let shellPath,
              shellPath.hasPrefix("/") else {
            return Defaults.shellPath
        }

        return shellPath
    }

    private static func shellQuoted(
        _ value: String
    ) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

struct SymphonyCodexLineBufferModel {
    private var bufferedData = Data()
    private let maxLineSize: Int

    init(maxLineSize: Int = 10 * 1024 * 1024) {
        self.maxLineSize = maxLineSize
    }

    mutating func append(_ data: Data) throws -> [String] {
        bufferedData.append(data)

        if bufferedData.count > maxLineSize {
            throw SymphonyCodexRunnerInfrastructureError.responseError(
                details: "A protocol line exceeded the maximum supported size."
            )
        }

        var lines: [String] = []

        while let newlineIndex = bufferedData.firstIndex(of: 0x0A) {
            let lineData = bufferedData.prefix(upTo: newlineIndex)
            bufferedData.removeSubrange(...newlineIndex)

            let line = String(data: lineData, encoding: .utf8) ?? ""
            lines.append(line.hasSuffix("\r") ? String(line.dropLast()) : line)
        }

        return lines
    }
}

struct SymphonyCodexCompatibilityRequirementsModel: Equatable, Sendable {
    let allowedApprovalPolicies: Set<String>?
    let allowedSandboxModes: Set<String>?
    let requiresNetworkAccess: Bool
    let requiresAdminAccess: Bool

    static func fromContract(_ result: SymphonyConfigValueContract?) -> Self? {
        guard let requirements = fromContract(requirementsIn: result) else {
            return nil
        }

        if case .null = requirements {
            return nil
        }

        let object = requirements.dictionaryValue ?? [:]
        return Self(
            allowedApprovalPolicies: toContract(stringSetIn: object, keys: ["allowedApprovalPolicies", "allowed_approval_policies"]),
            allowedSandboxModes: toContract(stringSetIn: object, keys: ["allowedSandboxModes", "allowed_sandbox_modes"]),
            requiresNetworkAccess: toContract(boolIn: object, keys: ["networkAccessRequired", "network_access_required", "requiresNetworkAccess", "requires_network_access"]),
            requiresAdminAccess: toContract(boolIn: object, keys: ["adminAccessRequired", "admin_access_required", "requiresAdminAccess", "requires_admin_access"])
        )
    }

    private static func fromContract(
        requirementsIn result: SymphonyConfigValueContract?
    ) -> SymphonyConfigValueContract? {
        if let object = result?.dictionaryValue, let requirements = object["requirements"] {
            return requirements
        }

        return result
    }

    private static func toContract(
        stringSetIn object: [String: SymphonyConfigValueContract],
        keys: [String]
    ) -> Set<String>? {
        for key in keys {
            guard let value = object[key] else {
                continue
            }

            guard case .array(let array) = value else {
                continue
            }

            let strings = array.compactMap(\.stringValue)
            return strings.isEmpty ? [] : Set(strings)
        }

        return nil
    }

    private static func toContract(
        boolIn object: [String: SymphonyConfigValueContract],
        keys: [String]
    ) -> Bool {
        for key in keys {
            guard let value = object[key] else {
                continue
            }

            if case .bool(let bool) = value {
                return bool
            }
        }

        return false
    }
}

struct SymphonyCodexApprovalRequestDecisionModel {
    func fromContract(
        from params: SymphonyConfigValueContract?,
        preferSessionDecision: Bool
    ) -> String {
        let allowedDecisions = fromContract(
            in: params,
            matchingAnyOf: ["allowedDecisions", "availableDecisions", "allowed_decisions", "available_decisions"]
        )

        if preferSessionDecision,
           allowedDecisions.contains("acceptForSession") {
            return "acceptForSession"
        }

        return allowedDecisions.contains("accept") ? "accept" : "accept"
    }

    private func fromContract(
        in value: SymphonyConfigValueContract?,
        matchingAnyOf keys: [String]
    ) -> [String] {
        guard let value else {
            return []
        }

        if case .object(let object) = value {
            for key in keys {
                if case .array(let array)? = object[key] {
                    return array.compactMap(\.stringValue)
                }
            }

            for nested in object.values {
                let values = fromContract(in: nested, matchingAnyOf: keys)
                if !values.isEmpty {
                    return values
                }
            }
        }

        if case .array(let array) = value {
            for item in array {
                let values = fromContract(in: item, matchingAnyOf: keys)
                if !values.isEmpty {
                    return values
                }
            }
        }

        return []
    }
}

struct SymphonyCodexServerDirectiveResponseModel {
    enum Action: Equatable, Sendable {
        case approval(
            requestKind: SymphonyCodexServerRequestKindContract,
            decision: String
        )
        case unsupportedToolCall
        case userInputRequested(code: String, message: String)
        case unhandled
    }

    private let classifier = SymphonyCodexServerDirectiveClassifier()
    private let approvalRequestDecisionModel = SymphonyCodexApprovalRequestDecisionModel()

    func fromMessage(_ message: SymphonyCodexProtocolMessageDTO) -> Action {
        switch classifier.classify(message) {
        case .approval(let requestKind):
            return .approval(
                requestKind: requestKind,
                decision: approvalRequestDecisionModel.fromContract(
                    from: message.params,
                    preferSessionDecision: true
                )
            )
        case .unsupportedToolCall:
            return .unsupportedToolCall
        case .userInputRequested:
            return .userInputRequested(
                code: "turn_input_required",
                message: "Symphony does not support interactive user input."
            )
        case .unhandled:
            return .unhandled
        }
    }
}

struct SymphonyCodexTelemetrySnapshotModel: Equatable, Sendable {
    let usage: SymphonyCodexUsageSnapshotContract?
    let rateLimits: SymphonyCodexRateLimitSnapshotContract?
}

struct SymphonyCodexTelemetryExtractorModel {
    func toContract(from value: SymphonyConfigValueContract?) -> SymphonyCodexTelemetrySnapshotModel {
        SymphonyCodexTelemetrySnapshotModel(
            usage: toContract(usageFrom: value),
            rateLimits: toContract(rateLimitsFrom: value)
        )
    }

    private func toContract(
        usageFrom value: SymphonyConfigValueContract?
    ) -> SymphonyCodexUsageSnapshotContract? {
        guard let object = fromContract(
            objectIn: value,
            containingAnyOf: [
                "inputTokens", "outputTokens", "totalTokens",
                "input_tokens", "output_tokens", "total_tokens"
            ]
        ) else {
            return nil
        }

        let inputTokens = toContract(integerFrom: object["inputTokens"] ?? object["input_tokens"])
        let outputTokens = toContract(integerFrom: object["outputTokens"] ?? object["output_tokens"])
        let totalTokens = toContract(integerFrom: object["totalTokens"] ?? object["total_tokens"])

        guard inputTokens != nil || outputTokens != nil || totalTokens != nil else {
            return nil
        }

        return SymphonyCodexUsageSnapshotContract(
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            totalTokens: totalTokens
        )
    }

    private func toContract(
        rateLimitsFrom value: SymphonyConfigValueContract?
    ) -> SymphonyCodexRateLimitSnapshotContract? {
        guard let payload = fromContract(
            valueIn: value,
            matchingAnyOf: ["rateLimits", "rate_limits"]
        ) else {
            return nil
        }

        return SymphonyCodexRateLimitSnapshotContract(payload: payload)
    }

    private func toContract(integerFrom value: SymphonyConfigValueContract?) -> Int? {
        value?.integerValue
    }

    private func fromContract(
        valueIn value: SymphonyConfigValueContract?,
        matchingAnyOf keys: [String]
    ) -> SymphonyConfigValueContract? {
        guard let value else {
            return nil
        }

        if case .object(let object) = value {
            for key in keys {
                if let direct = object[key] {
                    return direct
                }
            }

            for nestedValue in object.values {
                if let found = fromContract(valueIn: nestedValue, matchingAnyOf: keys) {
                    return found
                }
            }
        }

        if case .array(let array) = value {
            for item in array {
                if let found = fromContract(valueIn: item, matchingAnyOf: keys) {
                    return found
                }
            }
        }

        return nil
    }

    private func fromContract(
        objectIn value: SymphonyConfigValueContract?,
        containingAnyOf keys: [String]
    ) -> [String: SymphonyConfigValueContract]? {
        guard let value else {
            return nil
        }

        if case .object(let object) = value {
            if keys.contains(where: { object[$0] != nil }) {
                return object
            }

            for nestedValue in object.values {
                if let found = fromContract(objectIn: nestedValue, containingAnyOf: keys) {
                    return found
                }
            }
        }

        if case .array(let array) = value {
            for item in array {
                if let found = fromContract(objectIn: item, containingAnyOf: keys) {
                    return found
                }
            }
        }

        return nil
    }
}
