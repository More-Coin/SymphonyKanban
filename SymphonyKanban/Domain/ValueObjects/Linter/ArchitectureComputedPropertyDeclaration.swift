import Foundation

public struct ArchitectureComputedPropertyDeclaration: Sendable, Equatable {
    public let enclosingTypeName: String
    public let name: String
    public let typeDescription: String
    public let typeNames: [String]
    public let isStatic: Bool
    public let coordinate: SourceCoordinate

    public init(
        enclosingTypeName: String,
        name: String,
        typeDescription: String,
        typeNames: [String],
        isStatic: Bool,
        coordinate: SourceCoordinate
    ) {
        self.enclosingTypeName = enclosingTypeName
        self.name = name
        self.typeDescription = typeDescription
        self.typeNames = typeNames
        self.isStatic = isStatic
        self.coordinate = coordinate
    }
}
