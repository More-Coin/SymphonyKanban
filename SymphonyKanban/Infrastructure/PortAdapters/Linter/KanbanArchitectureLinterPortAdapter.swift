import Foundation
import SwiftParser
import SwiftSyntax

struct KanbanArchitectureLinterPortAdapter: ArchitectureLintPortProtocol {
    private let policies: [any ArchitecturePolicyProtocol]
    private let sourceFileDiscovery: SourceFileDiscoveryPortProtocol
    private let repoRelativePathModel: LinterRepoRelativePathModel

    init(
        policies: [any ArchitecturePolicyProtocol],
        sourceFileDiscovery: SourceFileDiscoveryPortProtocol,
        repoRelativePathModel: LinterRepoRelativePathModel = LinterRepoRelativePathModel()
    ) {
        self.policies = policies
        self.sourceFileDiscovery = sourceFileDiscovery
        self.repoRelativePathModel = repoRelativePathModel
    }

    func lintProject(at rootURL: URL) throws -> KanbanArchitectureLintResultContract {
        let classifier = ArchitecturePathClassificationPolicy()
        let fileURLs = try sourceFileDiscovery.discoverSwiftFiles(in: rootURL)
        let files = try fileURLs.map { try loadSourceFile(from: $0, rootURL: rootURL, classifier: classifier) }
        let context = buildProjectContext(from: files)
        let architectureFiles = files.map(\.architectureFile)
        let diagnostics = architectureFiles.flatMap { file in
            policies.flatMap { policy in
                policy.evaluate(file: file, context: context)
            }
        }
        let orderedDiagnostics = ArchitectureDiagnosticOrderingPolicy().ordered(diagnostics)
        return KanbanArchitectureLintResultContract(diagnostics: orderedDiagnostics)
    }

    private func buildProjectContext(from files: [SourceFileRecord]) -> ProjectContext {
        let declarations = files.flatMap { file in
            file.topLevelDeclarations.map { declaration in
                IndexedDeclaration(
                    name: declaration.name,
                    kind: declaration.kind,
                    inheritedTypeNames: declaration.inheritedTypeNames,
                    repoRelativePath: file.repoRelativePath,
                    layer: file.classification.layer,
                    roleFolder: file.classification.roleFolder
                )
            }
        }

        return ProjectContext(declarations: declarations)
    }

    private func loadSourceFile(
        from fileURL: URL,
        rootURL: URL,
        classifier: ArchitecturePathClassificationPolicy
    ) throws -> SourceFileRecord {
        let source: String
        do {
            source = try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            throw KanbanArchitectureLinterInfrastructureError.unreadableSourceFile(
                path: fileURL.standardizedFileURL.path
            )
        }
        let repoRelativePath = repoRelativePathModel.fromURLs(
            fileURL: fileURL,
            rootURL: rootURL
        )
        let syntaxTree = Parser.parse(source: source)
        let converter = SourceLocationConverter(fileName: repoRelativePath, tree: syntaxTree)

        return SourceFileRecord(
            fileURL: fileURL,
            repoRelativePath: repoRelativePath,
            source: source,
            syntaxTree: syntaxTree,
            converter: converter,
            classification: classifier.classify(repoRelativePath: repoRelativePath),
            imports: SourceFileAnalyzer.collectImports(from: syntaxTree),
            functionTypeOccurrences: SourceFileAnalyzer.collectFunctionTypeOccurrences(from: syntaxTree),
            identifierOccurrences: SourceFileAnalyzer.collectIdentifiers(from: syntaxTree),
            stringLiteralOccurrences: SourceFileAnalyzer.collectStringLiterals(from: syntaxTree),
            typedMemberOccurrences: SourceFileAnalyzer.collectTypedMembers(from: syntaxTree),
            memberCallOccurrences: SourceFileAnalyzer.collectMemberCalls(from: syntaxTree),
            methodDeclarations: SourceFileAnalyzer.collectMethodDeclarations(from: syntaxTree),
            initializerDeclarations: SourceFileAnalyzer.collectInitializerDeclarations(from: syntaxTree),
            computedPropertyDeclarations: SourceFileAnalyzer.collectComputedProperties(from: syntaxTree),
            storedMemberDeclarations: SourceFileAnalyzer.collectStoredMembers(from: syntaxTree),
            operationalUseOccurrences: SourceFileAnalyzer.collectOperationalUses(from: syntaxTree),
            typeReferences: SourceFileAnalyzer.collectTypeReferences(from: syntaxTree),
            topLevelDeclarations: SourceFileAnalyzer.collectTopLevelDeclarations(from: syntaxTree),
            nestedNominalDeclarations: SourceFileAnalyzer.collectNestedNominalDeclarations(from: syntaxTree)
        )
    }

}

private extension SourceFileRecord {
    var architectureFile: ArchitectureFile {
        ArchitectureFile(
            repoRelativePath: repoRelativePath,
            classification: classification,
            imports: imports.map { occurrence in
                ArchitectureImportOccurrence(
                    moduleName: occurrence.moduleName,
                    coordinate: coordinate(for: occurrence.position)
                )
            },
            functionTypeOccurrences: functionTypeOccurrences.map { occurrence in
                ArchitectureFunctionTypeOccurrence(
                    coordinate: coordinate(for: occurrence)
                )
            },
            identifierOccurrences: identifierOccurrences.map { occurrence in
                ArchitectureIdentifierOccurrence(
                    name: occurrence.name,
                    coordinate: coordinate(for: occurrence.position)
                )
            },
            stringLiteralOccurrences: stringLiteralOccurrences.map { occurrence in
                ArchitectureStringLiteralOccurrence(
                    value: occurrence.value,
                    coordinate: coordinate(for: occurrence.position)
                )
            },
            typedMemberOccurrences: typedMemberOccurrences.map { occurrence in
                ArchitectureTypedMemberOccurrence(
                    name: occurrence.name,
                    typeNames: occurrence.typeNames,
                    coordinate: coordinate(for: occurrence.position)
                )
            },
            memberCallOccurrences: memberCallOccurrences.map { occurrence in
                ArchitectureMemberCallOccurrence(
                    baseName: occurrence.baseName,
                    memberName: occurrence.memberName,
                    coordinate: coordinate(for: occurrence.position)
                )
            },
            methodDeclarations: methodDeclarations.map { declaration in
                ArchitectureMethodDeclaration(
                    enclosingTypeName: declaration.enclosingTypeName,
                    name: declaration.name,
                    isStatic: declaration.isStatic,
                    isPublicOrOpen: declaration.isPublicOrOpen,
                    isPrivateOrFileprivate: declaration.isPrivateOrFileprivate,
                    parameterTypeNames: declaration.parameterTypeNames,
                    hasExplicitReturnType: declaration.hasExplicitReturnType,
                    returnTypeDescription: declaration.returnTypeDescription,
                    returnTypeNames: declaration.returnTypeNames,
                    returnsVoidLike: declaration.returnsVoidLike,
                    coordinate: coordinate(for: declaration.position)
                )
            },
            initializerDeclarations: initializerDeclarations.map { declaration in
                ArchitectureInitializerDeclaration(
                    enclosingTypeName: declaration.enclosingTypeName,
                    parameterTypeNames: declaration.parameterTypeNames,
                    coordinate: coordinate(for: declaration.position)
                )
            },
            computedPropertyDeclarations: computedPropertyDeclarations.map { declaration in
                ArchitectureComputedPropertyDeclaration(
                    enclosingTypeName: declaration.enclosingTypeName,
                    name: declaration.name,
                    typeDescription: declaration.typeDescription,
                    typeNames: declaration.typeNames,
                    isStatic: declaration.isStatic,
                    coordinate: coordinate(for: declaration.position)
                )
            },
            storedMemberDeclarations: storedMemberDeclarations.map { declaration in
                ArchitectureStoredMemberDeclaration(
                    enclosingTypeName: declaration.enclosingTypeName,
                    name: declaration.name,
                    typeNames: declaration.typeNames,
                    isStatic: declaration.isStatic,
                    coordinate: coordinate(for: declaration.position)
                )
            },
            operationalUseOccurrences: operationalUseOccurrences.map { occurrence in
                ArchitectureOperationalUseOccurrence(
                    enclosingTypeName: occurrence.enclosingTypeName,
                    enclosingMethodName: occurrence.enclosingMethodName,
                    baseName: occurrence.baseName,
                    memberName: occurrence.memberName,
                    branchGroupIndex: occurrence.branchGroupIndex,
                    branchArmIndex: occurrence.branchArmIndex,
                    coordinate: coordinate(for: occurrence.position)
                )
            },
            typeReferences: typeReferences.map { reference in
                ArchitectureTypeReference(
                    name: reference.name,
                    coordinate: coordinate(for: reference.position)
                )
            },
            topLevelDeclarations: topLevelDeclarations.map { declaration in
                ArchitectureTopLevelDeclaration(
                    name: declaration.name,
                    kind: declaration.kind,
                    inheritedTypeNames: declaration.inheritedTypeNames,
                    memberNames: declaration.memberNames,
                    coordinate: coordinate(for: declaration.position)
                )
            },
            nestedNominalDeclarations: nestedNominalDeclarations.map { declaration in
                ArchitectureNestedNominalDeclaration(
                    enclosingTypeName: declaration.enclosingTypeName,
                    name: declaration.name,
                    kind: declaration.kind,
                    inheritedTypeNames: declaration.inheritedTypeNames,
                    memberNames: declaration.memberNames,
                    coordinate: coordinate(for: declaration.position)
                )
            }
        )
    }
}

private extension KanbanArchitectureLinterPortAdapter {
    enum SourceFileAnalyzer {
        static func collectImports(from sourceFile: SourceFileSyntax) -> [ImportOccurrence] {
            let collector = ImportCollector(viewMode: .sourceAccurate)
            collector.walk(sourceFile)
            return collector.imports
        }

        static func collectIdentifiers(from sourceFile: SourceFileSyntax) -> [NamedOccurrence] {
            let collector = IdentifierCollector(viewMode: .sourceAccurate)
            collector.walk(sourceFile)
            return collector.occurrences
        }

        static func collectStringLiterals(from sourceFile: SourceFileSyntax) -> [StringLiteralOccurrence] {
            let collector = StringLiteralCollector(viewMode: .sourceAccurate)
            collector.walk(sourceFile)
            return collector.occurrences
        }

        static func collectTypedMembers(from sourceFile: SourceFileSyntax) -> [TypedMemberOccurrence] {
            let collector = TypedMemberCollector(viewMode: .sourceAccurate)
            collector.walk(sourceFile)
            return collector.occurrences
        }

        static func collectMemberCalls(from sourceFile: SourceFileSyntax) -> [MemberCallOccurrence] {
            let collector = MemberCallCollector(viewMode: .sourceAccurate)
            collector.walk(sourceFile)
            return collector.occurrences
        }

        static func collectMethodDeclarations(
            from sourceFile: SourceFileSyntax
        ) -> [MethodDeclarationRecord] {
            let collector = MethodDeclarationCollector(viewMode: .sourceAccurate)
            collector.walk(sourceFile)
            return collector.occurrences
        }

        static func collectInitializerDeclarations(
            from sourceFile: SourceFileSyntax
        ) -> [InitializerDeclarationRecord] {
            let collector = InitializerDeclarationCollector(viewMode: .sourceAccurate)
            collector.walk(sourceFile)
            return collector.occurrences
        }

        static func collectComputedProperties(
            from sourceFile: SourceFileSyntax
        ) -> [ComputedPropertyDeclarationRecord] {
            let collector = ComputedPropertyCollector(viewMode: .sourceAccurate)
            collector.walk(sourceFile)
            return collector.occurrences
        }

        static func collectStoredMembers(
            from sourceFile: SourceFileSyntax
        ) -> [StoredMemberDeclarationRecord] {
            let collector = StoredMemberCollector(viewMode: .sourceAccurate)
            collector.walk(sourceFile)
            return collector.occurrences
        }

        static func collectOperationalUses(
            from sourceFile: SourceFileSyntax
        ) -> [OperationalUseOccurrenceRecord] {
            let collector = OperationalUseCollector(viewMode: .sourceAccurate)
            collector.walk(sourceFile)
            return collector.occurrences
        }

        static func collectFunctionTypeOccurrences(from sourceFile: SourceFileSyntax) -> [AbsolutePosition] {
            let collector = FunctionTypeCollector(viewMode: .sourceAccurate)
            collector.walk(sourceFile)
            return collector.occurrences
        }

        static func collectTypeReferences(from sourceFile: SourceFileSyntax) -> [NamedOccurrence] {
            let collector = TypeReferenceCollector(viewMode: .sourceAccurate)
            collector.walk(sourceFile)
            return collector.occurrences
        }

        static func collectTopLevelDeclarations(from sourceFile: SourceFileSyntax) -> [TopLevelNominalDeclaration] {
            sourceFile.statements.compactMap { statement in
                let item = statement.item

                if let declaration = item.as(ProtocolDeclSyntax.self) {
                    return TopLevelNominalDeclaration(
                        name: declaration.name.text,
                        kind: .protocol,
                        inheritedTypeNames: inheritedTypeNames(from: declaration.inheritanceClause),
                        memberNames: memberNames(from: declaration.memberBlock),
                        position: declaration.positionAfterSkippingLeadingTrivia
                    )
                }

                if let declaration = item.as(ClassDeclSyntax.self) {
                    return TopLevelNominalDeclaration(
                        name: declaration.name.text,
                        kind: .class,
                        inheritedTypeNames: inheritedTypeNames(from: declaration.inheritanceClause),
                        memberNames: memberNames(from: declaration.memberBlock),
                        position: declaration.positionAfterSkippingLeadingTrivia
                    )
                }

                if let declaration = item.as(StructDeclSyntax.self) {
                    return TopLevelNominalDeclaration(
                        name: declaration.name.text,
                        kind: .struct,
                        inheritedTypeNames: inheritedTypeNames(from: declaration.inheritanceClause),
                        memberNames: memberNames(from: declaration.memberBlock),
                        position: declaration.positionAfterSkippingLeadingTrivia
                    )
                }

                if let declaration = item.as(EnumDeclSyntax.self) {
                    return TopLevelNominalDeclaration(
                        name: declaration.name.text,
                        kind: .enum,
                        inheritedTypeNames: inheritedTypeNames(from: declaration.inheritanceClause),
                        memberNames: memberNames(from: declaration.memberBlock),
                        position: declaration.positionAfterSkippingLeadingTrivia
                    )
                }

                if let declaration = item.as(ActorDeclSyntax.self) {
                    return TopLevelNominalDeclaration(
                        name: declaration.name.text,
                        kind: .actor,
                        inheritedTypeNames: inheritedTypeNames(from: declaration.inheritanceClause),
                        memberNames: memberNames(from: declaration.memberBlock),
                        position: declaration.positionAfterSkippingLeadingTrivia
                    )
                }

                return nil
            }
        }

        static func collectNestedNominalDeclarations(
            from sourceFile: SourceFileSyntax
        ) -> [NestedNominalDeclarationRecord] {
            let collector = NestedNominalDeclarationCollector(viewMode: .sourceAccurate)
            collector.walk(sourceFile)
            return collector.occurrences
        }

        private static func inheritedTypeNames(from inheritanceClause: InheritanceClauseSyntax?) -> [String] {
            guard let inheritanceClause else {
                return []
            }

            return inheritanceClause.inheritedTypes.compactMap { inheritedType in
                if let identifierType = inheritedType.type.as(IdentifierTypeSyntax.self) {
                    return identifierType.name.text
                }
                if let memberType = inheritedType.type.as(MemberTypeSyntax.self) {
                    return memberType.name.text
                }
                return inheritedType.type.trimmedDescription
                    .split(separator: ".")
                    .last
                    .map(String.init)
            }
        }

        private static func memberNames(from memberBlock: MemberBlockSyntax) -> [String] {
            memberBlock.members.flatMap { member in
                if let variable = member.decl.as(VariableDeclSyntax.self) {
                    return variable.bindings.compactMap { binding in
                        binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
                    }
                }

                if let function = member.decl.as(FunctionDeclSyntax.self) {
                    return [function.name.text]
                }

                return []
            }
        }
    }

    nonisolated final class ImportCollector: SyntaxVisitor {
        var imports: [ImportOccurrence] = []

        override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
            let moduleName = node.path.last?.name.text ?? node.path.trimmedDescription
            imports.append(
                ImportOccurrence(
                    moduleName: moduleName,
                    position: node.positionAfterSkippingLeadingTrivia
                )
            )
            return .skipChildren
        }
    }

    nonisolated final class IdentifierCollector: SyntaxVisitor {
        var occurrences: [NamedOccurrence] = []

        override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
            if case .identifier(let text) = token.tokenKind {
                occurrences.append(
                    NamedOccurrence(
                        name: text,
                        position: token.positionAfterSkippingLeadingTrivia
                    )
                )
            }
            return .visitChildren
        }
    }

    nonisolated final class TypeReferenceCollector: SyntaxVisitor {
        var occurrences: [NamedOccurrence] = []

        override func visit(_ node: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
            occurrences.append(
                NamedOccurrence(
                    name: node.name.text,
                    position: node.positionAfterSkippingLeadingTrivia
                )
            )
            return .visitChildren
        }

        override func visit(_ node: MemberTypeSyntax) -> SyntaxVisitorContinueKind {
            occurrences.append(
                NamedOccurrence(
                    name: node.name.text,
                    position: node.positionAfterSkippingLeadingTrivia
                )
            )
            return .visitChildren
        }
    }

    nonisolated final class FunctionTypeCollector: SyntaxVisitor {
        var occurrences: [AbsolutePosition] = []

        override func visit(_ node: FunctionTypeSyntax) -> SyntaxVisitorContinueKind {
            occurrences.append(node.positionAfterSkippingLeadingTrivia)
            return .skipChildren
        }
    }

    nonisolated final class StringLiteralCollector: SyntaxVisitor {
        var occurrences: [StringLiteralOccurrence] = []

        override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
            let value = node.segments.compactMap { segment in
                segment.as(StringSegmentSyntax.self)?.content.text
            }.joined()

            guard !value.isEmpty else {
                return .skipChildren
            }

            occurrences.append(
                StringLiteralOccurrence(
                    value: value,
                    position: node.positionAfterSkippingLeadingTrivia
                )
            )

            return .skipChildren
        }
    }

    nonisolated final class TypedMemberCollector: SyntaxVisitor {
        var occurrences: [TypedMemberOccurrence] = []

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            for binding in node.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
                guard let typeAnnotation = binding.typeAnnotation else { continue }
                let typeNames = extractedTypeNames(from: typeAnnotation.type)
                guard !typeNames.isEmpty else { continue }

                occurrences.append(
                    TypedMemberOccurrence(
                        name: pattern.identifier.text,
                        typeNames: typeNames,
                        position: pattern.identifier.positionAfterSkippingLeadingTrivia
                    )
                )
            }

            return .visitChildren
        }
    }

    nonisolated final class MemberCallCollector: SyntaxVisitor {
        var occurrences: [MemberCallOccurrence] = []

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self) else {
                return .visitChildren
            }
            guard let baseName = rootBaseName(from: memberAccess.base) else {
                return .visitChildren
            }

            occurrences.append(
                MemberCallOccurrence(
                    baseName: baseName,
                    memberName: memberAccess.declName.baseName.text,
                    position: node.positionAfterSkippingLeadingTrivia
                )
            )

            return .visitChildren
        }
    }

    nonisolated final class MethodDeclarationCollector: SyntaxVisitor {
        var occurrences: [MethodDeclarationRecord] = []
        private var typeStack: [String] = []

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            if let identifierType = node.extendedType.as(IdentifierTypeSyntax.self) {
                typeStack.append(identifierType.name.text)
            } else if let memberType = node.extendedType.as(MemberTypeSyntax.self) {
                typeStack.append(memberType.name.text)
            }

            return .visitChildren
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            if node.extendedType.as(IdentifierTypeSyntax.self) != nil
                || node.extendedType.as(MemberTypeSyntax.self) != nil {
                _ = typeStack.popLast()
            }
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: StructDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            guard let enclosingTypeName = typeStack.last else {
                return .skipChildren
            }

            let returnMetadata = Self.returnMetadata(from: node)

            occurrences.append(
                MethodDeclarationRecord(
                    enclosingTypeName: enclosingTypeName,
                    name: node.name.text,
                    isStatic: hasModifier(named: ["static", "class"], in: node.modifiers),
                    isPublicOrOpen: hasModifier(named: ["public", "open"], in: node.modifiers),
                    isPrivateOrFileprivate: hasModifier(
                        named: ["private", "fileprivate"],
                        in: node.modifiers
                    ),
                    parameterTypeNames: Self.parameterTypeNames(from: node),
                    hasExplicitReturnType: returnMetadata.hasExplicitReturnType,
                    returnTypeDescription: returnMetadata.returnTypeDescription,
                    returnTypeNames: returnMetadata.returnTypeNames,
                    returnsVoidLike: returnMetadata.returnsVoidLike,
                    position: node.positionAfterSkippingLeadingTrivia
                )
            )

            return .skipChildren
        }

        private static func returnMetadata(
            from node: FunctionDeclSyntax
        ) -> (
            hasExplicitReturnType: Bool,
            returnTypeDescription: String?,
            returnTypeNames: [String],
            returnsVoidLike: Bool
        ) {
            guard let returnClause = node.signature.returnClause else {
                return (false, nil, [], true)
            }

            let returnType = returnClause.type
            return (
                true,
                returnType.trimmedDescription,
                extractedTypeNames(from: returnType),
                isVoidLike(type: returnType)
            )
        }

        private static func parameterTypeNames(from node: FunctionDeclSyntax) -> [String] {
            let typeNames: [String] = node.signature.parameterClause.parameters.flatMap { parameter in
                extractedTypeNames(from: parameter.type)
            }

            return Array(Set(typeNames))
        }
    }

    nonisolated final class InitializerDeclarationCollector: SyntaxVisitor {
        var occurrences: [InitializerDeclarationRecord] = []
        private var typeStack: [String] = []

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            if let identifierType = node.extendedType.as(IdentifierTypeSyntax.self) {
                typeStack.append(identifierType.name.text)
            } else if let memberType = node.extendedType.as(MemberTypeSyntax.self) {
                typeStack.append(memberType.name.text)
            }

            return .visitChildren
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            if node.extendedType.as(IdentifierTypeSyntax.self) != nil
                || node.extendedType.as(MemberTypeSyntax.self) != nil {
                _ = typeStack.popLast()
            }
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: StructDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            guard let enclosingTypeName = typeStack.last else {
                return .skipChildren
            }

            let parameterTypeNames = node.signature.parameterClause.parameters.flatMap { parameter in
                extractedTypeNames(from: parameter.type)
            }

            occurrences.append(
                InitializerDeclarationRecord(
                    enclosingTypeName: enclosingTypeName,
                    parameterTypeNames: Array(Set(parameterTypeNames)),
                    position: node.positionAfterSkippingLeadingTrivia
                )
            )

            return .skipChildren
        }
    }

    nonisolated final class ComputedPropertyCollector: SyntaxVisitor {
        var occurrences: [ComputedPropertyDeclarationRecord] = []
        private var typeStack: [String] = []
        private var methodDepth = 0

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            if let identifierType = node.extendedType.as(IdentifierTypeSyntax.self) {
                typeStack.append(identifierType.name.text)
            } else if let memberType = node.extendedType.as(MemberTypeSyntax.self) {
                typeStack.append(memberType.name.text)
            }

            return .visitChildren
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            if node.extendedType.as(IdentifierTypeSyntax.self) != nil
                || node.extendedType.as(MemberTypeSyntax.self) != nil {
                _ = typeStack.popLast()
            }
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: StructDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            methodDepth += 1
            return .visitChildren
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            methodDepth -= 1
        }

        override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            methodDepth += 1
            return .visitChildren
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            methodDepth -= 1
        }

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            guard let enclosingTypeName = typeStack.last, methodDepth == 0 else {
                return .visitChildren
            }

            let isStatic = hasModifier(named: ["static", "class"], in: node.modifiers)

            for binding in node.bindings {
                guard binding.accessorBlock != nil else { continue }
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
                guard let typeAnnotation = binding.typeAnnotation else { continue }

                let typeNames = extractedTypeNames(from: typeAnnotation.type)
                guard !typeNames.isEmpty else { continue }

                occurrences.append(
                    ComputedPropertyDeclarationRecord(
                        enclosingTypeName: enclosingTypeName,
                        name: pattern.identifier.text,
                        typeDescription: typeAnnotation.type.trimmedDescription,
                        typeNames: typeNames,
                        isStatic: isStatic,
                        position: pattern.identifier.positionAfterSkippingLeadingTrivia
                    )
                )
            }

            return .visitChildren
        }
    }

    nonisolated final class StoredMemberCollector: SyntaxVisitor {
        var occurrences: [StoredMemberDeclarationRecord] = []
        private var typeStack: [String] = []
        private var methodDepth = 0

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            if let identifierType = node.extendedType.as(IdentifierTypeSyntax.self) {
                typeStack.append(identifierType.name.text)
            } else if let memberType = node.extendedType.as(MemberTypeSyntax.self) {
                typeStack.append(memberType.name.text)
            }

            return .visitChildren
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            if node.extendedType.as(IdentifierTypeSyntax.self) != nil
                || node.extendedType.as(MemberTypeSyntax.self) != nil {
                _ = typeStack.popLast()
            }
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: StructDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            methodDepth += 1
            return .visitChildren
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            methodDepth -= 1
        }

        override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            methodDepth += 1
            return .visitChildren
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            methodDepth -= 1
        }

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            guard let enclosingTypeName = typeStack.last, methodDepth == 0 else {
                return .visitChildren
            }

            let isStatic = hasModifier(named: ["static", "class"], in: node.modifiers)

            for binding in node.bindings {
                guard binding.accessorBlock == nil else { continue }
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
                guard let typeAnnotation = binding.typeAnnotation else { continue }

                let typeNames = extractedTypeNames(from: typeAnnotation.type)
                guard !typeNames.isEmpty else { continue }

                occurrences.append(
                    StoredMemberDeclarationRecord(
                        enclosingTypeName: enclosingTypeName,
                        name: pattern.identifier.text,
                        typeNames: typeNames,
                        isStatic: isStatic,
                        position: pattern.identifier.positionAfterSkippingLeadingTrivia
                    )
                )
            }

            return .visitChildren
        }
    }

    nonisolated final class NestedNominalDeclarationCollector: SyntaxVisitor {
        var occurrences: [NestedNominalDeclarationRecord] = []
        private var typeStack: [String] = []

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            if let identifierType = node.extendedType.as(IdentifierTypeSyntax.self) {
                typeStack.append(identifierType.name.text)
            } else if let memberType = node.extendedType.as(MemberTypeSyntax.self) {
                typeStack.append(memberType.name.text)
            }

            return .visitChildren
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            if node.extendedType.as(IdentifierTypeSyntax.self) != nil
                || node.extendedType.as(MemberTypeSyntax.self) != nil {
                _ = typeStack.popLast()
            }
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            recordNestedDeclarationIfNeeded(
                enclosingTypeName: typeStack.last,
                name: node.name.text,
                kind: .struct,
                inheritedTypeNames: inheritedTypeNames(from: node.inheritanceClause),
                memberNames: memberNames(from: node.memberBlock),
                position: node.positionAfterSkippingLeadingTrivia
            )
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: StructDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            recordNestedDeclarationIfNeeded(
                enclosingTypeName: typeStack.last,
                name: node.name.text,
                kind: .class,
                inheritedTypeNames: inheritedTypeNames(from: node.inheritanceClause),
                memberNames: memberNames(from: node.memberBlock),
                position: node.positionAfterSkippingLeadingTrivia
            )
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            recordNestedDeclarationIfNeeded(
                enclosingTypeName: typeStack.last,
                name: node.name.text,
                kind: .actor,
                inheritedTypeNames: inheritedTypeNames(from: node.inheritanceClause),
                memberNames: memberNames(from: node.memberBlock),
                position: node.positionAfterSkippingLeadingTrivia
            )
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            recordNestedDeclarationIfNeeded(
                enclosingTypeName: typeStack.last,
                name: node.name.text,
                kind: .enum,
                inheritedTypeNames: inheritedTypeNames(from: node.inheritanceClause),
                memberNames: memberNames(from: node.memberBlock),
                position: node.positionAfterSkippingLeadingTrivia
            )
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            recordNestedDeclarationIfNeeded(
                enclosingTypeName: typeStack.last,
                name: node.name.text,
                kind: .protocol,
                inheritedTypeNames: inheritedTypeNames(from: node.inheritanceClause),
                memberNames: memberNames(from: node.memberBlock),
                position: node.positionAfterSkippingLeadingTrivia
            )
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            _ = typeStack.popLast()
        }

        private func recordNestedDeclarationIfNeeded(
            enclosingTypeName: String?,
            name: String,
            kind: NominalKind,
            inheritedTypeNames: [String],
            memberNames: [String],
            position: AbsolutePosition
        ) {
            guard let enclosingTypeName else {
                return
            }

            occurrences.append(
                NestedNominalDeclarationRecord(
                    enclosingTypeName: enclosingTypeName,
                    name: name,
                    kind: kind,
                    inheritedTypeNames: inheritedTypeNames,
                    memberNames: memberNames,
                    position: position
                )
            )
        }

        private func inheritedTypeNames(from inheritanceClause: InheritanceClauseSyntax?) -> [String] {
            guard let inheritanceClause else {
                return []
            }

            return inheritanceClause.inheritedTypes.compactMap { inheritedType in
                if let identifierType = inheritedType.type.as(IdentifierTypeSyntax.self) {
                    return identifierType.name.text
                }
                if let memberType = inheritedType.type.as(MemberTypeSyntax.self) {
                    return memberType.name.text
                }
                return inheritedType.type.trimmedDescription
                    .split(separator: ".")
                    .last
                    .map(String.init)
            }
        }

        private func memberNames(from memberBlock: MemberBlockSyntax) -> [String] {
            memberBlock.members.flatMap { member in
                if let variable = member.decl.as(VariableDeclSyntax.self) {
                    return variable.bindings.compactMap { binding in
                        binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
                    }
                }

                if let function = member.decl.as(FunctionDeclSyntax.self) {
                    return [function.name.text]
                }

                return []
            }
        }
    }

    nonisolated final class OperationalUseCollector: SyntaxVisitor {
        var occurrences: [OperationalUseOccurrenceRecord] = []
        private var typeStack: [String] = []
        private var methodStack: [String] = []
        private var nextBranchGroupIndex = 0

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            if let identifierType = node.extendedType.as(IdentifierTypeSyntax.self) {
                typeStack.append(identifierType.name.text)
            } else if let memberType = node.extendedType.as(MemberTypeSyntax.self) {
                typeStack.append(memberType.name.text)
            }

            return .visitChildren
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            if node.extendedType.as(IdentifierTypeSyntax.self) != nil
                || node.extendedType.as(MemberTypeSyntax.self) != nil {
                _ = typeStack.popLast()
            }
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: StructDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            typeStack.append(node.name.text)
            return .visitChildren
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            _ = typeStack.popLast()
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            methodStack.append(node.name.text)
            guard let enclosingTypeName = typeStack.last else {
                return .skipChildren
            }

            collectOperationalUses(
                in: Syntax(node.body),
                enclosingTypeName: enclosingTypeName,
                enclosingMethodName: node.name.text,
                branchGroupIndex: nil,
                branchArmIndex: nil
            )

            return .skipChildren
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            _ = methodStack.popLast()
        }

        private func collectOperationalUses(
            in node: Syntax?,
            enclosingTypeName: String,
            enclosingMethodName: String,
            branchGroupIndex: Int?,
            branchArmIndex: Int?
        ) {
            guard let node else {
                return
            }

            if let switchExpression = node.as(SwitchExprSyntax.self) {
                collectSwitchOperationalUses(
                    in: switchExpression,
                    enclosingTypeName: enclosingTypeName,
                    enclosingMethodName: enclosingMethodName
                )
                return
            }

            if let ifExpression = node.as(IfExprSyntax.self) {
                collectIfChainOperationalUses(
                    in: ifExpression,
                    enclosingTypeName: enclosingTypeName,
                    enclosingMethodName: enclosingMethodName
                )
                return
            }

            if let functionCall = node.as(FunctionCallExprSyntax.self) {
                appendOperationalUse(
                    from: functionCall,
                    enclosingTypeName: enclosingTypeName,
                    enclosingMethodName: enclosingMethodName,
                    branchGroupIndex: branchGroupIndex,
                    branchArmIndex: branchArmIndex
                )
            } else if let subscriptCall = node.as(SubscriptCallExprSyntax.self) {
                appendOperationalUse(
                    from: subscriptCall,
                    enclosingTypeName: enclosingTypeName,
                    enclosingMethodName: enclosingMethodName,
                    branchGroupIndex: branchGroupIndex,
                    branchArmIndex: branchArmIndex
                )
            }

            for child in node.children(viewMode: .sourceAccurate) {
                collectOperationalUses(
                    in: child,
                    enclosingTypeName: enclosingTypeName,
                    enclosingMethodName: enclosingMethodName,
                    branchGroupIndex: branchGroupIndex,
                    branchArmIndex: branchArmIndex
                )
            }
        }

        private func collectSwitchOperationalUses(
            in node: SwitchExprSyntax,
            enclosingTypeName: String,
            enclosingMethodName: String
        ) {
            let branchGroupIndex = nextBranchGroupIndex
            nextBranchGroupIndex += 1

            for (offset, switchCase) in node.cases.enumerated() {
                collectOperationalUses(
                    in: Syntax(switchCase),
                    enclosingTypeName: enclosingTypeName,
                    enclosingMethodName: enclosingMethodName,
                    branchGroupIndex: branchGroupIndex,
                    branchArmIndex: offset + 1
                )
            }
        }

        private func collectIfChainOperationalUses(
            in node: IfExprSyntax,
            enclosingTypeName: String,
            enclosingMethodName: String
        ) {
            let branchGroupIndex = nextBranchGroupIndex
            nextBranchGroupIndex += 1
            var currentIf: IfExprSyntax? = node
            var branchArmIndex = 1

            while let activeIf = currentIf {
                collectOperationalUses(
                    in: Syntax(activeIf.body),
                    enclosingTypeName: enclosingTypeName,
                    enclosingMethodName: enclosingMethodName,
                    branchGroupIndex: branchGroupIndex,
                    branchArmIndex: branchArmIndex
                )

                guard let elseBody = activeIf.elseBody else {
                    break
                }

                if let elseIf = elseBody.as(IfExprSyntax.self) {
                    currentIf = elseIf
                    branchArmIndex += 1
                    continue
                }

                collectOperationalUses(
                    in: Syntax(elseBody),
                    enclosingTypeName: enclosingTypeName,
                    enclosingMethodName: enclosingMethodName,
                    branchGroupIndex: branchGroupIndex,
                    branchArmIndex: branchArmIndex + 1
                )
                break
            }
        }

        private func appendOperationalUse(
            from node: FunctionCallExprSyntax,
            enclosingTypeName: String,
            enclosingMethodName: String,
            branchGroupIndex: Int?,
            branchArmIndex: Int?
        ) {
            if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
               let baseName = rootBaseName(from: memberAccess.base) {
                occurrences.append(
                    OperationalUseOccurrenceRecord(
                        enclosingTypeName: enclosingTypeName,
                        enclosingMethodName: enclosingMethodName,
                        baseName: baseName,
                        memberName: memberAccess.declName.baseName.text,
                        branchGroupIndex: branchGroupIndex,
                        branchArmIndex: branchArmIndex,
                        position: node.positionAfterSkippingLeadingTrivia
                    )
                )
            } else if let declReference = node.calledExpression.as(DeclReferenceExprSyntax.self) {
                let baseName = declReference.baseName.text
                if baseName != "self" {
                    occurrences.append(
                        OperationalUseOccurrenceRecord(
                            enclosingTypeName: enclosingTypeName,
                            enclosingMethodName: enclosingMethodName,
                            baseName: baseName,
                            memberName: "callAsFunction",
                            branchGroupIndex: branchGroupIndex,
                            branchArmIndex: branchArmIndex,
                            position: node.positionAfterSkippingLeadingTrivia
                        )
                    )
                }
            }
        }

        private func appendOperationalUse(
            from node: SubscriptCallExprSyntax,
            enclosingTypeName: String,
            enclosingMethodName: String,
            branchGroupIndex: Int?,
            branchArmIndex: Int?
        ) {
            guard let baseName = rootBaseName(from: node.calledExpression) else {
                return
            }

            occurrences.append(
                OperationalUseOccurrenceRecord(
                    enclosingTypeName: enclosingTypeName,
                    enclosingMethodName: enclosingMethodName,
                    baseName: baseName,
                    memberName: "subscript",
                    branchGroupIndex: branchGroupIndex,
                    branchArmIndex: branchArmIndex,
                    position: node.positionAfterSkippingLeadingTrivia
                )
            )
        }
    }

    private static func hasModifier(
        named modifierNames: Set<String>,
        in modifiers: DeclModifierListSyntax?
    ) -> Bool {
        guard let modifiers else {
            return false
        }

        return modifiers.contains { modifier in
            modifierNames.contains(modifier.name.text)
        }
    }

    private static func extractedTypeNames(from type: TypeSyntax) -> [String] {
        let collector = TypeReferenceCollector(viewMode: .sourceAccurate)
        collector.walk(type)
        return Array(Set(collector.occurrences.map(\.name)))
    }

    private static func isVoidLike(type: TypeSyntax) -> Bool {
        if let identifierType = type.as(IdentifierTypeSyntax.self) {
            return identifierType.name.text == "Void"
        }

        if let tupleType = type.as(TupleTypeSyntax.self) {
            return tupleType.elements.isEmpty
        }

        return type.trimmedDescription == "()"
    }

    private static func rootBaseName(from expression: ExprSyntax?) -> String? {
        guard let expression else {
            return nil
        }

        if let declReference = expression.as(DeclReferenceExprSyntax.self) {
            let name = declReference.baseName.text
            return name == "self" ? nil : name
        }

        if let memberAccess = expression.as(MemberAccessExprSyntax.self) {
            return rootBaseName(from: memberAccess.base) ?? memberAccess.declName.baseName.text
        }

        return nil
    }
}
