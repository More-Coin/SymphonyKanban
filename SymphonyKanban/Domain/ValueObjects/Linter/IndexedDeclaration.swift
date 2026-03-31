import Foundation

public struct IndexedDeclaration: Sendable, Equatable {
    public let name: String
    public let kind: NominalKind
    public let inheritedTypeNames: [String]
    public let methodShapes: [IndexedMethodShape]
    public let repoRelativePath: String
    public let layer: ArchitectureLayer
    public let roleFolder: RoleFolder

    public init(
        name: String,
        kind: NominalKind,
        inheritedTypeNames: [String],
        methodShapes: [IndexedMethodShape],
        repoRelativePath: String,
        layer: ArchitectureLayer,
        roleFolder: RoleFolder
    ) {
        self.name = name
        self.kind = kind
        self.inheritedTypeNames = inheritedTypeNames
        self.methodShapes = methodShapes
        self.repoRelativePath = repoRelativePath
        self.layer = layer
        self.roleFolder = roleFolder
    }
}
