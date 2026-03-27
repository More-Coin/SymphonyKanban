import Foundation

public struct ArchitectureStoredMemberDeclaration: Sendable, Equatable {
    public let enclosingTypeName: String
    public let name: String
    public let typeNames: [String]
    public let isStatic: Bool
    public let coordinate: SourceCoordinate

    public init(
        enclosingTypeName: String,
        name: String,
        typeNames: [String],
        isStatic: Bool,
        coordinate: SourceCoordinate
    ) {
        self.enclosingTypeName = enclosingTypeName
        self.name = name
        self.typeNames = typeNames
        self.isStatic = isStatic
        self.coordinate = coordinate
    }
}
