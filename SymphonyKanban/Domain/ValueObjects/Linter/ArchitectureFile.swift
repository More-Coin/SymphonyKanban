import Foundation

public struct ArchitectureFile: Sendable, Equatable {
    public let repoRelativePath: String
    public let classification: FileClassification
    public let imports: [ArchitectureImportOccurrence]
    public let functionTypeOccurrences: [ArchitectureFunctionTypeOccurrence]
    public let identifierOccurrences: [ArchitectureIdentifierOccurrence]
    public let stringLiteralOccurrences: [ArchitectureStringLiteralOccurrence]
    public let typedMemberOccurrences: [ArchitectureTypedMemberOccurrence]
    public let memberCallOccurrences: [ArchitectureMemberCallOccurrence]
    public let methodDeclarations: [ArchitectureMethodDeclaration]
    public let initializerDeclarations: [ArchitectureInitializerDeclaration]
    public let computedPropertyDeclarations: [ArchitectureComputedPropertyDeclaration]
    public let storedMemberDeclarations: [ArchitectureStoredMemberDeclaration]
    public let operationalUseOccurrences: [ArchitectureOperationalUseOccurrence]
    public let typeReferences: [ArchitectureTypeReference]
    public let topLevelDeclarations: [ArchitectureTopLevelDeclaration]
    public let nestedNominalDeclarations: [ArchitectureNestedNominalDeclaration]

    public init(
        repoRelativePath: String,
        classification: FileClassification,
        imports: [ArchitectureImportOccurrence],
        functionTypeOccurrences: [ArchitectureFunctionTypeOccurrence],
        identifierOccurrences: [ArchitectureIdentifierOccurrence],
        stringLiteralOccurrences: [ArchitectureStringLiteralOccurrence],
        typedMemberOccurrences: [ArchitectureTypedMemberOccurrence],
        memberCallOccurrences: [ArchitectureMemberCallOccurrence],
        methodDeclarations: [ArchitectureMethodDeclaration],
        initializerDeclarations: [ArchitectureInitializerDeclaration],
        computedPropertyDeclarations: [ArchitectureComputedPropertyDeclaration],
        storedMemberDeclarations: [ArchitectureStoredMemberDeclaration],
        operationalUseOccurrences: [ArchitectureOperationalUseOccurrence],
        typeReferences: [ArchitectureTypeReference],
        topLevelDeclarations: [ArchitectureTopLevelDeclaration],
        nestedNominalDeclarations: [ArchitectureNestedNominalDeclaration]
    ) {
        self.repoRelativePath = repoRelativePath
        self.classification = classification
        self.imports = imports
        self.functionTypeOccurrences = functionTypeOccurrences
        self.identifierOccurrences = identifierOccurrences
        self.stringLiteralOccurrences = stringLiteralOccurrences
        self.typedMemberOccurrences = typedMemberOccurrences
        self.memberCallOccurrences = memberCallOccurrences
        self.methodDeclarations = methodDeclarations
        self.initializerDeclarations = initializerDeclarations
        self.computedPropertyDeclarations = computedPropertyDeclarations
        self.storedMemberDeclarations = storedMemberDeclarations
        self.operationalUseOccurrences = operationalUseOccurrences
        self.typeReferences = typeReferences
        self.topLevelDeclarations = topLevelDeclarations
        self.nestedNominalDeclarations = nestedNominalDeclarations
    }

    public func diagnostic(
        ruleID: String,
        message: String,
        coordinate: SourceCoordinate? = nil
    ) -> ArchitectureDiagnostic {
        let coordinate = coordinate ?? SourceCoordinate(line: 1, column: 1)
        return ArchitectureDiagnostic(
            ruleID: ruleID,
            path: repoRelativePath,
            line: coordinate.line,
            column: coordinate.column,
            message: message
        )
    }
}
