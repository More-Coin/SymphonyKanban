import Foundation

public struct PresentationControllerShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "presentation.controllers.shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isControllerFile else {
            return []
        }

        let hasControllerType = file.topLevelDeclarations.contains { $0.name.hasSuffix("Controller") }
        guard !hasControllerType else {
            return []
        }

        return [
            file.diagnostic(
                ruleID: Self.ruleID,
                message: "Presentation/Controllers files must expose at least one controller-shaped top-level type ending in 'Controller'."
            )
        ]
    }
}

public struct PresentationControllersServiceReferencePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "presentation.controllers.service_reference"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isControllerFile else {
            return []
        }

        let hasServiceReference = file.typeReferences.contains { reference in
            guard let declaration = context.uniqueDeclaration(named: reference.name) else {
                return false
            }
            return declaration.roleFolder == .applicationServices
        }

        guard !hasServiceReference else {
            return []
        }

        return [
            file.diagnostic(
                ruleID: Self.ruleID,
                message: "Presentation controllers must depend on an Application service from Application/Services and call that service rather than orchestrating workflow directly."
            )
        ]
    }
}

public struct PresentationControllersUseCaseReferencePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "presentation.controllers.usecase_reference"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isControllerFile else {
            return []
        }

        var diagnostics: [ArchitectureDiagnostic] = []
        var seenNames = Set<String>()

        for reference in file.typeReferences {
            guard seenNames.insert(reference.name).inserted else { continue }
            guard let declaration = context.uniqueDeclaration(named: reference.name) else { continue }
            guard declaration.roleFolder == .applicationUseCases else { continue }

            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Presentation controllers must call Application services, not use case '\(reference.name)' from \(declaration.repoRelativePath). Move orchestration behind a service.",
                    coordinate: reference.coordinate
                )
            )
        }

        return diagnostics
    }
}

public struct PresentationControllersFunctionSeamPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "presentation.controllers.function_seam"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isControllerFile else {
            return []
        }

        return file.functionTypeOccurrences.map { occurrence in
            file.diagnostic(
                ruleID: Self.ruleID,
                message: "Presentation controllers must not depend on arbitrary function or closure seams for workflow execution. Inject an Application service instead.",
                coordinate: occurrence.coordinate
            )
        }
    }
}

public struct PresentationRouteShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "presentation.routes.shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.roleFolder == .presentationRoutes else {
            return []
        }

        let hasRouteType = file.topLevelDeclarations.contains { $0.name.hasSuffix("Routes") }
        guard !hasRouteType else {
            return []
        }

        return [
            file.diagnostic(
                ruleID: Self.ruleID,
                message: "Presentation/Routes files must expose at least one route-shaped top-level type ending in 'Routes'."
            )
        ]
    }
}

public struct PresentationDTOsShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "presentation.dtos.shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isPresentationDTOFile else {
            return []
        }

        var diagnostics = file.topLevelDeclarations.compactMap { declaration -> ArchitectureDiagnostic? in
            switch declaration.kind {
            case .protocol:
                return file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Presentation/DTOs should expose transport-shape types, not protocol '\(declaration.name)'.",
                    coordinate: declaration.coordinate
                )
            case .class, .actor:
                return file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Presentation/DTOs should expose simple transport shapes, not \(declaration.kind.rawValue) '\(declaration.name)'.",
                    coordinate: declaration.coordinate
                )
            case .struct, .enum:
                guard declaration.name.hasSuffix("DTO") || declaration.name.hasSuffix("DTOs") || declaration.name.hasSuffix("QueryParams") else {
                    return file.diagnostic(
                        ruleID: Self.ruleID,
                        message: "Presentation DTO types should end in 'DTO', 'DTOs', or 'QueryParams'; rename '\(declaration.name)'.",
                        coordinate: declaration.coordinate
                    )
                }
                return nil
            }
        }

        let hasDTOType = file.topLevelDeclarations.contains {
            ($0.kind == .struct || $0.kind == .enum)
                && ($0.name.hasSuffix("DTO") || $0.name.hasSuffix("DTOs") || $0.name.hasSuffix("QueryParams"))
        }

        if !hasDTOType {
            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Presentation/DTOs files must expose at least one transport-shaped type ending in 'DTO', 'DTOs', or 'QueryParams'."
                )
            )
        }

        return diagnostics
    }
}

public struct PresentationPresentersShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "presentation.presenters.shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        presentationRoleNamedDiagnostics(file: file, ruleID: Self.ruleID, matches: file.classification.isPresentationPresenterFile, requiredSuffix: "Presenter", rolePath: "Presentation/Presenters")
    }
}

public struct PresentationRenderersShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "presentation.renderers.shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        presentationRoleNamedDiagnostics(file: file, ruleID: Self.ruleID, matches: file.classification.isPresentationRendererFile, requiredSuffix: "Renderer", rolePath: "Presentation/Renderers")
    }
}

public struct PresentationMiddlewareShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "presentation.middleware.shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        presentationRoleNamedDiagnostics(file: file, ruleID: Self.ruleID, matches: file.classification.isPresentationMiddlewareFile, requiredSuffix: "Middleware", rolePath: "Presentation/Middleware")
    }
}

public struct PresentationErrorsShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "presentation.errors.shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isPresentationErrorFile else {
            return []
        }
        return structuredErrorDiagnostics(
            file: file,
            ruleID: Self.ruleID,
            rolePath: "Presentation/Errors",
            namingDescription: "...PresentationError or ...PresentationErrors",
            namingValidator: { declaration in
                declaration.name.hasSuffix("PresentationError")
                    || declaration.name.hasSuffix("PresentationErrors")
            }
        )
    }
}

public struct PresentationErrorsPlacementPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "presentation.errors.placement"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isPresentation else {
            return []
        }
        guard !file.classification.isPresentationErrorFile else {
            return []
        }

        return structuredErrorPlacementDiagnostics(
            file: file,
            ruleID: Self.ruleID,
            rolePath: "Presentation/Errors",
            namingValidator: { declaration in
                declaration.name.hasSuffix("PresentationError")
                    || declaration.name.hasSuffix("PresentationErrors")
            }
        )
    }
}

public struct PresentationViewModelsShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "presentation.viewmodels.shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        presentationRoleNamedDiagnostics(file: file, ruleID: Self.ruleID, matches: file.classification.isPresentationViewModelFile, requiredSuffix: "ViewModel", rolePath: "Presentation/ViewModels")
    }
}

public struct PresentationViewsShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "presentation.views.shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        presentationRoleNamedDiagnostics(file: file, ruleID: Self.ruleID, matches: file.classification.isPresentationViewFile, requiredSuffix: "View", rolePath: "Presentation/Views")
    }
}

public struct PresentationStylesShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "presentation.styles.shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        presentationRoleNamedDiagnostics(file: file, ruleID: Self.ruleID, matches: file.classification.isPresentationStyleFile, requiredSuffix: "Style", rolePath: "Presentation/Styles")
    }
}

public struct PresentationInfrastructureReferencePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "presentation.infrastructure_reference"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isPresentation else {
            return []
        }

        var diagnostics: [ArchitectureDiagnostic] = []
        var seenNames = Set<String>()

        for reference in file.typeReferences {
            guard seenNames.insert(reference.name).inserted else { continue }
            guard let declaration = context.uniqueDeclaration(named: reference.name) else { continue }
            guard declaration.layer == .infrastructure else { continue }

            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Presentation must not depend on infrastructure type '\(reference.name)' from \(declaration.repoRelativePath).",
                    coordinate: reference.coordinate
                )
            )
        }

        return diagnostics
    }
}

private func presentationRoleNamedDiagnostics(
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
                message: "\(rolePath) files should expose types ending in '\(requiredSuffix)'; rename or move '\(declaration.name)'.",
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
                message: "\(rolePath) files must expose at least one type ending in '\(requiredSuffix)'."
            )
        )
    }

    return diagnostics
}
