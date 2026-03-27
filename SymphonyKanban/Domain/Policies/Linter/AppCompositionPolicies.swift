import Foundation

public struct AppConfigurationShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "app.configuration.shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        roleNamedDiagnostics(
            file: file,
            ruleID: Self.ruleID,
            matches: file.classification.isAppConfigurationFile,
            requiredSuffix: "Configuration",
            rolePath: "App/Configuration"
        )
    }
}

public struct AppRuntimeShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "app.runtime.shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        roleNamedDiagnostics(
            file: file,
            ruleID: Self.ruleID,
            matches: file.classification.isAppRuntimeFile,
            requiredSuffix: "Runtime",
            rolePath: "App/Runtime"
        )
    }
}

public struct AppDependencyInjectionShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "app.dependency_injection.shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        roleNamedDiagnostics(
            file: file,
            ruleID: Self.ruleID,
            matches: file.classification.isAppDependencyInjectionFile,
            requiredSuffix: "DI",
            rolePath: "App/DependencyInjection"
        )
    }
}

public struct CompositionRootInwardReferencePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "app.inward_reference"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.layer == .presentation || file.classification.layer == .infrastructure else {
            return []
        }

        var diagnostics: [ArchitectureDiagnostic] = []
        var seenNames = Set<String>()

        for reference in file.typeReferences {
            guard seenNames.insert(reference.name).inserted else { continue }
            guard let declaration = context.uniqueDeclaration(named: reference.name) else { continue }
            guard declaration.layer == .app else { continue }

            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Presentation and Infrastructure must not depend on composition-root type '\(reference.name)' from \(declaration.repoRelativePath).",
                    coordinate: reference.coordinate
                )
            )
        }

        return diagnostics
    }
}

private func roleNamedDiagnostics(
    file: ArchitectureFile,
    ruleID: String,
    matches: Bool,
    requiredSuffix: String,
    rolePath: String
) -> [ArchitectureDiagnostic] {
    guard matches else {
        return []
    }

    var diagnostics = file.topLevelDeclarations.compactMap { declaration -> ArchitectureDiagnostic? in
        guard declaration.kind != .protocol else {
            return file.diagnostic(
                ruleID: ruleID,
                message: "\(rolePath) should expose concrete types, not protocol '\(declaration.name)'.",
                coordinate: declaration.coordinate
            )
        }
        guard declaration.name.hasSuffix(requiredSuffix) else {
            return file.diagnostic(
                ruleID: ruleID,
                message: "\(rolePath) files are currently linted to expose concrete types ending in '\(requiredSuffix)'; rename or move '\(declaration.name)' if this file should stay in \(rolePath).",
                coordinate: declaration.coordinate
            )
        }
        return nil
    }

    let hasRequiredType = file.topLevelDeclarations.contains {
        $0.kind != .protocol && $0.name.hasSuffix(requiredSuffix)
    }

    if !hasRequiredType {
        diagnostics.append(
            file.diagnostic(
                ruleID: ruleID,
                message: "\(rolePath) files are currently linted to expose at least one concrete type ending in '\(requiredSuffix)'."
            )
        )
    }

    return diagnostics
}
