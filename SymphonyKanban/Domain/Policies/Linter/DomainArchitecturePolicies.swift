import Foundation

public struct DomainForbiddenImportPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "domain.forbidden_import"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isDomain else {
            return []
        }

        return file.imports.compactMap { importOccurrence in
            guard DomainPolicyForbiddenAPIs.platformModules.contains(importOccurrence.moduleName) else {
                return nil
            }
            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Domain files must remain framework-free; move import '\(importOccurrence.moduleName)' to Presentation, App, or Infrastructure.",
                coordinate: importOccurrence.coordinate
            )
        }
    }
}

public struct DomainOuterLayerReferencePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "domain.outer_layer_reference"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isDomain else {
            return []
        }

        var diagnostics: [ArchitectureDiagnostic] = []
        var seenNames = Set<String>()

        for reference in file.typeReferences {
            guard seenNames.insert(reference.name).inserted else { continue }
            guard let declaration = context.uniqueDeclaration(named: reference.name) else { continue }
            guard declaration.layer != .domain else { continue }

            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Domain files must not reference App, Application, Infrastructure, or Presentation type '\(reference.name)' from \(declaration.repoRelativePath).",
                    coordinate: reference.coordinate
                )
            )
        }

        return diagnostics
    }
}

public struct DomainDurableStructurePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "domain.durable_structure"
    private let allowedTopLevelFolders: Set<String> = [
        "Entities",
        "ValueObjects",
        "Policies",
        "Protocols",
        "Errors"
    ]

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isDomain else {
            return []
        }

        guard let domainIndex = file.classification.pathComponents.firstIndex(of: "Domain") else {
            return []
        }

        let nextIndex = domainIndex + 1
        guard file.classification.pathComponents.indices.contains(nextIndex) else {
            return [
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Domain files must live under the durable Domain folders: Entities, ValueObjects, Policies, Protocols, or Errors."
                )
            ]
        }

        let topLevelFolder = file.classification.pathComponents[nextIndex]
        guard !topLevelFolder.hasSuffix(".swift") else {
            return [
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Domain files must live under the durable Domain folders: Entities, ValueObjects, Policies, Protocols, or Errors."
                )
            ]
        }

        guard !allowedTopLevelFolders.contains(topLevelFolder) else {
            return []
        }

        return [
            file.diagnostic(
                ruleID: Self.ruleID,
                message: "Domain/\(topLevelFolder) is not part of the durable Domain structure. Move this file under Entities, ValueObjects, Policies, Protocols, or Errors."
            )
        ]
    }
}

public struct DomainPolicyPurityPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "domain.policy_forbidden_api"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isPolicyFile else {
            return []
        }

        return forbiddenIdentifierDiagnostics(
            file: file,
            ruleID: Self.ruleID,
            forbiddenIdentifiers: DomainPolicyForbiddenAPIs.platformTypes,
            messagePrefix: "Domain policy files must remain pure and must not use platform or I/O API"
        )
    }
}

public struct DomainPolicyShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "domain.policy_shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.roleFolder == .domainPolicies else {
            return []
        }

        var diagnostics = file.topLevelDeclarations.compactMap { declaration -> ArchitectureDiagnostic? in
            guard declaration.kind == .protocol else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Domain/Policies should expose concrete policy types, not protocol '\(declaration.name)'. Move capability contracts to Domain/Protocols.",
                coordinate: declaration.coordinate
            )
        }

        let hasPolicyType = file.topLevelDeclarations.contains { declaration in
            declaration.name.hasSuffix("Policy")
        }

        if !hasPolicyType {
            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Domain/Policies files must expose at least one policy-shaped top-level type ending in 'Policy'."
                )
            )
        }

        return diagnostics
    }
}

public struct DomainProtocolNamingPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "domain.protocol_naming"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.roleFolder == .domainProtocols else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind == .protocol else {
                return nil
            }
            guard !isRepositoryProtocolName(declaration.name) else {
                return nil
            }
            guard !declaration.name.hasSuffix("Protocol") else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Domain capability protocols should use role-revealing names ending in 'Protocol'. Rename '\(declaration.name)' or move it to a more appropriate folder.",
                coordinate: declaration.coordinate
            )
        }
    }
}

public struct DomainErrorsShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "domain.errors.shape"
    public static let surfaceRuleID = "domain.errors.surface"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isDomainErrorFile else {
            return []
        }
        var diagnostics = structuredErrorDiagnostics(
            file: file,
            ruleID: Self.ruleID,
            rolePath: "Domain/Errors",
            namingDescription: "SharedDomainError, <Feature>Error, or <Feature>DomainError",
            namingValidator: { declaration in
                declaration.name == "SharedDomainError"
                    || declaration.name.hasSuffix("DomainError")
                    || declaration.name.hasSuffix("Error")
            }
        )

        diagnostics.append(
            contentsOf: structuredErrorSurfaceDiagnostics(
                file: file,
                ruleID: Self.surfaceRuleID,
                rolePath: "Domain/Errors",
                forbiddenTerms: structuredErrorForbiddenSurfaceTerms
            )
        )

        return diagnostics
    }
}

public struct DomainErrorsPlacementPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "domain.errors.placement"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isDomain else {
            return []
        }
        guard !file.classification.isDomainErrorFile else {
            return []
        }

        return structuredErrorPlacementDiagnostics(
            file: file,
            ruleID: Self.ruleID,
            rolePath: "Domain/Errors",
            namingValidator: { declaration in
                declaration.name == "SharedDomainError"
                    || declaration.name.hasSuffix("DomainError")
                    || declaration.name.hasSuffix("Error")
            }
        )
    }
}

public struct RepositoryProtocolPlacementPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "domain.repository_protocol_placement"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind == .protocol, isRepositoryLikeName(declaration.name) else {
                return nil
            }
            guard file.classification.isDomain, file.classification.roleFolder == .domainProtocols else {
                return file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Repository protocols belong in Domain/Protocols; move '\(declaration.name)' out of \(file.repoRelativePath).",
                    coordinate: declaration.coordinate
                )
            }
            return nil
        }
    }
}

private enum DomainPolicyForbiddenAPIs {
    static let platformModules: Set<String> = ["SwiftUI", "AppKit", "Combine", "OSLog", "SwiftData"]
    static let platformTypes: Set<String> = [
        "Process",
        "FileManager",
        "Bundle",
        "UserDefaults",
        "URLSession",
        "NSWorkspace",
        "NSOpenPanel"
    ]
}

let structuredErrorRequiredMemberNames: Set<String> = ["code", "message", "retryable", "details"]

func structuredErrorDiagnostics(
    file: ArchitectureFile,
    ruleID: String,
    rolePath: String,
    namingDescription: String,
    namingValidator: (ArchitectureTopLevelDeclaration) -> Bool
) -> [ArchitectureDiagnostic] {
    var diagnostics: [ArchitectureDiagnostic] = []

    let concreteDeclarations = file.topLevelDeclarations.filter { $0.kind != .protocol }
    let fileBaseName = structuredErrorFileBaseName(file.repoRelativePath)

    if concreteDeclarations.count > 1 {
        diagnostics.append(
            file.diagnostic(
                ruleID: ruleID,
                message: "\(rolePath) files should be dedicated error files with one structured error type per file."
            )
        )
    }

    diagnostics.append(contentsOf: file.topLevelDeclarations.compactMap { declaration in
        guard declaration.kind == .protocol else {
            return nil
        }

        return file.diagnostic(
            ruleID: ruleID,
            message: "\(rolePath) should expose concrete structured error types, not protocol '\(declaration.name)'.",
            coordinate: declaration.coordinate
        )
    })

    let structuredErrorDeclarations = concreteDeclarations.filter { declaration in
        isStructuredErrorDeclaration(declaration, namingValidator: namingValidator)
    }

    if structuredErrorDeclarations.isEmpty {
        diagnostics.append(
            file.diagnostic(
                ruleID: ruleID,
                message: "\(rolePath) files should expose structured error types named \(namingDescription) and expose code, message, retryable, and details."
            )
        )
        return diagnostics
    }

    if !structuredErrorDeclarations.contains(where: { $0.name == fileBaseName }) {
        diagnostics.append(
            file.diagnostic(
                ruleID: ruleID,
                message: "For clarity, \(rolePath) files should be named after the structured error type they contain. Rename this file to match the error type."
            )
        )
    }

    for declaration in concreteDeclarations {
        guard namingValidator(declaration)
            || isStructuredErrorDeclaration(declaration, namingValidator: namingValidator)
        else {
            diagnostics.append(
                file.diagnostic(
                    ruleID: ruleID,
                    message: "\(rolePath) should expose structured error types named \(namingDescription); rename or move '\(declaration.name)'.",
                    coordinate: declaration.coordinate
                )
            )
            continue
        }

        if !declaration.inheritedTypeNames.contains("StructuredErrorProtocol") {
            diagnostics.append(
                file.diagnostic(
                    ruleID: ruleID,
                    message: "\(declaration.name) must conform to StructuredErrorProtocol.",
                    coordinate: declaration.coordinate
                )
            )
        }

        let memberNames = Set(declaration.memberNames)
        let missingMemberNames = structuredErrorRequiredMemberNames.subtracting(memberNames).sorted()
        guard !missingMemberNames.isEmpty else {
            continue
        }

        diagnostics.append(
            file.diagnostic(
                ruleID: ruleID,
                message: "\(declaration.name) should expose structured error members code, message, retryable, and details. Missing: \(missingMemberNames.joined(separator: ", ")).",
                coordinate: declaration.coordinate
            )
        )
    }

    return diagnostics
}

func structuredErrorPlacementDiagnostics(
    file: ArchitectureFile,
    ruleID: String,
    rolePath: String,
    namingValidator: (ArchitectureTopLevelDeclaration) -> Bool
) -> [ArchitectureDiagnostic] {
    file.topLevelDeclarations.compactMap { declaration in
        guard declaration.kind != .protocol else {
            return nil
        }
        guard isStructuredErrorDeclaration(declaration, namingValidator: namingValidator) else {
            return nil
        }

        return file.diagnostic(
            ruleID: ruleID,
            message: "Structured error type '\(declaration.name)' must live in \(rolePath), not in \(file.repoRelativePath). For clarity, structured error files should be dedicated and named after the error type.",
            coordinate: declaration.coordinate
        )
    }
}

private func structuredErrorFileBaseName(_ repoRelativePath: String) -> String {
    let fileName = repoRelativePath.split(separator: "/").last.map(String.init) ?? repoRelativePath
    return fileName.hasSuffix(".swift") ? String(fileName.dropLast(6)) : fileName
}

private func isStructuredErrorDeclaration(
    _ declaration: ArchitectureTopLevelDeclaration,
    namingValidator: (ArchitectureTopLevelDeclaration) -> Bool
) -> Bool {
    guard declaration.kind != .protocol else {
        return false
    }

    return namingValidator(declaration)
        || declaration.inheritedTypeNames.contains("StructuredErrorProtocol")
        || declaration.inheritedTypeNames.contains("Error")
        || declaration.inheritedTypeNames.contains("LocalizedError")
        || structuredErrorRequiredMemberNames.isSubset(of: Set(declaration.memberNames))
}

private func forbiddenIdentifierDiagnostics(
    file: ArchitectureFile,
    ruleID: String,
    forbiddenIdentifiers: Set<String>,
    messagePrefix: String
) -> [ArchitectureDiagnostic] {
    var diagnostics: [ArchitectureDiagnostic] = []
    var seenNames = Set<String>()

    for occurrence in file.identifierOccurrences {
        guard forbiddenIdentifiers.contains(occurrence.name) else { continue }
        guard seenNames.insert(occurrence.name).inserted else { continue }
        diagnostics.append(
            file.diagnostic(
                ruleID: ruleID,
                message: "\(messagePrefix) '\(occurrence.name)'.",
                coordinate: occurrence.coordinate
            )
        )
    }

    return diagnostics
}

let structuredErrorForbiddenSurfaceTerms: Set<String> = [
    "codex",
    "github",
    "gitlab",
    "jira",
    "linear",
    "openai",
    "workflow.md"
]

func structuredErrorSurfaceDiagnostics(
    file: ArchitectureFile,
    ruleID: String,
    rolePath: String,
    forbiddenTerms: Set<String>
) -> [ArchitectureDiagnostic] {
    guard file.topLevelDeclarations.contains(where: {
        $0.kind != .protocol
            && (
                $0.inheritedTypeNames.contains("StructuredErrorProtocol")
                    || $0.inheritedTypeNames.contains("Error")
                    || $0.inheritedTypeNames.contains("LocalizedError")
                    || structuredErrorRequiredMemberNames.isSubset(of: Set($0.memberNames))
            )
    }) else {
        return []
    }

    var diagnostics: [ArchitectureDiagnostic] = []
    var seenTerms = Set<String>()

    for occurrence in file.identifierOccurrences {
        let normalizedName = occurrence.name.lowercased()
        guard forbiddenTerms.contains(normalizedName) else { continue }
        guard seenTerms.insert(normalizedName).inserted else { continue }
        diagnostics.append(
            file.diagnostic(
                ruleID: ruleID,
                message: "\(rolePath) structured errors must stay transport agnostic and must not use provider or other boundary vocabulary; remove '\(occurrence.name)'.",
                coordinate: occurrence.coordinate
            )
        )
    }

    for occurrence in file.stringLiteralOccurrences {
        let normalizedValue = occurrence.value.lowercased()
        guard let matchedTerm = forbiddenTerms.first(where: { normalizedValue.contains($0) }) else {
            continue
        }
        guard seenTerms.insert(matchedTerm).inserted else { continue }
        diagnostics.append(
            file.diagnostic(
                ruleID: ruleID,
                message: "\(rolePath) structured errors must stay transport agnostic and must not use provider or other boundary vocabulary; remove '\(matchedTerm)'.",
                coordinate: occurrence.coordinate
            )
        )
    }

    return diagnostics
}

private func isRepositoryLikeName(_ name: String) -> Bool {
    isRepositoryProtocolName(name) || name.hasSuffix("Repository")
}

private func isRepositoryProtocolName(_ name: String) -> Bool {
    name.hasSuffix("RepositoryProtocol")
}
