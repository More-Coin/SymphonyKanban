public indirect enum SymphonyConfigValueContract: Equatable, Sendable {
    case string(String)
    case integer(Int)
    case double(Double)
    case bool(Bool)
    case array([SymphonyConfigValueContract])
    case object([String: SymphonyConfigValueContract])
    case null

    var stringValue: String? {
        guard case .string(let value) = self else {
            return nil
        }

        return value
    }

    var integerValue: Int? {
        switch self {
        case .integer(let value):
            return value
        case .string(let value):
            return Int(value)
        default:
            return nil
        }
    }

    var dictionaryValue: [String: SymphonyConfigValueContract]? {
        guard case .object(let value) = self else {
            return nil
        }

        return value
    }

    var arrayValue: [SymphonyConfigValueContract]? {
        guard case .array(let value) = self else {
            return nil
        }

        return value
    }
}
