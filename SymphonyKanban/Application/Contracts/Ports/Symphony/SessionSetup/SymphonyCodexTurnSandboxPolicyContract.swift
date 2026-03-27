public struct SymphonyCodexTurnSandboxPolicyContract: Equatable, Sendable {
    public let type: String
    public let writableRoots: [String]
    public let networkAccess: Bool
    public let access: SymphonyConfigValueContract?
    public let readOnlyAccess: SymphonyConfigValueContract?

    public init(
        type: String,
        writableRoots: [String] = [],
        networkAccess: Bool,
        access: SymphonyConfigValueContract? = nil,
        readOnlyAccess: SymphonyConfigValueContract? = nil
    ) {
        self.type = type
        self.writableRoots = writableRoots
        self.networkAccess = networkAccess
        self.access = access
        self.readOnlyAccess = readOnlyAccess
    }

    public func configValueContract() -> SymphonyConfigValueContract {
        var object: [String: SymphonyConfigValueContract] = [
            "type": .string(type),
            "networkAccess": .bool(networkAccess)
        ]

        if !writableRoots.isEmpty {
            object["writableRoots"] = .array(writableRoots.map(SymphonyConfigValueContract.string))
        }

        if let access {
            object["access"] = access
        }

        if let readOnlyAccess {
            object["readOnlyAccess"] = readOnlyAccess
        }

        return .object(object)
    }
}
