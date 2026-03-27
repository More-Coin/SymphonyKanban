import Foundation
import SwiftSyntax

struct LinterRepoRelativePathModel {
    func fromURLs(
        fileURL: URL,
        rootURL: URL
    ) -> String {
        let rootPath = rootURL.standardizedFileURL.path
        let filePath = fileURL.standardizedFileURL.path

        guard filePath.hasPrefix(rootPath) else {
            return fileURL.lastPathComponent
        }

        let trimmed = filePath.dropFirst(rootPath.count)
        return trimmed.hasPrefix("/") ? String(trimmed.dropFirst()) : String(trimmed)
    }
}

public struct NamedOccurrence: Sendable, Equatable {
    public let name: String
    public let position: AbsolutePosition

    public init(name: String, position: AbsolutePosition) {
        self.name = name
        self.position = position
    }
}

public struct ImportOccurrence: Sendable, Equatable {
    public let moduleName: String
    public let position: AbsolutePosition

    public init(moduleName: String, position: AbsolutePosition) {
        self.moduleName = moduleName
        self.position = position
    }
}

public struct StringLiteralOccurrence: Sendable, Equatable {
    public let value: String
    public let position: AbsolutePosition

    public init(value: String, position: AbsolutePosition) {
        self.value = value
        self.position = position
    }
}

public struct TypedMemberOccurrence: Sendable, Equatable {
    public let name: String
    public let typeNames: [String]
    public let position: AbsolutePosition

    public init(name: String, typeNames: [String], position: AbsolutePosition) {
        self.name = name
        self.typeNames = typeNames
        self.position = position
    }
}

public struct MemberCallOccurrence: Sendable, Equatable {
    public let baseName: String
    public let memberName: String
    public let position: AbsolutePosition

    public init(baseName: String, memberName: String, position: AbsolutePosition) {
        self.baseName = baseName
        self.memberName = memberName
        self.position = position
    }
}

public struct MethodDeclarationRecord: Sendable, Equatable {
    public let enclosingTypeName: String
    public let name: String
    public let isStatic: Bool
    public let isPublicOrOpen: Bool
    public let isPrivateOrFileprivate: Bool
    public let parameterTypeNames: [String]
    public let hasExplicitReturnType: Bool
    public let returnTypeDescription: String?
    public let returnTypeNames: [String]
    public let returnsVoidLike: Bool
    public let position: AbsolutePosition

    public init(
        enclosingTypeName: String,
        name: String,
        isStatic: Bool,
        isPublicOrOpen: Bool,
        isPrivateOrFileprivate: Bool,
        parameterTypeNames: [String],
        hasExplicitReturnType: Bool,
        returnTypeDescription: String?,
        returnTypeNames: [String],
        returnsVoidLike: Bool,
        position: AbsolutePosition
    ) {
        self.enclosingTypeName = enclosingTypeName
        self.name = name
        self.isStatic = isStatic
        self.isPublicOrOpen = isPublicOrOpen
        self.isPrivateOrFileprivate = isPrivateOrFileprivate
        self.parameterTypeNames = parameterTypeNames
        self.hasExplicitReturnType = hasExplicitReturnType
        self.returnTypeDescription = returnTypeDescription
        self.returnTypeNames = returnTypeNames
        self.returnsVoidLike = returnsVoidLike
        self.position = position
    }
}

public struct InitializerDeclarationRecord: Sendable, Equatable {
    public let enclosingTypeName: String
    public let parameterTypeNames: [String]
    public let position: AbsolutePosition

    public init(
        enclosingTypeName: String,
        parameterTypeNames: [String],
        position: AbsolutePosition
    ) {
        self.enclosingTypeName = enclosingTypeName
        self.parameterTypeNames = parameterTypeNames
        self.position = position
    }
}

public struct ComputedPropertyDeclarationRecord: Sendable, Equatable {
    public let enclosingTypeName: String
    public let name: String
    public let typeDescription: String
    public let typeNames: [String]
    public let isStatic: Bool
    public let position: AbsolutePosition

    public init(
        enclosingTypeName: String,
        name: String,
        typeDescription: String,
        typeNames: [String],
        isStatic: Bool,
        position: AbsolutePosition
    ) {
        self.enclosingTypeName = enclosingTypeName
        self.name = name
        self.typeDescription = typeDescription
        self.typeNames = typeNames
        self.isStatic = isStatic
        self.position = position
    }
}

public struct StoredMemberDeclarationRecord: Sendable, Equatable {
    public let enclosingTypeName: String
    public let name: String
    public let typeNames: [String]
    public let isStatic: Bool
    public let position: AbsolutePosition

    public init(
        enclosingTypeName: String,
        name: String,
        typeNames: [String],
        isStatic: Bool,
        position: AbsolutePosition
    ) {
        self.enclosingTypeName = enclosingTypeName
        self.name = name
        self.typeNames = typeNames
        self.isStatic = isStatic
        self.position = position
    }
}

public struct OperationalUseOccurrenceRecord: Sendable, Equatable {
    public let enclosingTypeName: String
    public let enclosingMethodName: String
    public let baseName: String
    public let memberName: String
    public let branchGroupIndex: Int?
    public let branchArmIndex: Int?
    public let position: AbsolutePosition

    public init(
        enclosingTypeName: String,
        enclosingMethodName: String,
        baseName: String,
        memberName: String,
        branchGroupIndex: Int?,
        branchArmIndex: Int?,
        position: AbsolutePosition
    ) {
        self.enclosingTypeName = enclosingTypeName
        self.enclosingMethodName = enclosingMethodName
        self.baseName = baseName
        self.memberName = memberName
        self.branchGroupIndex = branchGroupIndex
        self.branchArmIndex = branchArmIndex
        self.position = position
    }
}

public struct NestedNominalDeclarationRecord: Sendable, Equatable {
    public let enclosingTypeName: String
    public let name: String
    public let kind: NominalKind
    public let inheritedTypeNames: [String]
    public let memberNames: [String]
    public let position: AbsolutePosition

    public init(
        enclosingTypeName: String,
        name: String,
        kind: NominalKind,
        inheritedTypeNames: [String],
        memberNames: [String],
        position: AbsolutePosition
    ) {
        self.enclosingTypeName = enclosingTypeName
        self.name = name
        self.kind = kind
        self.inheritedTypeNames = inheritedTypeNames
        self.memberNames = memberNames
        self.position = position
    }
}

public struct TopLevelNominalDeclaration: Sendable, Equatable {
    public let name: String
    public let kind: NominalKind
    public let inheritedTypeNames: [String]
    public let memberNames: [String]
    public let position: AbsolutePosition

    public init(
        name: String,
        kind: NominalKind,
        inheritedTypeNames: [String],
        memberNames: [String],
        position: AbsolutePosition
    ) {
        self.name = name
        self.kind = kind
        self.inheritedTypeNames = inheritedTypeNames
        self.memberNames = memberNames
        self.position = position
    }
}

public struct SourceFileRecord {
    public let fileURL: URL
    public let repoRelativePath: String
    public let source: String
    public let syntaxTree: SourceFileSyntax
    public let converter: SourceLocationConverter
    public let classification: FileClassification
    public let imports: [ImportOccurrence]
    public let functionTypeOccurrences: [AbsolutePosition]
    public let identifierOccurrences: [NamedOccurrence]
    public let stringLiteralOccurrences: [StringLiteralOccurrence]
    public let typedMemberOccurrences: [TypedMemberOccurrence]
    public let memberCallOccurrences: [MemberCallOccurrence]
    public let methodDeclarations: [MethodDeclarationRecord]
    public let initializerDeclarations: [InitializerDeclarationRecord]
    public let computedPropertyDeclarations: [ComputedPropertyDeclarationRecord]
    public let storedMemberDeclarations: [StoredMemberDeclarationRecord]
    public let operationalUseOccurrences: [OperationalUseOccurrenceRecord]
    public let typeReferences: [NamedOccurrence]
    public let topLevelDeclarations: [TopLevelNominalDeclaration]
    public let nestedNominalDeclarations: [NestedNominalDeclarationRecord]

    public init(
        fileURL: URL,
        repoRelativePath: String,
        source: String,
        syntaxTree: SourceFileSyntax,
        converter: SourceLocationConverter,
        classification: FileClassification,
        imports: [ImportOccurrence],
        functionTypeOccurrences: [AbsolutePosition],
        identifierOccurrences: [NamedOccurrence],
        stringLiteralOccurrences: [StringLiteralOccurrence],
        typedMemberOccurrences: [TypedMemberOccurrence],
        memberCallOccurrences: [MemberCallOccurrence],
        methodDeclarations: [MethodDeclarationRecord],
        initializerDeclarations: [InitializerDeclarationRecord],
        computedPropertyDeclarations: [ComputedPropertyDeclarationRecord],
        storedMemberDeclarations: [StoredMemberDeclarationRecord],
        operationalUseOccurrences: [OperationalUseOccurrenceRecord],
        typeReferences: [NamedOccurrence],
        topLevelDeclarations: [TopLevelNominalDeclaration],
        nestedNominalDeclarations: [NestedNominalDeclarationRecord]
    ) {
        self.fileURL = fileURL
        self.repoRelativePath = repoRelativePath
        self.source = source
        self.syntaxTree = syntaxTree
        self.converter = converter
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

    public func firstImport(named moduleName: String) -> ImportOccurrence? {
        imports.first { $0.moduleName == moduleName }
    }

    public func firstIdentifier(named name: String) -> NamedOccurrence? {
        identifierOccurrences.first { $0.name == name }
    }

    public func firstTypeReference(named name: String) -> NamedOccurrence? {
        typeReferences.first { $0.name == name }
    }

    public func coordinate(for position: AbsolutePosition) -> SourceCoordinate {
        let location = converter.location(for: position)
        return SourceCoordinate(
            line: max(location.line, 1),
            column: max(location.column, 1)
        )
    }

    public func diagnostic(
        ruleID: String,
        message: String,
        position: AbsolutePosition? = nil
    ) -> ArchitectureDiagnostic {
        let coordinate = coordinate(for: position ?? AbsolutePosition(utf8Offset: 0))
        return ArchitectureDiagnostic(
            ruleID: ruleID,
            path: repoRelativePath,
            line: coordinate.line,
            column: coordinate.column,
            message: message
        )
    }
}
