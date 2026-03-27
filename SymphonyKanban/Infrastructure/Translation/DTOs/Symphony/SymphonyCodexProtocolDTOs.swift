import Foundation

typealias SymphonyCodexJSONRPCIdentifierDTO = SymphonyCodexJSONRPCIdentifierCarrier

nonisolated struct SymphonyCodexJSONRPCIdentifierCarrier: Encodable, Equatable, Sendable {
    fileprivate let wireValue: SymphonyCodexJSONRPCIdentifierWireValue

    init(integer: Int) {
        self.wireValue = .integer(integer)
    }

    init(string: String) {
        self.wireValue = .string(string)
    }

    func encode(to encoder: Encoder) throws {
        try wireValue.encode(to: encoder)
    }
}

nonisolated private enum SymphonyCodexJSONRPCIdentifierWireValue: Encodable, Equatable, Sendable {
    case integer(Int)
    case string(String)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .integer(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}

typealias SymphonyCodexJSONValueDTO = SymphonyCodexJSONValueCarrier

nonisolated struct SymphonyCodexJSONValueCarrier: Encodable, Equatable, Sendable {
    fileprivate let wireValue: SymphonyCodexJSONValueWireValue

    init(_ value: SymphonyConfigValueContract) {
        self.wireValue = SymphonyCodexJSONValueWireValue(value)
    }

    func encode(to encoder: Encoder) throws {
        try wireValue.encode(to: encoder)
    }
}

nonisolated private enum SymphonyCodexJSONValueWireValue: Encodable, Equatable, Sendable {
    case string(String)
    case integer(Int)
    case double(Double)
    case bool(Bool)
    case array([SymphonyCodexJSONValueWireValue])
    case object([String: SymphonyCodexJSONValueWireValue])
    case null

    init(_ value: SymphonyConfigValueContract) {
        switch value {
        case .string(let string):
            self = .string(string)
        case .integer(let integer):
            self = .integer(integer)
        case .double(let double):
            self = .double(double)
        case .bool(let bool):
            self = .bool(bool)
        case .array(let array):
            self = .array(array.map(Self.init))
        case .object(let object):
            self = .object(object.mapValues(Self.init))
        case .null:
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value):
            try container.encode(value)
        case .integer(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

nonisolated struct SymphonyCodexJSONRPCRequestDTO<Params: Encodable & Sendable>: Encodable, Sendable {
    let id: Int
    let method: String
    let params: Params
}

nonisolated struct SymphonyCodexJSONRPCNotificationDTO<Params: Encodable & Sendable>: Encodable, Sendable {
    let method: String
    let params: Params
}

nonisolated struct SymphonyCodexJSONRPCResultResponseDTO<Result: Encodable & Sendable>: Encodable, Sendable {
    let id: SymphonyCodexJSONRPCIdentifierDTO
    let result: Result
}

nonisolated struct SymphonyCodexJSONRPCErrorResponseDTO: Encodable, Sendable {
    nonisolated struct ErrorPayload: Encodable, Sendable {
        let code: String
        let message: String
    }

    let id: SymphonyCodexJSONRPCIdentifierDTO
    let error: ErrorPayload
}

nonisolated struct SymphonyCodexInitializeParamsDTO: Encodable, Sendable {
    nonisolated struct ClientInfoDTO: Encodable, Sendable {
        let name: String
        let title: String?
        let version: String
    }

    nonisolated struct CapabilitiesDTO: Encodable, Sendable {
        let experimentalAPI: Bool
        let optOutNotificationMethods: [String]
    }

    let clientInfo: ClientInfoDTO
    let capabilities: CapabilitiesDTO
}

nonisolated struct SymphonyCodexInitializedParamsDTO: Encodable, Sendable {}

nonisolated struct SymphonyCodexConfigRequirementsReadParamsDTO: Encodable, Sendable {}

nonisolated struct SymphonyCodexThreadStartParamsDTO: Encodable, Sendable {
    let cwd: String
    let approvalPolicy: String
    let sandbox: String
    let serviceName: String?
}

nonisolated struct SymphonyCodexTurnInputItemDTO: Encodable, Sendable {
    let type: String
    let text: String

    init(text: String) {
        self.type = "text"
        self.text = text
    }
}

nonisolated struct SymphonyCodexTurnStartParamsDTO: Encodable, Sendable {
    let threadId: String
    let input: [SymphonyCodexTurnInputItemDTO]
    let cwd: String
    let title: String
    let approvalPolicy: String
    let sandboxPolicy: SymphonyCodexJSONValueDTO
}

nonisolated struct SymphonyCodexApprovalDecisionDTO: Encodable, Sendable {
    let decision: String
}

nonisolated struct SymphonyCodexUnsupportedToolResultDTO: Encodable, Sendable {
    let success: Bool
    let error: String
}

struct SymphonyCodexProtocolMessageDTO: Equatable, Sendable {
    let id: SymphonyCodexJSONRPCIdentifierDTO?
    let method: String?
    let params: SymphonyConfigValueContract?
    let result: SymphonyConfigValueContract?
    let error: SymphonyConfigValueContract?
}

enum SymphonyCodexProtocolDTOTranslators {
    struct Requests {
        func encodedCall<Params: Encodable & Sendable>(
            _ request: SymphonyCodexJSONRPCRequestDTO<Params>,
            using encoder: JSONEncoder
        ) throws -> String {
            try SymphonyCodexProtocolDTOTranslators.encodePayload(
                request,
                using: encoder
            )
        }

        func encodedCall<Params: Encodable & Sendable>(
            _ notification: SymphonyCodexJSONRPCNotificationDTO<Params>,
            using encoder: JSONEncoder
        ) throws -> String {
            try SymphonyCodexProtocolDTOTranslators.encodePayload(
                notification,
                using: encoder
            )
        }

        func initializeCall(
            id: Int,
            from request: SymphonyCodexSessionStartupContract.InitializeRequest
        ) -> SymphonyCodexJSONRPCRequestDTO<SymphonyCodexInitializeParamsDTO> {
            SymphonyCodexJSONRPCRequestDTO(
                id: id,
                method: "initialize",
                params: SymphonyCodexInitializeParamsDTO(
                    clientInfo: .init(
                        name: request.clientInfo.name,
                        title: request.clientInfo.title,
                        version: request.clientInfo.version
                    ),
                    capabilities: .init(
                        experimentalAPI: request.capabilities.experimentalAPI,
                        optOutNotificationMethods: request.capabilities.optOutNotificationMethods
                    )
                )
            )
        }

        func initializedCall() -> SymphonyCodexJSONRPCNotificationDTO<SymphonyCodexInitializedParamsDTO> {
            SymphonyCodexJSONRPCNotificationDTO(
                method: "initialized",
                params: SymphonyCodexInitializedParamsDTO()
            )
        }

        func requirementsProbe(
            id: Int
        ) -> SymphonyCodexJSONRPCRequestDTO<SymphonyCodexConfigRequirementsReadParamsDTO> {
            SymphonyCodexJSONRPCRequestDTO(
                id: id,
                method: "configRequirements/read",
                params: SymphonyCodexConfigRequirementsReadParamsDTO()
            )
        }

        func threadStartCall(
            id: Int,
            launchPath: String,
            request: SymphonyCodexSessionStartupContract.ThreadStartRequest
        ) -> SymphonyCodexJSONRPCRequestDTO<SymphonyCodexThreadStartParamsDTO> {
            SymphonyCodexJSONRPCRequestDTO(
                id: id,
                method: "thread/start",
                params: SymphonyCodexThreadStartParamsDTO(
                    cwd: launchPath,
                    approvalPolicy: request.approvalPolicy,
                    sandbox: request.sandbox,
                    serviceName: request.serviceName
                )
            )
        }

        func turnStartCall(
            id: Int,
            request: SymphonyCodexTurnStartContract
        ) -> SymphonyCodexJSONRPCRequestDTO<SymphonyCodexTurnStartParamsDTO> {
            SymphonyCodexJSONRPCRequestDTO(
                id: id,
                method: "turn/start",
                params: SymphonyCodexTurnStartParamsDTO(
                    threadId: request.threadID,
                    input: [SymphonyCodexTurnInputItemDTO(text: request.inputText)],
                    cwd: request.currentWorkingDirectoryPath,
                    title: request.title,
                    approvalPolicy: request.approvalPolicy,
                    sandboxPolicy: SymphonyCodexJSONValueDTO(request.sandboxPolicy.configValueContract())
                )
            )
        }
    }

    struct Responses {
        func identifier(integer: Int) -> SymphonyCodexJSONRPCIdentifierDTO {
            SymphonyCodexJSONRPCIdentifierDTO(integer: integer)
        }

        func approvalDecision(_ decision: String) -> SymphonyCodexApprovalDecisionDTO {
            SymphonyCodexApprovalDecisionDTO(decision: decision)
        }

        func unsupportedToolResult() -> SymphonyCodexUnsupportedToolResultDTO {
            SymphonyCodexUnsupportedToolResultDTO(
                success: false,
                error: "unsupported_tool_call"
            )
        }

        func resultEnvelope<Result: Encodable & Sendable>(
            id: SymphonyCodexJSONRPCIdentifierDTO,
            result: Result
        ) -> SymphonyCodexJSONRPCResultResponseDTO<Result> {
            SymphonyCodexJSONRPCResultResponseDTO(
                id: id,
                result: result
            )
        }

        func errorEnvelope(
            id: SymphonyCodexJSONRPCIdentifierDTO,
            code: String,
            message: String
        ) -> SymphonyCodexJSONRPCErrorResponseDTO {
            SymphonyCodexJSONRPCErrorResponseDTO(
                id: id,
                error: .init(code: code, message: message)
            )
        }

        func approvalDecisionEnvelope(
            id: SymphonyCodexJSONRPCIdentifierDTO,
            decision: String
        ) -> SymphonyCodexJSONRPCResultResponseDTO<SymphonyCodexApprovalDecisionDTO> {
            resultEnvelope(
                id: id,
                result: approvalDecision(decision)
            )
        }

        func unsupportedToolEnvelope(
            id: SymphonyCodexJSONRPCIdentifierDTO
        ) -> SymphonyCodexJSONRPCResultResponseDTO<SymphonyCodexUnsupportedToolResultDTO> {
            resultEnvelope(
                id: id,
                result: unsupportedToolResult()
            )
        }

        func userInputRejectedEnvelope(
            id: SymphonyCodexJSONRPCIdentifierDTO
        ) -> SymphonyCodexJSONRPCErrorResponseDTO {
            errorEnvelope(
                id: id,
                code: "turn_input_required",
                message: "Symphony does not support interactive user input."
            )
        }

        func encodedServerDirectivePayload(
            id: SymphonyCodexJSONRPCIdentifierDTO,
            action: SymphonyCodexServerDirectiveResponseModel.Action,
            using encoder: JSONEncoder
        ) throws -> String? {
            switch action {
            case .approval(_, let decision):
                return try encodedPayload(
                    approvalDecisionEnvelope(id: id, decision: decision),
                    using: encoder
                )
            case .unsupportedToolCall:
                return try encodedPayload(
                    unsupportedToolEnvelope(id: id),
                    using: encoder
                )
            case .userInputRequested(let code, let message):
                return try encodedPayload(
                    errorEnvelope(id: id, code: code, message: message),
                    using: encoder
                )
            case .unhandled:
                return nil
            }
        }

        private func encodedPayload<Value: Encodable>(
            _ payload: Value,
            using encoder: JSONEncoder
        ) throws -> String {
            try SymphonyCodexProtocolDTOTranslators.encodePayload(
                payload,
                using: encoder
            )
        }
    }

    struct Messages {
        func parseLine(_ line: String) throws -> SymphonyCodexProtocolMessageDTO {
            guard let data = line.data(using: .utf8) else {
                throw SymphonyCodexRunnerInfrastructureError.responseError(
                    details: "The protocol line could not be encoded as UTF-8."
                )
            }

            let jsonObject = try JSONSerialization.jsonObject(with: data)
            guard let object = jsonObject as? [String: Any] else {
                throw SymphonyCodexRunnerInfrastructureError.responseError(
                    details: "The protocol line was not a JSON object."
                )
            }

            return SymphonyCodexProtocolMessageDTO(
                id: object["id"].flatMap(identifier(from:)),
                method: object["method"] as? String,
                params: object["params"].map(configValue(from:)),
                result: object["result"].map(configValue(from:)),
                error: object["error"].map(configValue(from:))
            )
        }

        private func identifier(from value: Any) -> SymphonyCodexJSONRPCIdentifierDTO? {
            if let integer = value as? Int {
                return SymphonyCodexJSONRPCIdentifierDTO(integer: integer)
            }

            if let string = value as? String {
                return SymphonyCodexJSONRPCIdentifierDTO(string: string)
            }

            return nil
        }

        private func configValue(from value: Any) -> SymphonyConfigValueContract {
            switch value {
            case let string as String:
                return .string(string)
            case let integer as Int:
                return .integer(integer)
            case let double as Double:
                if floor(double) == double {
                    return .integer(Int(double))
                }

                return .double(double)
            case let bool as Bool:
                return .bool(bool)
            case let array as [Any]:
                return .array(array.map(configValue(from:)))
            case let object as [String: Any]:
                return .object(object.mapValues(configValue(from:)))
            case _ as NSNull:
                return .null
            default:
                return .null
            }
        }
    }

    fileprivate static func encodePayload<Value: Encodable>(
        _ payload: Value,
        using encoder: JSONEncoder
    ) throws -> String {
        let data = try encoder.encode(payload)
        guard let string = String(data: data, encoding: .utf8) else {
            throw SymphonyCodexRunnerInfrastructureError.responseError(
                details: "A protocol payload could not be encoded as UTF-8."
            )
        }

        return string
    }
}
