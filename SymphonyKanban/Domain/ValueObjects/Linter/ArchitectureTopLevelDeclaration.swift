import Foundation

public struct ArchitectureTopLevelDeclaration: Sendable, Equatable {
    public let name: String
    public let kind: NominalKind
    public let inheritedTypeNames: [String]
    public let memberNames: [String]
    public let coordinate: SourceCoordinate

    public init(
        name: String,
        kind: NominalKind,
        inheritedTypeNames: [String],
        memberNames: [String],
        coordinate: SourceCoordinate
    ) {
        self.name = name
        self.kind = kind
        self.inheritedTypeNames = inheritedTypeNames
        self.memberNames = memberNames
        self.coordinate = coordinate
    }
}
