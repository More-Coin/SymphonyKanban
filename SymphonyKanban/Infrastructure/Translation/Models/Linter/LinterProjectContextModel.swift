import Foundation

struct LinterProjectContextModel {
    func toDomain(_ files: [SourceFileRecord]) -> ProjectContext {
        let declarations: [IndexedDeclaration] = files.flatMap { file in
            file.topLevelDeclarations.map { declaration in
                let methodShapes: [IndexedMethodShape]
                if declaration.kind == .protocol {
                    methodShapes = file.methodDeclarations
                        .filter { $0.enclosingTypeName == declaration.name }
                        .map { method in
                            IndexedMethodShape(
                                returnsVoidLike: method.returnsVoidLike,
                                parameterTypeNames: method.parameterTypeNames
                            )
                        }
                } else {
                    methodShapes = []
                }

                return IndexedDeclaration(
                    name: declaration.name,
                    kind: declaration.kind,
                    inheritedTypeNames: declaration.inheritedTypeNames,
                    methodShapes: methodShapes,
                    repoRelativePath: file.repoRelativePath,
                    layer: file.classification.layer,
                    roleFolder: file.classification.roleFolder
                )
            }
        }

        return ProjectContext(declarations: declarations)
    }
}
