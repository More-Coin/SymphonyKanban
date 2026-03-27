import Foundation

public struct ArchitectureInitializerDeclaration: Sendable, Equatable {
    public let enclosingTypeName: String
    public let parameterTypeNames: [String]
    public let coordinate: SourceCoordinate

    public init(
        enclosingTypeName: String,
        parameterTypeNames: [String],
        coordinate: SourceCoordinate
    ) {
        self.enclosingTypeName = enclosingTypeName
        self.parameterTypeNames = parameterTypeNames
        self.coordinate = coordinate
    }
}
