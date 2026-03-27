import Foundation

public struct ArchitectureNestedNominalDeclaration: Sendable, Equatable {
    public let enclosingTypeName: String
    public let name: String
    public let kind: NominalKind
    public let inheritedTypeNames: [String]
    public let memberNames: [String]
    public let coordinate: SourceCoordinate

    public init(
        enclosingTypeName: String,
        name: String,
        kind: NominalKind,
        inheritedTypeNames: [String],
        memberNames: [String],
        coordinate: SourceCoordinate
    ) {
        self.enclosingTypeName = enclosingTypeName
        self.name = name
        self.kind = kind
        self.inheritedTypeNames = inheritedTypeNames
        self.memberNames = memberNames
        self.coordinate = coordinate
    }
}
