import Foundation

public struct ArchitectureMethodDeclaration: Sendable, Equatable {
    public let enclosingTypeName: String
    public let name: String
    public let isStatic: Bool
    public let isPublicOrOpen: Bool
    public let isPrivateOrFileprivate: Bool
    public let parameterTypeNames: [String]
    public let hasExplicitReturnType: Bool
    public let returnTypeDescription: String?
    public let returnTypeNames: [String]
    public let returnsVoidLike: Bool
    public let coordinate: SourceCoordinate

    public init(
        enclosingTypeName: String,
        name: String,
        isStatic: Bool,
        isPublicOrOpen: Bool,
        isPrivateOrFileprivate: Bool,
        parameterTypeNames: [String],
        hasExplicitReturnType: Bool,
        returnTypeDescription: String?,
        returnTypeNames: [String],
        returnsVoidLike: Bool,
        coordinate: SourceCoordinate
    ) {
        self.enclosingTypeName = enclosingTypeName
        self.name = name
        self.isStatic = isStatic
        self.isPublicOrOpen = isPublicOrOpen
        self.isPrivateOrFileprivate = isPrivateOrFileprivate
        self.parameterTypeNames = parameterTypeNames
        self.hasExplicitReturnType = hasExplicitReturnType
        self.returnTypeDescription = returnTypeDescription
        self.returnTypeNames = returnTypeNames
        self.returnsVoidLike = returnsVoidLike
        self.coordinate = coordinate
    }
}
