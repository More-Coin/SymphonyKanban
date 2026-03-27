import Foundation

public struct ProjectContext: Sendable, Equatable {
    public let declarations: [IndexedDeclaration]
    private let uniquelyNamedDeclarations: [String: IndexedDeclaration]

    public init(declarations: [IndexedDeclaration]) {
        self.declarations = declarations

        var declarationsByName: [String: [IndexedDeclaration]] = [:]
        for declaration in declarations {
            declarationsByName[declaration.name, default: []].append(declaration)
        }

        var unique: [String: IndexedDeclaration] = [:]
        for (name, matchedDeclarations) in declarationsByName where matchedDeclarations.count == 1 {
            unique[name] = matchedDeclarations[0]
        }
        self.uniquelyNamedDeclarations = unique
    }

    public func uniqueDeclaration(named name: String) -> IndexedDeclaration? {
        uniquelyNamedDeclarations[name]
    }
}
