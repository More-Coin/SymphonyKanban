import Foundation

public struct IndexedMethodShape: Sendable, Equatable {
    public let returnsVoidLike: Bool
    public let parameterTypeNames: [String]

    public init(
        returnsVoidLike: Bool,
        parameterTypeNames: [String]
    ) {
        self.returnsVoidLike = returnsVoidLike
        self.parameterTypeNames = parameterTypeNames
    }
}
