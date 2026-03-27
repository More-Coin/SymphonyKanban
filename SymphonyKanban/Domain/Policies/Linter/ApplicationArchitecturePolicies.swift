import Foundation

public struct ApplicationOuterLayerReferencePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.outer_layer_reference"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplication else {
            return []
        }

        var diagnostics: [ArchitectureDiagnostic] = []
        var seenNames = Set<String>()

        for reference in file.typeReferences {
            guard seenNames.insert(reference.name).inserted else { continue }
            guard let declaration = context.uniqueDeclaration(named: reference.name) else { continue }
            guard declaration.layer == .presentation || declaration.layer == .app else {
                continue
            }

            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Application files must not reference Presentation or App composition-root type '\(reference.name)' from \(declaration.repoRelativePath). Keep transport concerns in Presentation and startup or wiring concerns in App.",
                    coordinate: reference.coordinate
                )
            )
        }

        return diagnostics
    }
}

public struct ApplicationPortProtocolsShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.port_protocols.shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationPortProtocolFile else {
            return []
        }

        var diagnostics = forbiddenIdentifierDiagnostics(
            file: file,
            ruleID: Self.ruleID,
            forbiddenIdentifiers: ApplicationPolicyForbiddenAPIs.platformTypes,
            messagePrefix: "Application port protocol files define technical seams only and must not use platform API"
        )

        diagnostics.append(contentsOf: file.topLevelDeclarations.compactMap { declaration in
            switch declaration.kind {
            case .class, .actor, .struct, .enum:
                return file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Application/Ports/Protocols should expose port protocols only; move concrete \(declaration.kind.rawValue) '\(declaration.name)' to Infrastructure if it is a boundary implementation, or to Contracts if it is an application-owned data shape.",
                    coordinate: declaration.coordinate
                )
            case .protocol:
                guard declaration.name.hasSuffix("PortProtocol") else {
                    return file.diagnostic(
                        ruleID: Self.ruleID,
                        message: "Application port protocols should end in 'PortProtocol'; rename '\(declaration.name)'.",
                        coordinate: declaration.coordinate
                    )
                }
                return nil
            }
        })

        let hasPortProtocol = file.topLevelDeclarations.contains {
            $0.kind == .protocol && $0.name.hasSuffix("PortProtocol")
        }

        if !hasPortProtocol {
            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Application/Ports/Protocols files must expose at least one protocol ending in 'PortProtocol'."
                )
            )
        }

        return diagnostics
    }
}

public struct ApplicationContractsShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.contracts.shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationContractFile else {
            return []
        }

        var diagnostics = forbiddenIdentifierDiagnostics(
            file: file,
            ruleID: Self.ruleID,
            forbiddenIdentifiers: ApplicationPolicyForbiddenAPIs.platformTypes,
            messagePrefix: "Application contract files define application-owned data shapes and must not use platform API"
        )

        diagnostics.append(contentsOf: file.topLevelDeclarations.compactMap { declaration in
            switch declaration.kind {
            case .protocol:
                return file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Application contracts are data shapes, not protocols. Move '\(declaration.name)' to Application/Ports/Protocols if it is a seam.",
                    coordinate: declaration.coordinate
                )
            case .class, .actor:
                return file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Application contracts should be simple value shapes, not concrete \(declaration.kind.rawValue)s like '\(declaration.name)'.",
                    coordinate: declaration.coordinate
                )
            case .struct, .enum:
                guard declaration.name.hasSuffix("Contract") else {
                    return file.diagnostic(
                        ruleID: Self.ruleID,
                        message: "Anything under Application/Contracts should end in 'Contract'; rename '\(declaration.name)'.",
                        coordinate: declaration.coordinate
                    )
                }
                return nil
            }
        })

        let hasContractType = file.topLevelDeclarations.contains {
            ($0.kind == .struct || $0.kind == .enum) && $0.name.hasSuffix("Contract")
        }

        if !hasContractType {
            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Application contract files must expose at least one struct or enum ending in 'Contract'."
                )
            )
        }

        return diagnostics
    }
}

public struct ApplicationContractsNestedErrorPlacementPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.contracts.nested_error_placement"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationContractFile else {
            return []
        }

        return file.nestedNominalDeclarations.compactMap { declaration in
            guard isErrorShapedContractNestedDeclaration(declaration) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Application contract files must not declare nested error-shaped type '\(declaration.name)' inside '\(declaration.enclosingTypeName)'. Move the error type to Application/Errors and reference it from the contract instead.",
                coordinate: declaration.coordinate
            )
        }
    }
}

public struct ApplicationContractsNoErrorMappingSurfacePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.contracts.no_error_mapping_surface"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationContractFile else {
            return []
        }

        var diagnostics: [ArchitectureDiagnostic] = []

        diagnostics.append(contentsOf: file.initializerDeclarations.compactMap { declaration in
            guard declaration.parameterTypeNames.contains(where: { isErrorShapedTypeName($0, context: context) }) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: applicationContractErrorMappingSurfaceMessage(
                    surfaceDescription: "Initializer '\(declaration.enclosingTypeName).init(...)'"
                ),
                coordinate: declaration.coordinate
            )
        })

        diagnostics.append(contentsOf: file.methodDeclarations.compactMap { declaration in
            if declaration.parameterTypeNames.contains(where: { isErrorShapedTypeName($0, context: context) }) {
                return file.diagnostic(
                    ruleID: Self.ruleID,
                    message: applicationContractErrorMappingSurfaceMessage(
                        surfaceDescription: "Method '\(declaration.name)' on contract '\(declaration.enclosingTypeName)'"
                    ),
                    coordinate: declaration.coordinate
                )
            }
            
            return nil
        })

        return diagnostics
    }
}

public struct ApplicationContractsNoCollaboratorDependenciesPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.contracts.no_collaborator_dependencies"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationContractFile else {
            return []
        }

        var seenForbiddenDependencyNames = Set<String>()
        var diagnostics: [ArchitectureDiagnostic] = []

        diagnostics.append(contentsOf: file.typeReferences.compactMap { reference -> ArchitectureDiagnostic? in
            guard isForbiddenApplicationContractDependencyTypeName(
                reference.name,
                context: context
            ) else {
                return nil
            }

            let dependencyName = canonicalArchitectureTypeName(reference.name)

            guard seenForbiddenDependencyNames.insert(dependencyName).inserted else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: applicationContractCollaboratorDependencyMessage(
                        dependencyName: dependencyName,
                        declaration: context.uniqueDeclaration(named: dependencyName)
                    ),
                coordinate: reference.coordinate
            )
        })

        diagnostics.append(contentsOf: file.identifierOccurrences.compactMap { occurrence -> ArchitectureDiagnostic? in
            guard isForbiddenApplicationContractDependencyTypeName(
                occurrence.name,
                context: context
            ) else {
                return nil
            }

            let dependencyName = canonicalArchitectureTypeName(occurrence.name)

            guard seenForbiddenDependencyNames.insert(dependencyName).inserted else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: applicationContractCollaboratorDependencyMessage(
                    dependencyName: dependencyName,
                    declaration: context.uniqueDeclaration(named: dependencyName)
                ),
                coordinate: occurrence.coordinate
            )
        })

        diagnostics.append(contentsOf: file.methodDeclarations.flatMap { declaration in
            declaration.parameterTypeNames.compactMap { rawDependencyName -> ArchitectureDiagnostic? in
                guard isForbiddenApplicationContractDependencyTypeName(rawDependencyName, context: context) else {
                    return nil
                }

                let dependencyName = canonicalArchitectureTypeName(rawDependencyName)

                guard seenForbiddenDependencyNames.insert(dependencyName).inserted else {
                    return nil
                }

                return file.diagnostic(
                    ruleID: Self.ruleID,
                    message: applicationContractCollaboratorDependencyMessage(
                        dependencyName: dependencyName,
                        declaration: context.uniqueDeclaration(named: dependencyName)
                    ),
                    coordinate: declaration.coordinate
                )
            }
        })

        diagnostics.append(contentsOf: file.initializerDeclarations.flatMap { declaration in
            declaration.parameterTypeNames.compactMap { rawDependencyName -> ArchitectureDiagnostic? in
                guard isForbiddenApplicationContractDependencyTypeName(rawDependencyName, context: context) else {
                    return nil
                }

                let dependencyName = canonicalArchitectureTypeName(rawDependencyName)

                guard seenForbiddenDependencyNames.insert(dependencyName).inserted else {
                    return nil
                }

                return file.diagnostic(
                    ruleID: Self.ruleID,
                    message: applicationContractCollaboratorDependencyMessage(
                        dependencyName: dependencyName,
                        declaration: context.uniqueDeclaration(named: dependencyName)
                    ),
                    coordinate: declaration.coordinate
                )
            }
        })

        return diagnostics
    }
}

public struct ApplicationContractsOwnershipPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.contracts.ownership"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        var diagnostics: [ArchitectureDiagnostic] = []

        diagnostics.append(contentsOf: file.initializerDeclarations.compactMap { declaration in
            guard let contractDeclaration = attachedApplicationContractDeclaration(
                named: declaration.enclosingTypeName,
                from: file,
                context: context
            ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: applicationContractOwnershipMessage(
                    surfaceDescription: "Initializer '\(declaration.enclosingTypeName).init(...)'",
                    contractName: contractDeclaration.name,
                    ownerPath: contractDeclaration.repoRelativePath
                ),
                coordinate: declaration.coordinate
            )
        })

        diagnostics.append(contentsOf: file.methodDeclarations.compactMap { declaration in
            guard let contractDeclaration = attachedApplicationContractDeclaration(
                named: declaration.enclosingTypeName,
                from: file,
                context: context
            ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: applicationContractOwnershipMessage(
                    surfaceDescription: "Method '\(declaration.name)' on contract '\(declaration.enclosingTypeName)'",
                    contractName: contractDeclaration.name,
                    ownerPath: contractDeclaration.repoRelativePath
                ),
                coordinate: declaration.coordinate
            )
        })

        diagnostics.append(contentsOf: file.computedPropertyDeclarations.compactMap { declaration in
            guard let contractDeclaration = attachedApplicationContractDeclaration(
                named: declaration.enclosingTypeName,
                from: file,
                context: context
            ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: applicationContractOwnershipMessage(
                    surfaceDescription: "Computed property '\(declaration.name)' on contract '\(declaration.enclosingTypeName)'",
                    contractName: contractDeclaration.name,
                    ownerPath: contractDeclaration.repoRelativePath
                ),
                coordinate: declaration.coordinate
            )
        })

        return diagnostics
    }
}

public struct ApplicationContractsNoStateTransitionSurfacePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.contracts.no_state_transition_surface"

    public init() {}

    public func evaluate(file: ArchitectureFile, context _: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationContractFile else {
            return []
        }

        var diagnostics: [ArchitectureDiagnostic] = []

        diagnostics.append(contentsOf: file.methodDeclarations.compactMap { declaration in
            guard isApplicationContractStateTransitionMethod(declaration) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: applicationContractStateTransitionSurfaceMessage(
                    surfaceDescription: "Method '\(declaration.name)' on contract '\(declaration.enclosingTypeName)'"
                ),
                coordinate: declaration.coordinate
            )
        })

        diagnostics.append(contentsOf: file.computedPropertyDeclarations.compactMap { declaration in
            guard isApplicationContractStateTransitionComputedProperty(declaration) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: applicationContractStateTransitionSurfaceMessage(
                    surfaceDescription: "Computed property '\(declaration.name)' on contract '\(declaration.enclosingTypeName)'"
                ),
                coordinate: declaration.coordinate
            )
        })

        return diagnostics
    }
}

public struct ApplicationContractsErrorTaxonomyPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.contracts.error_taxonomy"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationContractFile else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard isForbiddenApplicationContractErrorTaxonomy(
                declaration: declaration,
                file: file
            ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Application contract type '\(declaration.name)' must not act as an error or failure taxonomy. Move real structured errors to Application/Errors, let Application/Ports/Protocols throw them, and keep contracts as passive data carriers. If serialized failure metadata is needed, use a snapshot contract struct with stored fields only instead of an error/failure enum taxonomy. Do not fix this by renaming the taxonomy, wrapping it in a contract struct, preserving it through typealias, keeping static canonical failure instances in Application/Contracts, keeping structured-code mapping helpers in the contract file, introducing an intermediary condition/status contract or failure/runnerFailure field that still carries canonical failure classification through result or log contracts, or merely renaming those fields to errorSnapshot/runnerErrorSnapshot while preserving the same returned failure channel. Application/Contracts must not remain the source of truth for failure classification; failure classification should flow through thrown Application errors, while contracts carry only passive snapshots or true non-error outcomes.",
                coordinate: declaration.coordinate
            )
        }
    }
}

public struct ApplicationProtocolPlacementPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.protocol_placement"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplication else {
            return []
        }
        guard !file.classification.isApplicationPortProtocolFile else {
            return []
        }
        guard !file.classification.isApplicationUseCaseFile else {
            return []
        }
        guard !file.classification.isApplicationServicesRole else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind == .protocol else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Application port protocols and other technical seams belong in Application/Ports/Protocols; move protocol '\(declaration.name)' out of \(file.repoRelativePath).",
                coordinate: declaration.coordinate
            )
        }
    }
}

public struct ApplicationErrorsShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.errors.shape"
    public static let surfaceRuleID = "application.errors.surface"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationErrorFile else {
            return []
        }
        var diagnostics = structuredErrorDiagnostics(
            file: file,
            ruleID: Self.ruleID,
            rolePath: "Application/Errors",
            namingDescription: "ApplicationError or another role-revealing workflow error name ending in Error",
            namingValidator: { declaration in
                declaration.name == "ApplicationError" || declaration.name.hasSuffix("Error")
            }
        )

        diagnostics.append(
            contentsOf: structuredErrorSurfaceDiagnostics(
                file: file,
                ruleID: Self.surfaceRuleID,
                rolePath: "Application/Errors",
                forbiddenTerms: structuredErrorForbiddenSurfaceTerms
            )
        )

        return diagnostics
    }
}

public struct ApplicationErrorsPlacementPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.errors.placement"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplication else {
            return []
        }
        guard !file.classification.isApplicationErrorFile else {
            return []
        }

        return structuredErrorPlacementDiagnostics(
            file: file,
            ruleID: Self.ruleID,
            rolePath: "Application/Errors",
            namingValidator: { declaration in
                declaration.name == "ApplicationError" || declaration.name.hasSuffix("Error")
            }
        )
    }
}

public struct ApplicationServicesNoProtocolsPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.services.no_protocols"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationServicesRole else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind == .protocol else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Application/Services owns orchestrators; move protocol '\(declaration.name)' to Application/Ports/Protocols.",
                coordinate: declaration.coordinate
            )
        }
    }
}

public struct ApplicationServicesShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.services.shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationServiceFile else {
            return []
        }

        var diagnostics = file.topLevelDeclarations.compactMap { declaration -> ArchitectureDiagnostic? in
            guard declaration.kind != .protocol else {
                return nil
            }
            guard !declaration.name.hasSuffix("Service") else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Application/Services files should expose orchestrators ending in 'Service'; rename or move '\(declaration.name)'.",
                coordinate: declaration.coordinate
            )
        }

        let hasServiceType = file.topLevelDeclarations.contains {
            $0.kind != .protocol && $0.name.hasSuffix("Service")
        }

        if !hasServiceType {
            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Application/Services files must expose at least one top-level type ending in 'Service'."
                )
            )
        }

        return diagnostics
    }
}

public struct ApplicationServicesNoUseCasesPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.services.no_usecases"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationServicesRole else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard declaration.name.hasSuffix("UseCase") || declaration.name.hasSuffix("UseCases") else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Use-case types belong in Application/UseCases; move '\(declaration.name)' out of \(file.repoRelativePath).",
                coordinate: declaration.coordinate
            )
        }
    }
}

public struct ApplicationUseCasesShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.usecases.shape"
    private let forbiddenSuffixes = ["Service", "Coordinator", "Store", "Controller", "Orchestrator"]

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationUseCaseFile else {
            return []
        }

        var diagnostics = file.topLevelDeclarations.compactMap { declaration -> ArchitectureDiagnostic? in
            if forbiddenSuffixes.contains(where: { declaration.name.hasSuffix($0) }) {
                return file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Application/UseCases should expose focused operation types, not service-shaped type '\(declaration.name)'.",
                    coordinate: declaration.coordinate
                )
            }

            guard declaration.name.hasSuffix("UseCase") else {
                return file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Application use cases should end in 'UseCase'; rename '\(declaration.name)'.",
                    coordinate: declaration.coordinate
                )
            }

            if declaration.kind == .enum {
                return file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Application/UseCases should expose focused operation protocols or concrete operation types, not enum '\(declaration.name)'.",
                    coordinate: declaration.coordinate
                )
            }

            return nil
        }

        let hasUseCaseType = file.topLevelDeclarations.contains {
            $0.name.hasSuffix("UseCase")
        }

        if !hasUseCaseType {
            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Application/UseCases files must expose at least one top-level type ending in 'UseCase'."
                )
            )
        }

        return diagnostics
    }
}

public struct ApplicationUseCasesNoProtocolsPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.usecases.no_protocols"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationUseCaseFile else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind == .protocol, declaration.name.hasSuffix("UseCase") else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Application use cases must be concrete operation types, not protocols. Move seam '\(declaration.name)' to Application/Ports/Protocols or replace it with a concrete use-case implementation that depends on abstractions.",
                coordinate: declaration.coordinate
            )
        }
    }
}

public struct ApplicationUseCasesOperationShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.usecases.operation_shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationUseCaseFile else {
            return []
        }

        return operationSurfaceUseCaseDeclarations(in: file).compactMap { declaration in
            let operationMethods = applicationOperationMethods(
                file: file,
                context: context,
                enclosingTypeName: declaration.name
            )

            guard !operationMethods.isEmpty else {
                return file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Application use cases must declare at least one direct instance operation method that is not private or fileprivate and that explicitly returns a non-Void Application contract result.",
                    coordinate: declaration.coordinate
                )
            }

            guard !hasInvalidMultiMethodOperationNaming(operationMethods) else {
                return file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Application use cases with multiple public operation methods must give each operation a distinct semantic name. Generic names like 'execute', 'callAsFunction', and 'perform' are only allowed when the use case exposes exactly one public operation method.",
                    coordinate: declaration.coordinate
                )
            }

            return nil
        }
    }
}

public struct ApplicationUseCasesAbstractionDelegationPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.usecases.abstraction_delegation"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationUseCaseFile else {
            return []
        }

        return concreteUseCaseDeclarations(in: file).flatMap { declaration -> [ArchitectureDiagnostic] in
            let nonPrivateInstanceMethods = nonPrivateInstanceUseCaseMethods(
                file: file,
                enclosingTypeName: declaration.name
            )
            let inwardDependencyNames = inwardAbstractionDependencyNames(
                file: file,
                context: context,
                enclosingTypeName: declaration.name
            )

            guard !nonPrivateInstanceMethods.isEmpty, !inwardDependencyNames.isEmpty else {
                return [
                    file.diagnostic(
                        ruleID: Self.ruleID,
                        message: "Concrete Application use cases must operationally use at least one injected Application or Domain protocol dependency from a valid method instead of merely storing or referencing abstractions.",
                        coordinate: declaration.coordinate
                    )
                ]
            }

            let diagnostics: [ArchitectureDiagnostic] = nonPrivateInstanceMethods.compactMap { method in
                guard !methodOperationallyUsesInwardAbstraction(
                    file: file,
                    context: context,
                    enclosingTypeName: declaration.name,
                    methodName: method.name
                ) else {
                    return nil
                }

                return file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Application use case method '\(method.name)' must operationally use an injected Application or Domain protocol dependency. Inspect the implementation and relocate it according to its role: move pure local invariant or evaluator logic to the relevant contract or Domain-owned type; move sequencing, coordination, or support logic to an Application service or split the use case/service boundary; move runtime, provider, persistence, transport, or other concrete boundary implementation to Infrastructure behind a protocol and inject it into a focused use case. If the method mixes these roles, split it into the appropriate parts instead of keeping the combined implementation on the use case surface.",
                    coordinate: method.coordinate
                )
            }

            return diagnostics
        }
    }
}

public struct ApplicationUseCasesSurfacePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.usecases.surface"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationUseCaseFile else {
            return []
        }

        return concreteUseCaseDeclarations(in: file).flatMap { declaration -> [ArchitectureDiagnostic] in
            nonPrivateInstanceUseCaseMethods(
                file: file,
                enclosingTypeName: declaration.name
            ).compactMap { method in
                guard methodOperationallyUsesInwardAbstraction(
                    file: file,
                    context: context,
                    enclosingTypeName: declaration.name,
                    methodName: method.name
                ) else {
                    return nil
                }

                let keepsProjectionOrTranslationInline = useCaseMethodKeepsProjectionOrTranslationInline(
                    file: file,
                    context: context,
                    enclosingTypeName: declaration.name,
                    method: method
                )
                let usesApplicationStateTransition = useCaseMethodOperationallyUsesApplicationStateTransition(
                    file: file,
                    context: context,
                    enclosingTypeName: declaration.name,
                    methodName: method.name
                )

                guard keepsProjectionOrTranslationInline || usesApplicationStateTransition else {
                    return nil
                }

                return file.diagnostic(
                    ruleID: Self.ruleID,
                    message: applicationUseCaseSurfaceProjectionMessage(
                        methodName: method.name,
                        includesProjectionOrTranslation: keepsProjectionOrTranslationInline,
                        includesStateTransition: usesApplicationStateTransition
                    ),
                    coordinate: method.coordinate
                )
            }
        }
    }
}

public struct ApplicationServicesInfrastructureReferencePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.services.infrastructure_reference"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationServiceFile else {
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
                    message: "Application services may orchestrate use cases directly, but they must not depend on infrastructure type '\(reference.name)' from \(declaration.repoRelativePath).",
                    coordinate: reference.coordinate
                )
            )
        }

        return diagnostics
    }
}

public struct ApplicationServicesRepositoryReferencePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.services.repository_reference"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationServiceFile else {
            return []
        }

        var diagnostics: [ArchitectureDiagnostic] = []
        var seenNames = Set<String>()

        for reference in file.typeReferences {
            guard seenNames.insert(reference.name).inserted else { continue }
            guard let declaration = context.uniqueDeclaration(named: reference.name) else { continue }
            guard isRepositoryDependency(declaration) else { continue }

            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Application services orchestrate use cases, never repositories directly; move dependency '\(reference.name)' from \(declaration.repoRelativePath) behind a use case.",
                    coordinate: reference.coordinate
                )
            )
        }

        return diagnostics
    }
}

public struct ApplicationUseCasesInfrastructureReferencePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.usecases.infrastructure_reference"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationUseCaseFile else {
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
                    message: "Application use cases must depend on Application or Domain protocols, not infrastructure type '\(reference.name)' from \(declaration.repoRelativePath).",
                    coordinate: reference.coordinate
                )
            )
        }

        return diagnostics
    }
}

public struct ApplicationUseCasesPlatformAPIPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.usecases.platform_api"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationUseCaseFile else {
            return []
        }

        return forbiddenIdentifierDiagnostics(
            file: file,
            ruleID: Self.ruleID,
            forbiddenIdentifiers: ApplicationPolicyForbiddenAPIs.platformTypes.union(["ProcessInfo"]),
            messagePrefix: "Application use cases must stay platform-agnostic and must not use platform or I/O API"
        )
    }
}

public struct ApplicationUseCasesServiceReferencePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.usecases.service_reference"
    private let serviceSuffixes = ["Service", "Store", "Controller", "Coordinator", "Orchestrator", "Builder", "Generator", "Actor"]

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationUseCaseFile else {
            return []
        }

        var diagnostics: [ArchitectureDiagnostic] = []
        var seenNames = Set<String>()

        for reference in file.typeReferences {
            guard seenNames.insert(reference.name).inserted else { continue }
            guard let declaration = context.uniqueDeclaration(named: reference.name) else { continue }
            guard declaration.roleFolder == .applicationServices else {
                continue
            }
            guard isServiceLike(declaration) else {
                continue
            }

            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Application use cases should stay focused on one operation and depend on application-facing protocols or Domain protocols, not Application service '\(reference.name)' from \(declaration.repoRelativePath).",
                    coordinate: reference.coordinate
                )
            )
        }

        return diagnostics
    }

    private func isServiceLike(_ declaration: IndexedDeclaration) -> Bool {
        switch declaration.kind {
        case .class, .actor:
            return true
        case .struct, .protocol:
            return serviceSuffixes.contains { declaration.name.hasSuffix($0) }
        case .enum:
            return false
        }
    }
}

public struct ApplicationServicesPlatformAPIPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.services.platform_api"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationServiceFile else {
            return []
        }

        return forbiddenIdentifierDiagnostics(
            file: file,
            ruleID: Self.ruleID,
            forbiddenIdentifiers: ["Process", "FileManager", "Bundle", "UserDefaults", "URLSession"],
            messagePrefix: "Application services orchestrate workflows but must not use platform, filesystem, or networking API"
        )
    }
}

public struct ApplicationServicesOrchestrationPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.services.orchestration"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationServiceFile else {
            return []
        }

        let serviceDeclarations = file.topLevelDeclarations.filter(isServiceLikeDeclaration)
        let hasValidServiceSurface = serviceDeclarations.contains { declaration in
            let publicMethods = exposedServiceSurfaceMethods(
                file: file,
                enclosingTypeName: declaration.name
            )

            return publicMethods.contains { method in
                serviceMethodSatisfiesOrchestrationSurfaceRule(
                    file: file,
                    context: context,
                    enclosingTypeName: declaration.name,
                    method: method
                )
            }
        }

        var diagnostics: [ArchitectureDiagnostic] = []

        if !hasValidServiceSurface {
            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Application services must expose real orchestration: exposed methods should operationally use at least one injected Application use case or Application state transition, depending on responsibility. Stored dependencies alone, service-to-service delegation, direct port wrappers, and trivial shells do not qualify. Calling collaborators also does not excuse embedded adapter-style projection or emission logic; move those concerns behind Application ports."
                )
            )
        }

        diagnostics.append(
            contentsOf: serviceDeclarations.flatMap { declaration -> [ArchitectureDiagnostic] in
                guard !injectedApplicationUseCaseDependencyNames(
                    file: file,
                    context: context,
                    enclosingTypeName: declaration.name
                ).isEmpty else {
                    return []
                }

                return exposedServiceSurfaceMethods(
                    file: file,
                    enclosingTypeName: declaration.name
                ).compactMap { method in
                    guard !serviceMethodSatisfiesOrchestrationSurfaceRule(
                        file: file,
                        context: context,
                        enclosingTypeName: declaration.name,
                        method: method
                    ) else {
                        return nil
                    }

                    return file.diagnostic(
                        ruleID: Self.ruleID,
                        message: "Application service method '\(method.name)' must operationally use an injected Application use case or Application state transition, depending on the responsibility it exposes. Inspect the implementation and classify it into one of these buckets: invariant or evaluator logic; pure application-owned next-state semantics; concrete boundary implementation logic; orchestration logic or mixed orchestration of invariants and implementation. Move invariant or evaluator logic inward to the relevant Application contract or Domain entity or value object. Move pure application-owned next-state semantics to Application/StateTransitions and let the service orchestrate those transitions directly when that is the actual responsibility. Move concrete boundary implementation logic to Infrastructure behind an Application or Domain protocol seam, then consume it from a focused use case through dependency injection; do not call Infrastructure directly from the service. For orchestration logic or mixed orchestration of invariants and implementation, decompose mixed methods first, move invariants inward, move next-state semantics to state transitions, move implementation behind protocols and focused use cases, and keep only actual service-level orchestration on the exposed surface. Thin forwarding or facade and state-transition or bookkeeping helpers remain decomposition signals, not final destination buckets.",
                        coordinate: method.coordinate
                    )
                }
            }
        )

        return diagnostics
    }
}

public struct ApplicationServicesSurfacePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "application.services.surface"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isApplicationServiceFile else {
            return []
        }

        var diagnostics = providerSpecificSurfaceDiagnostics(
            file: file,
            ruleID: Self.ruleID,
            rolePath: "Application/Services",
            forbiddenTerms: providerSpecificSurfaceTerms
        )

        if let diagnostic = applicationServicesTechnicalProjectionDiagnostic(file: file) {
            diagnostics.append(diagnostic)
        }

        return diagnostics
    }
}

private enum ApplicationPolicyForbiddenAPIs {
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

private let genericUseCaseOperationMethodNames: Set<String> = [
    "execute",
    "callAsFunction",
    "perform"
]

private let explicitContractStateTransitionPrefixes: [String] = [
    "claim",
    "unclaim",
    "release",
    "register",
    "update",
    "schedule",
    "complete",
    "apply",
    "transition",
    "advance",
    "nextState",
    "previousState"
]

private let applicationContractForbiddenBoundaryTypeNames: Set<String> = [
    "URLRequest",
    "URLResponse",
    "HTTPURLResponse",
    "URLSession",
    "Process"
]

private let applicationContractErrorTaxonomyNameTerms: Set<String> = [
    "error",
    "errors",
    "failure",
    "failures",
    "failurecode",
    "failurecodes",
    "failurekind",
    "failurekinds"
]

private let applicationContractErrorTaxonomyIdentifierTerms: Set<String> = [
    "timeout",
    "failed",
    "failure",
    "cancelled",
    "canceled",
    "required",
    "notfound",
    "incompatible",
    "invalid",
    "error",
    "exit",
    "response",
    "policy",
    "input"
]

private let applicationContractErrorTaxonomyHelperPrefixes: [String] = [
    "from",
    "map",
    "normalize"
]

let providerSpecificSurfaceTerms: Set<String> = [
    "api key",
    "apikey",
    "approval policy",
    "approvalpolicy",
    "codex",
    "codexcommand",
    "codex command",
    "endpoint",
    "github",
    "gitlab",
    "graphql",
    "jira",
    "linear",
    "openai",
    "project slug",
    "projectslug",
    "sandbox",
    "tracker kind",
    "trackerkind",
    "workflow path",
    "workflowpath",
    "workflow.md"
]

private let applicationServicesTechnicalProjectionSourceTypeNames: Set<String> = [
    "SymphonyCodexRuntimeEventContract",
    "SymphonyCodexTurnExecutionResultContract",
    "SymphonyCodexSessionIdentityContract",
    "SymphonyCodexUsageSnapshotContract",
    "SymphonyCodexRateLimitSnapshotContract"
]

private let applicationServicesTechnicalProjectionTargetTypeNames: Set<String> = [
    "SymphonyWorkerAttemptLogEventContract",
    "SymphonyLiveSessionContract"
]

private let applicationServicesTechnicalProjectionSinkTypeNames: Set<String> = [
    "SymphonyWorkerAttemptLogSinkPortProtocol"
]

private let applicationServicesTechnicalProjectionEmitMemberNames: Set<String> = [
    "emit"
]

private let applicationUseCaseProjectionCollectionMemberNames: Set<String> = [
    "compactMap",
    "flatMap",
    "map",
    "reduce",
    "sorted"
]

private let applicationUseCaseProjectionContractNameTerms: [String] = [
    "event",
    "log",
    "row",
    "session",
    "snapshot",
    "status"
]

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

private func isExplicitContractStateTransitionName(_ name: String) -> Bool {
    explicitContractStateTransitionPrefixes.contains { name.hasPrefix($0) }
}

private func isApplicationContractStateTransitionMethod(
    _ declaration: ArchitectureMethodDeclaration
) -> Bool {
    if isDirectApplicationContractSurfaceType(
        declaration.returnTypeDescription,
        enclosingTypeName: declaration.enclosingTypeName
    ) {
        return true
    }

    return isExplicitContractStateTransitionName(declaration.name)
}

private func isApplicationContractStateTransitionComputedProperty(
    _ declaration: ArchitectureComputedPropertyDeclaration
) -> Bool {
    if isDirectApplicationContractSurfaceType(
        declaration.typeDescription,
        enclosingTypeName: declaration.enclosingTypeName
    ) {
        return true
    }

    return isExplicitContractStateTransitionName(declaration.name)
}

private func isDirectApplicationContractSurfaceType(
    _ typeDescription: String?,
    enclosingTypeName: String
) -> Bool {
    guard let typeDescription else {
        return false
    }

    let normalized = typeDescription.replacingOccurrences(of: " ", with: "")
    return normalized == enclosingTypeName
        || normalized == "\(enclosingTypeName)?"
        || normalized == "\(enclosingTypeName)!"
}

private func applicationContractStateTransitionSurfaceMessage(
    surfaceDescription: String
) -> String {
    "\(surfaceDescription) appears to define next-state or progression semantics on a contract surface. Application contracts may answer what is true now, but must not define what state becomes next. Likely categories: local next-state semantics (signs: returns the owning contract type, reconstructs the contract after changing owned fields or collections, remains collaborator-free; architectural note: pure local application-state progression; destination: Application/StateTransitions); service-level orchestration (signs: combines local state changes with broader workflow sequencing, retry or dispatch flow, reconciliation flow, or collaborator-driven control flow; architectural note: services coordinate workflow across operations and collaborators, not contract surfaces; destination: Application/Services); seam-backed application operation (signs: the behavior depends on or belongs with a protocol-backed collaborator such as loading, saving, scheduling, or executing through an abstraction seam; architectural note: one focused application operation across a seam; destination: Application/UseCases); concrete boundary behavior (signs: runtime, platform, provider, persistence, filesystem, network, or transport behavior is embedded; architectural note: concrete implementation rather than contract-local meaning; destination: Infrastructure). If this logic mixes responsibilities, decompose it before moving it: split out observational evaluation that only reads current contract data; split out pure local next-state semantics that rebuild or return updated contract state; split out broader workflow sequencing such as retries, dispatch ordering, reconciliation, or collaborator coordination; split out seam-backed operations that depend on protocol collaborators; and split out concrete boundary behavior. After the split, keep only contract-local observational evaluators on contracts, move local next-state semantics to Application/StateTransitions, move broader workflow sequencing to Application/Services, move seam-backed operations to Application/UseCases, and move concrete boundary behavior to Infrastructure."
}

private func applicationContractErrorMappingSurfaceMessage(
    surfaceDescription: String
) -> String {
    "\(surfaceDescription) appears to translate or shape error/failure information on a contract surface. Application contracts may expose narrow observational evaluators and may store passive snapshot fields, but they must not own error translation or failure-shaping logic. Likely categories: application error shaping (signs: switches on error type, assigns canonical code/message/retryable/details fields, or normalizes failure meaning without boundary-specific types; architectural note: application-layer failure meaning belongs outside contract surfaces; destination: Application/Errors, or Application/Services if the shaping is tightly tied to one workflow path); boundary or provider error adaptation (signs: maps runtime, provider, persistence, filesystem, transport, or other boundary-specific failure types into an Application-facing contract; architectural note: adapter behavior belongs where boundary details are already understood; destination: Infrastructure); orchestration-time workflow failure shaping (signs: converts failures into blocker, retry, skip, warning, or workflow outcome contracts using workflow context; architectural note: workflow sequencing and control belong in orchestrating services or focused seam-backed operations, not contracts; destination: Application/Services or Application/UseCases); hidden failure taxonomy ownership (signs: preserves canonical failure classification, named failure families, or centralized failure labels through helper logic; architectural note: contracts may carry passive snapshots but must not become the source of truth for failure classification; destination: Application/Errors). If this logic mixes responsibilities, decompose it before moving it. Separate passive snapshot storage from failure classification, workflow decision logic, and boundary-specific error adaptation. Signs of classification include switching on error type or assigning canonical codes/messages/retryability. Signs of workflow shaping include blocker/retry/skip/outcome decisions tied to workflow context. Signs of boundary adaptation include provider/runtime/persistence/transport-specific failure types. After splitting: keep only passive snapshot data on the contract, move failure classification to Application/Errors, move workflow decision logic to Application/Services or a focused Application/UseCases, and move boundary-specific adaptation to Infrastructure."
}

private func applicationContractCollaboratorDependencyMessage(
    dependencyName: String,
    declaration: IndexedDeclaration?
) -> String {
    let destinationGuidance: String
    let collaboratorCategory: String

    if let declaration {
        if declaration.repoRelativePath.contains("/Application/Ports/Protocols/")
            || declaration.repoRelativePath.contains("/Application/UseCases/") {
            collaboratorCategory = "a protocol-backed boundary operation"
            destinationGuidance = "move seam-backed operations to Application/UseCases"
        } else if declaration.layer == ArchitectureLayer.infrastructure || isRepositoryDependency(declaration) {
            collaboratorCategory = "concrete boundary implementation"
            destinationGuidance = "move concrete implementation to Infrastructure"
        } else {
            collaboratorCategory = "workflow orchestration"
            destinationGuidance = "move orchestration to Application/Services"
        }
    } else {
        collaboratorCategory = "workflow orchestration"
        destinationGuidance = "move orchestration to Application/Services, seam-backed operations to Application/UseCases, and concrete implementation to Infrastructure"
    }

    return "Application contracts may expose narrow observational evaluators only, and those evaluators must remain collaborator-free. Contract file references collaborator or boundary type '\(dependencyName)', so the current implementation is not a valid contract-local evaluator. Likely categories include: 1) a misclassified evaluator shape with forbidden collaborator use, 2) a protocol-backed boundary operation, 3) workflow orchestration, or 4) concrete boundary implementation. Signs: evaluator-shaped slices return predicates or derived values from stored contract state but still reference collaborators; seam-backed slices call ports or use cases to fetch, persist, schedule, execute, or otherwise cross a seam; orchestration slices branch, validate, retry, or coordinate multiple steps across collaborators; implementation slices reference repositories, gateways, adapters, SDKs, transport APIs, or other infrastructure-specific types. Architectural note: contracts answer what is true now and must stay collaborator-free, while \(collaboratorCategory) belongs on a non-contract surface. Destinations: if the logic is truly observational, remove the collaborator entirely and keep only the collaborator-free evaluator on the contract; otherwise \(destinationGuidance). In all cases, route seam-backed operations to Application/UseCases, workflow orchestration to Application/Services, and concrete boundary implementation to Infrastructure. If the logic mixes categories, do not move the entire method as one block. First split the surface into responsibility slices: collaborator-free observational evaluation over contract data, protocol-backed boundary operations, workflow sequencing or coordination, and concrete boundary implementation. Keep only the collaborator-free observational slice on the contract, then move each remaining slice to its proper destination."
}

private func applicationContractOwnershipMessage(
    surfaceDescription: String,
    contractName: String,
    ownerPath: String
) -> String {
    "\(surfaceDescription) attaches behavior to Application contract type '\(contractName)' from a non-owning file. Application contracts may expose narrow observational evaluators only, and attached behavior must live in the owning contract file at \(ownerPath) or on an appropriate non-contract surface. Likely categories: contract-local observational evaluator (signs: direct case projection or collaborator-free derivation from the contract's own stored data and explicit passive inputs only; architectural note: contract-owned meaning belongs with the contract surface itself; destination: \(ownerPath)); seam-backed application operation (signs: the behavior fetches, saves, schedules, executes, resolves, or otherwise crosses an abstraction seam; architectural note: seam-backed application behavior does not belong on contract surfaces; destination: Application/UseCases); workflow orchestration (signs: the behavior sequences retries, validation flow, dispatch order, reconciliation, or coordination across operations or collaborators; architectural note: workflow control belongs in Application/Services, not on contract types; destination: Application/Services); concrete boundary behavior (signs: runtime, provider, persistence, filesystem, network, transport, parsing, normalization, request shaping, or other adapter-local behavior is embedded; architectural note: concrete implementation belongs outside the contract surface; destination: Infrastructure). If this logic mixes responsibilities, decompose it before moving it: split out collaborator-free observational evaluation over the contract's own data; split out seam-backed operations; split out workflow sequencing or coordination; and split out concrete boundary behavior such as parsing, normalization, or request shaping. After the split, keep only the collaborator-free observational slice in \(ownerPath), move seam-backed operations to Application/UseCases, move orchestration to Application/Services, and move concrete boundary behavior to Infrastructure."
}

private func attachedApplicationContractDeclaration(
    named typeName: String,
    from file: ArchitectureFile,
    context: ProjectContext
) -> IndexedDeclaration? {
    guard let declaration = context.uniqueDeclaration(named: typeName),
          isApplicationContractDeclaration(declaration),
          declaration.repoRelativePath != file.repoRelativePath else {
        return nil
    }

    return declaration
}

private func isApplicationContractDeclaration(_ declaration: IndexedDeclaration) -> Bool {
    switch declaration.roleFolder {
    case .applicationContractsCommands, .applicationContractsPorts, .applicationContractsWorkflow:
        return true
    default:
        return false
    }
}

private func isForbiddenApplicationContractDependencyTypeName(
    _ typeName: String,
    context: ProjectContext
) -> Bool {
    let normalizedTypeName = canonicalArchitectureTypeName(typeName)

    if applicationContractForbiddenBoundaryTypeNames.contains(normalizedTypeName) {
        return true
    }

    if normalizedTypeName.hasSuffix("RepositoryProtocol") {
        return true
    }

    guard let declaration = context.uniqueDeclaration(named: normalizedTypeName) else {
        return false
    }

    switch declaration.roleFolder {
    case .applicationPortsProtocols,
         .applicationServices,
         .applicationUseCases,
         .infrastructureRepositories,
         .infrastructureGateways,
         .infrastructurePortAdapters,
         .infrastructureEvaluators:
        return true
    default:
        return false
    }
}

private func canonicalArchitectureTypeName(_ typeName: String) -> String {
    typeName
        .replacingOccurrences(of: "any ", with: "")
        .replacingOccurrences(of: "some ", with: "")
        .replacingOccurrences(of: "?", with: "")
        .replacingOccurrences(of: "!", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func isErrorShapedContractNestedDeclaration(
    _ declaration: ArchitectureNestedNominalDeclaration
) -> Bool {
    declaration.name.hasSuffix("Error")
        || declaration.inheritedTypeNames.contains("StructuredErrorProtocol")
        || declaration.inheritedTypeNames.contains("Error")
        || declaration.inheritedTypeNames.contains("LocalizedError")
        || structuredErrorRequiredMemberNames.isSubset(of: Set(declaration.memberNames))
}

private func isErrorShapedTypeName(_ typeName: String, context: ProjectContext) -> Bool {
    if typeName == "Error"
        || typeName == "StructuredErrorProtocol"
        || typeName == "LocalizedError"
        || typeName.hasSuffix("Error") {
        return true
    }

    guard let declaration = context.uniqueDeclaration(named: typeName) else {
        return false
    }

    return isErrorShapedIndexedDeclaration(declaration)
}

private func isErrorShapedIndexedDeclaration(_ declaration: IndexedDeclaration) -> Bool {
    declaration.name.hasSuffix("Error")
        || declaration.inheritedTypeNames.contains("StructuredErrorProtocol")
        || declaration.inheritedTypeNames.contains("Error")
        || declaration.inheritedTypeNames.contains("LocalizedError")
        || declaration.roleFolder == .domainErrors
        || declaration.roleFolder == .applicationErrors
        || declaration.roleFolder == .infrastructureErrors
        || declaration.roleFolder == .presentationErrors
}

private func isForbiddenApplicationContractErrorTaxonomy(
    declaration: ArchitectureTopLevelDeclaration,
    file: ArchitectureFile
) -> Bool {
    if declaration.inheritedTypeNames.contains("StructuredErrorProtocol")
        || declaration.inheritedTypeNames.contains("Error")
        || declaration.inheritedTypeNames.contains("LocalizedError") {
        return true
    }

    switch declaration.kind {
    case .enum:
        return isForbiddenApplicationContractErrorTaxonomyEnum(
            declaration: declaration,
            file: file
        )
    case .struct:
        return isForbiddenApplicationContractErrorTaxonomyStruct(
            declaration: declaration,
            file: file
        )
    default:
        return false
    }
}

private func isForbiddenApplicationContractErrorTaxonomyEnum(
    declaration: ArchitectureTopLevelDeclaration,
    file: ArchitectureFile
) -> Bool {
    guard isApplicationContractErrorTaxonomyName(declaration.name) else {
        return false
    }

    let caseSignalCount = applicationContractErrorTaxonomySignalCount(
        in: file,
        excluding: declaration.name
    )
    let hasStructuredErrorMembers = structuredErrorRequiredMemberNames.isSubset(
        of: Set(declaration.memberNames)
    )
    let hasTaxonomyHelpers = declaration.memberNames.contains(where: isApplicationContractErrorTaxonomyHelperName)

    return caseSignalCount >= 2 || hasStructuredErrorMembers || hasTaxonomyHelpers
}

private func isForbiddenApplicationContractErrorTaxonomyStruct(
    declaration: ArchitectureTopLevelDeclaration,
    file: ArchitectureFile
) -> Bool {
    guard isApplicationContractErrorTaxonomyName(declaration.name) else {
        return false
    }

    guard !isAllowedApplicationContractErrorSnapshotStruct(declaration) else {
        return false
    }

    let hasStructuredErrorMembers = structuredErrorRequiredMemberNames.isSubset(
        of: Set(declaration.memberNames)
    )
    let hasTaxonomyHelpers = declaration.memberNames.contains(where: isApplicationContractErrorTaxonomyHelperName)
    let caseSignalCount = applicationContractErrorTaxonomySignalCount(
        in: file,
        excluding: declaration.name
    )

    return hasStructuredErrorMembers || hasTaxonomyHelpers || caseSignalCount >= 2
}

private func isAllowedApplicationContractErrorSnapshotStruct(
    _ declaration: ArchitectureTopLevelDeclaration
) -> Bool {
    guard declaration.kind == .struct else {
        return false
    }

    let memberNames = Set(declaration.memberNames)
    guard structuredErrorRequiredMemberNames.isSubset(of: memberNames) else {
        return false
    }

    guard declaration.inheritedTypeNames.isEmpty else {
        return false
    }

    return !memberNames.contains(where: isApplicationContractErrorTaxonomyHelperName)
}

private func isApplicationContractErrorTaxonomyName(_ name: String) -> Bool {
    let normalized = normalizeTaxonomyTerm(name)
    return applicationContractErrorTaxonomyNameTerms.contains { normalized.contains($0) }
}

private func isApplicationContractErrorTaxonomyHelperName(_ name: String) -> Bool {
    let normalized = normalizeTaxonomyTerm(name)
    return applicationContractErrorTaxonomyHelperPrefixes.contains { normalized.hasPrefix($0) }
        && normalized.contains("error")
}

private func applicationContractErrorTaxonomySignalCount(
    in file: ArchitectureFile,
    excluding declarationName: String
) -> Int {
    let excludedName = normalizeTaxonomyTerm(declarationName)
    let matchedIdentifiers = Set(
        file.identifierOccurrences.compactMap { occurrence -> String? in
            let normalized = normalizeTaxonomyTerm(occurrence.name)
            guard normalized != excludedName else {
                return nil
            }

            guard applicationContractErrorTaxonomyIdentifierTerms.contains(where: { normalized.contains($0) }) else {
                return nil
            }

            return normalized
        }
    )

    let matchedStrings = Set(
        file.stringLiteralOccurrences.compactMap { occurrence -> String? in
            let normalized = normalizeTaxonomyTerm(occurrence.value)
            guard applicationContractErrorTaxonomyIdentifierTerms.contains(where: { normalized.contains($0) }) else {
                return nil
            }

            return normalized
        }
    )

    return matchedIdentifiers.union(matchedStrings).count
}

private func normalizeTaxonomyTerm(_ value: String) -> String {
    value.lowercased().filter(\.isLetter)
}

private func providerSpecificSurfaceDiagnostics(
    file: ArchitectureFile,
    ruleID: String,
    rolePath: String,
    forbiddenTerms: Set<String>
) -> [ArchitectureDiagnostic] {
    var diagnostics: [ArchitectureDiagnostic] = []
    var seenTerms = Set<String>()

    for occurrence in file.identifierOccurrences {
        let normalizedName = occurrence.name.lowercased()
        guard forbiddenTerms.contains(normalizedName) else { continue }
        guard seenTerms.insert(normalizedName).inserted else { continue }
        diagnostics.append(
            file.diagnostic(
                ruleID: ruleID,
                message: "\(rolePath) should stay provider and product agnostic; move '\(occurrence.name)' behind an application-facing protocol or infrastructure implementation.",
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
                message: "\(rolePath) should stay provider and product agnostic; move '\(matchedTerm)' behind an application-facing protocol or infrastructure implementation.",
                coordinate: occurrence.coordinate
            )
        )
    }

    return diagnostics
}

private func applicationServicesTechnicalProjectionDiagnostic(
    file: ArchitectureFile
) -> ArchitectureDiagnostic? {
    let serviceTypeNames = Set(
        file.topLevelDeclarations.compactMap { declaration -> String? in
            guard declaration.kind != .protocol, declaration.name.hasSuffix("Service") else {
                return nil
            }

            return declaration.name
        }
    )

    guard !serviceTypeNames.isEmpty else {
        return nil
    }

    let hasProjectionTargetReference = file.typeReferences.contains { reference in
        isApplicationServicesTechnicalProjectionTargetTypeName(reference.name)
    } || file.identifierOccurrences.contains { occurrence in
        isApplicationServicesTechnicalProjectionTargetTypeName(occurrence.name)
    }
    guard hasProjectionTargetReference else {
        return nil
    }

    let hasSinkDependency = file.storedMemberDeclarations.contains { declaration in
        declaration.typeNames.contains(where: isApplicationServicesTechnicalProjectionSinkTypeName)
    }

    let hasEmitCall = file.memberCallOccurrences.contains { occurrence in
        applicationServicesTechnicalProjectionEmitMemberNames.contains(occurrence.memberName)
    }

    let storesProjectionTargetsAtServiceLevel = file.storedMemberDeclarations.first { declaration in
        serviceTypeNames.contains(declaration.enclosingTypeName)
            && declaration.typeNames.contains(where: isApplicationServicesTechnicalProjectionTargetTypeName)
    } != nil

    let nestedProjectionHelper = file.nestedNominalDeclarations.first { declaration in
        isNestedApplicationServiceTechnicalProjectionHelper(
            declaration: declaration,
            file: file
        )
    }

    let hasServiceLevelProjectionEmission = hasSinkDependency && hasEmitCall
    let hasServiceLevelProjectionStorage = storesProjectionTargetsAtServiceLevel

    guard nestedProjectionHelper != nil
        || hasServiceLevelProjectionEmission
        || hasServiceLevelProjectionStorage else {
        return nil
    }

    let coordinate = nestedProjectionHelper?.coordinate
        ?? file.topLevelDeclarations.first(where: { serviceTypeNames.contains($0.name) })?.coordinate

    return file.diagnostic(
        ruleID: ApplicationServicesSurfacePolicy.ruleID,
        message: "Application services may construct their own top-level result contracts and request contracts for collaborators, but they must not project runtime/result technical contracts into log/session telemetry contracts or emit/store those projections directly inside the service. Move projection and emission behind Application ports with Infrastructure implementations, while keeping policy decisions in Application. Do not fix this by renaming the helper to Policy, moving the same projection into a private helper, or adding more collaborator calls while keeping the projection or emission pipeline in the service.",
        coordinate: coordinate
    )
}

private func applicationUseCaseSurfaceProjectionMessage(
    methodName: String,
    includesProjectionOrTranslation: Bool,
    includesStateTransition: Bool
) -> String {
    let projectionSigns = includesProjectionOrTranslation
        ? "the method sorts, maps, reduces, formats, or assembles auxiliary row, snapshot, event, session, status, or log contracts around the seam call"
        : "projection or translation concerns are not the dominant signal in this method"
    let stateTransitionSigns = includesStateTransition
        ? "the method calls an Application state transition or otherwise keeps pure next-state semantics on the use-case surface"
        : "pure application state progression is not the dominant signal in this method"

    return "Application use case method '\(methodName)' mixes a seam-backed operation with inline state progression or projection/translation logic. Likely categories: focused seam-backed application operation (signs: the method delegates through injected Application or Domain protocols and returns one top-level Application contract without owning inline state progression or auxiliary projection assembly; architectural note: use cases define one focused application operation across a seam; destination: Application/UseCases); pure application state progression (signs: \(stateTransitionSigns); architectural note: pure state evolution belongs in Application/StateTransitions, then gets orchestrated by services when it must be combined with seam-backed work; destination: Application/StateTransitions); application-facing projection or translation surface (signs: \(projectionSigns); architectural note: projection and translation are implementation-shaped concerns that should live behind an Application port with an Infrastructure implementation when they serve a boundary-facing status or read-model surface; destination: Infrastructure/PortAdapters or Infrastructure/Gateways behind an Application port); workflow orchestration (signs: the method sequences retries, validation, multi-step coordination, or broader runtime control around the seam; architectural note: broader sequencing belongs in Application/Services; destination: Application/Services). Explicit decomposition guidance: keep only the focused seam-backed operation on the use case surface; move pure application-owned state progression to Application/StateTransitions; extract boundary-facing projection or translation behind an Application port and implement it in Infrastructure; move broader sequencing to Application/Services; and if the current method mixes these roles, split seam invocation, state progression, and projection into separate collaborators instead of keeping the combined implementation inline."
}

private func isNestedApplicationServiceTechnicalProjectionHelper(
    declaration: ArchitectureNestedNominalDeclaration,
    file: ArchitectureFile
) -> Bool {
    let methods = file.methodDeclarations.filter { $0.enclosingTypeName == declaration.name }
    let initializers = file.initializerDeclarations.filter { $0.enclosingTypeName == declaration.name }
    let storedMembers = file.storedMemberDeclarations.filter { $0.enclosingTypeName == declaration.name }

    let handlesTechnicalSourceContracts =
        methods.contains { declaration in
            declaration.parameterTypeNames.contains(where: isApplicationServicesTechnicalProjectionSourceTypeName)
        }
        || initializers.contains { declaration in
            declaration.parameterTypeNames.contains(where: isApplicationServicesTechnicalProjectionSourceTypeName)
        }

    guard handlesTechnicalSourceContracts else {
        return false
    }

    let storesProjectionTargets = storedMembers.contains { declaration in
        declaration.typeNames.contains(where: isApplicationServicesTechnicalProjectionTargetTypeName)
    }

    let returnsProjectionTargets = methods.contains { declaration in
        declaration.returnTypeNames.contains(where: isApplicationServicesTechnicalProjectionTargetTypeName)
    }

    let hasSinkDependency = storedMembers.contains { declaration in
        declaration.typeNames.contains(where: isApplicationServicesTechnicalProjectionSinkTypeName)
    }

    let hasEmitCall = file.memberCallOccurrences.contains { occurrence in
        applicationServicesTechnicalProjectionEmitMemberNames.contains(occurrence.memberName)
    }

    return storesProjectionTargets || returnsProjectionTargets || (hasSinkDependency && hasEmitCall)
}

private func isApplicationServicesTechnicalProjectionSourceTypeName(_ typeName: String) -> Bool {
    applicationServicesTechnicalProjectionSourceTypeNames.contains(typeName)
}

private func isApplicationServicesTechnicalProjectionTargetTypeName(_ typeName: String) -> Bool {
    applicationServicesTechnicalProjectionTargetTypeNames.contains(typeName)
}

private func isApplicationServicesTechnicalProjectionSinkTypeName(_ typeName: String) -> Bool {
    applicationServicesTechnicalProjectionSinkTypeNames.contains(typeName)
}

private func useCaseMethodKeepsProjectionOrTranslationInline(
    file: ArchitectureFile,
    context: ProjectContext,
    enclosingTypeName: String,
    method: ArchitectureMethodDeclaration
) -> Bool {
    let operationalUses = file.operationalUseOccurrences.filter { occurrence in
        occurrence.enclosingTypeName == enclosingTypeName
            && occurrence.enclosingMethodName == method.name
    }
    guard !operationalUses.isEmpty else {
        return false
    }

    let hasProjectionCollectionOperation = operationalUses.contains { occurrence in
        applicationUseCaseProjectionCollectionMemberNames.contains(occurrence.memberName)
    }
    guard hasProjectionCollectionOperation else {
        return false
    }

    let constructedApplicationContracts = Set(operationalUses.compactMap { occurrence -> String? in
        guard occurrence.memberName == "callAsFunction" else {
            return nil
        }

        guard let declaration = context.uniqueDeclaration(named: occurrence.baseName),
              isApplicationContractDeclaration(declaration) else {
            return nil
        }

        return declaration.name
    })
    guard !constructedApplicationContracts.isEmpty else {
        return false
    }

    let returnedApplicationContracts = Set(method.returnTypeNames.compactMap { typeName -> String? in
        let normalizedTypeName = canonicalArchitectureTypeName(typeName)
        guard let declaration = context.uniqueDeclaration(named: normalizedTypeName),
              isApplicationContractDeclaration(declaration) else {
            return nil
        }

        return declaration.name
    })

    let auxiliaryConstructedContracts = constructedApplicationContracts.subtracting(returnedApplicationContracts)
    let projectionShapedAuxiliaryContracts = auxiliaryConstructedContracts.filter(isProjectionShapedApplicationContractName)
    if !projectionShapedAuxiliaryContracts.isEmpty {
        return true
    }

    return returnedApplicationContracts.contains(where: isProjectionShapedApplicationContractName)
        && constructedApplicationContracts.count > returnedApplicationContracts.count
}

private func useCaseStateTransitionDependencyNames(
    file: ArchitectureFile,
    context: ProjectContext,
    enclosingTypeName: String
) -> Set<String> {
    Set(file.storedMemberDeclarations.compactMap { declaration -> String? in
        guard declaration.enclosingTypeName == enclosingTypeName,
              !declaration.isStatic else {
            return nil
        }

        let referencesStateTransition = declaration.typeNames.contains { typeName in
            guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
                return false
            }

            return indexedDeclaration.roleFolder == .applicationStateTransitions
        }

        return referencesStateTransition ? declaration.name : nil
    })
}

private func useCaseNonPublicHelperMethodNames(
    file: ArchitectureFile,
    enclosingTypeName: String
) -> Set<String> {
    Set(file.methodDeclarations.compactMap { declaration in
        guard declaration.enclosingTypeName == enclosingTypeName,
              !declaration.isStatic,
              declaration.isPrivateOrFileprivate else {
            return nil
        }

        return declaration.name
    })
}

private func useCaseMethodOperationallyUsesApplicationStateTransition(
    file: ArchitectureFile,
    context: ProjectContext,
    enclosingTypeName: String,
    methodName: String,
    visitedMethodNames: Set<String> = []
) -> Bool {
    guard !visitedMethodNames.contains(methodName) else {
        return false
    }

    let stateTransitionDependencyNames = useCaseStateTransitionDependencyNames(
        file: file,
        context: context,
        enclosingTypeName: enclosingTypeName
    )
    guard !stateTransitionDependencyNames.isEmpty else {
        return false
    }

    if file.operationalUseOccurrences.contains(where: { occurrence in
        occurrence.enclosingTypeName == enclosingTypeName
            && occurrence.enclosingMethodName == methodName
            && stateTransitionDependencyNames.contains(occurrence.baseName)
    }) {
        return true
    }

    let helperMethodNames = useCaseNonPublicHelperMethodNames(
        file: file,
        enclosingTypeName: enclosingTypeName
    )
    let calledHelperNames = Set(file.operationalUseOccurrences.compactMap { occurrence -> String? in
        guard occurrence.enclosingTypeName == enclosingTypeName,
              occurrence.enclosingMethodName == methodName,
              helperMethodNames.contains(occurrence.baseName) else {
            return nil
        }

        return occurrence.baseName
    })

    let nextVisitedMethodNames = visitedMethodNames.union([methodName])
    return calledHelperNames.contains { helperMethodName in
        useCaseMethodOperationallyUsesApplicationStateTransition(
            file: file,
            context: context,
            enclosingTypeName: enclosingTypeName,
            methodName: helperMethodName,
            visitedMethodNames: nextVisitedMethodNames
        )
    }
}

private func isProjectionShapedApplicationContractName(_ typeName: String) -> Bool {
    let normalized = normalizeTaxonomyTerm(typeName)
    return applicationUseCaseProjectionContractNameTerms.contains { normalized.contains($0) }
}

private func isRepositoryDependency(_ declaration: IndexedDeclaration) -> Bool {
    if declaration.layer == .infrastructure && declaration.roleFolder == .infrastructureRepositories {
        return true
    }

    return declaration.kind == .protocol
        && declaration.roleFolder == .domainProtocols
        && isRepositoryLikeName(declaration.name)
}

private func isRepositoryLikeName(_ name: String) -> Bool {
    name.hasSuffix("RepositoryProtocol") || name.hasSuffix("Repository")
}

private func referencesOrchestrationCollaborator(
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let collaboratorNames = Set(
        file.typedMemberOccurrences.compactMap { occurrence -> String? in
            let hasOrchestrationType = occurrence.typeNames.contains { typeName in
                guard let declaration = context.uniqueDeclaration(named: typeName) else {
                    return false
                }

                if declaration.roleFolder == .applicationServices {
                    return isServiceLike(declaration)
                }

                return declaration.roleFolder == .applicationUseCases
                    || declaration.roleFolder == .applicationStateTransitions
            }

            return hasOrchestrationType ? occurrence.name : nil
        }
    )

    guard !collaboratorNames.isEmpty else {
        return false
    }

    return file.memberCallOccurrences.contains { collaboratorNames.contains($0.baseName) }
}

private func exposedServiceSurfaceMethods(
    file: ArchitectureFile,
    enclosingTypeName: String
) -> [ArchitectureMethodDeclaration] {
    file.methodDeclarations.filter { declaration in
        declaration.enclosingTypeName == enclosingTypeName
            && !declaration.isStatic
            && declaration.isPublicOrOpen
    }
}

private func injectedApplicationUseCaseDependencyNames(
    file: ArchitectureFile,
    context: ProjectContext,
    enclosingTypeName: String
) -> Set<String> {
    Set(file.storedMemberDeclarations.compactMap { declaration -> String? in
        guard declaration.enclosingTypeName == enclosingTypeName,
              !declaration.isStatic else {
            return nil
        }

        let referencesUseCase = declaration.typeNames.contains { typeName in
            guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
                return false
            }

            return indexedDeclaration.roleFolder == .applicationUseCases
        }

        return referencesUseCase ? declaration.name : nil
    })
}

private func injectedApplicationStateTransitionDependencyNames(
    file: ArchitectureFile,
    context: ProjectContext,
    enclosingTypeName: String
) -> Set<String> {
    Set(file.storedMemberDeclarations.compactMap { declaration -> String? in
        guard declaration.enclosingTypeName == enclosingTypeName,
              !declaration.isStatic else {
            return nil
        }

        let referencesStateTransition = declaration.typeNames.contains { typeName in
            guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
                return false
            }

            return indexedDeclaration.roleFolder == .applicationStateTransitions
        }

        return referencesStateTransition ? declaration.name : nil
    })
}

private func serviceNonPublicHelperMethodNames(
    file: ArchitectureFile,
    enclosingTypeName: String
) -> Set<String> {
    Set(file.methodDeclarations.compactMap { declaration in
        guard declaration.enclosingTypeName == enclosingTypeName,
              !declaration.isStatic,
              declaration.isPrivateOrFileprivate else {
            return nil
        }

        return declaration.name
    })
}

private func serviceMethodOperationallyUsesInjectedApplicationOrchestrationDependency(
    file: ArchitectureFile,
    context: ProjectContext,
    enclosingTypeName: String,
    methodName: String,
    visitedMethodNames: Set<String> = []
) -> Bool {
    guard !visitedMethodNames.contains(methodName) else {
        return false
    }

    let useCaseDependencyNames = injectedApplicationUseCaseDependencyNames(
        file: file,
        context: context,
        enclosingTypeName: enclosingTypeName
    )
    let stateTransitionDependencyNames = injectedApplicationStateTransitionDependencyNames(
        file: file,
        context: context,
        enclosingTypeName: enclosingTypeName
    )
    let orchestrationDependencyNames = useCaseDependencyNames.union(stateTransitionDependencyNames)
    guard !orchestrationDependencyNames.isEmpty else {
        return false
    }

    if file.operationalUseOccurrences.contains(where: { occurrence in
        occurrence.enclosingTypeName == enclosingTypeName
            && occurrence.enclosingMethodName == methodName
            && orchestrationDependencyNames.contains(occurrence.baseName)
    }) {
        return true
    }

    let helperMethodNames = serviceNonPublicHelperMethodNames(
        file: file,
        enclosingTypeName: enclosingTypeName
    )
    let calledHelperNames = Set(file.operationalUseOccurrences.compactMap { occurrence -> String? in
        guard occurrence.enclosingTypeName == enclosingTypeName,
              occurrence.enclosingMethodName == methodName,
              helperMethodNames.contains(occurrence.baseName) else {
            return nil
        }

        return occurrence.baseName
    })

    let nextVisitedMethodNames = visitedMethodNames.union([methodName])
    return calledHelperNames.contains { helperMethodName in
        serviceMethodOperationallyUsesInjectedApplicationOrchestrationDependency(
            file: file,
            context: context,
            enclosingTypeName: enclosingTypeName,
            methodName: helperMethodName,
            visitedMethodNames: nextVisitedMethodNames
        )
    }
}

private func serviceMethodSatisfiesOrchestrationSurfaceRule(
    file: ArchitectureFile,
    context: ProjectContext,
    enclosingTypeName: String,
    method: ArchitectureMethodDeclaration
) -> Bool {
    guard serviceMethodOperationallyUsesInjectedApplicationOrchestrationDependency(
        file: file,
        context: context,
        enclosingTypeName: enclosingTypeName,
        methodName: method.name
    ) else {
        return false
    }

    return !isThinForwardingFacadeServiceMethod(
        file: file,
        context: context,
        enclosingTypeName: enclosingTypeName,
        declaration: method
    )
}

private func isThinForwardingFacadeServiceMethod(
    file: ArchitectureFile,
    context: ProjectContext,
    enclosingTypeName: String,
    declaration: ArchitectureMethodDeclaration
) -> Bool {
    let useCaseDependencyNames = injectedApplicationUseCaseDependencyNames(
        file: file,
        context: context,
        enclosingTypeName: enclosingTypeName
    )
    guard !useCaseDependencyNames.isEmpty else {
        return false
    }

    let helperMethodNames = serviceNonPublicHelperMethodNames(
        file: file,
        enclosingTypeName: enclosingTypeName
    )
    let operationalUses = file.operationalUseOccurrences.filter { occurrence in
        occurrence.enclosingTypeName == enclosingTypeName
            && occurrence.enclosingMethodName == declaration.name
    }
    guard !operationalUses.isEmpty else {
        return false
    }

    let directUseCaseCalls = operationalUses.filter { occurrence in
        useCaseDependencyNames.contains(occurrence.baseName)
    }
    guard !directUseCaseCalls.isEmpty else {
        return false
    }

    let callsPrivateHelpers = operationalUses.contains { occurrence in
        helperMethodNames.contains(occurrence.baseName)
    }
    if callsPrivateHelpers {
        return false
    }

    let nonUseCaseOperationalUses = operationalUses.filter { occurrence in
        !useCaseDependencyNames.contains(occurrence.baseName)
    }
    guard nonUseCaseOperationalUses.isEmpty else {
        return false
    }

    return Set(directUseCaseCalls.map(\.baseName)).count == 1
}

private func concreteUseCaseDeclarations(in file: ArchitectureFile) -> [ArchitectureTopLevelDeclaration] {
    file.topLevelDeclarations.filter {
        $0.name.hasSuffix("UseCase") && $0.kind != .protocol
    }
}

private func operationSurfaceUseCaseDeclarations(
    in file: ArchitectureFile
) -> [ArchitectureTopLevelDeclaration] {
    file.topLevelDeclarations.filter {
        $0.name.hasSuffix("UseCase") && $0.kind != .enum
    }
}

private func applicationOperationMethods(
    file: ArchitectureFile,
    context: ProjectContext,
    enclosingTypeName: String
) -> [ArchitectureMethodDeclaration] {
    file.methodDeclarations.filter { declaration in
        declaration.enclosingTypeName == enclosingTypeName
            && !declaration.isStatic
            && !declaration.isPrivateOrFileprivate
            && returnsApplicationContractResult(declaration, context: context)
    }
}

private func nonPrivateInstanceUseCaseMethods(
    file: ArchitectureFile,
    enclosingTypeName: String
) -> [ArchitectureMethodDeclaration] {
    file.methodDeclarations.filter { declaration in
        declaration.enclosingTypeName == enclosingTypeName
            && !declaration.isStatic
            && !declaration.isPrivateOrFileprivate
    }
}

private func hasInvalidMultiMethodOperationNaming(
    _ declarations: [ArchitectureMethodDeclaration]
) -> Bool {
    guard declarations.count > 1 else {
        return false
    }

    let methodNames = declarations.map(\.name)
    return methodNames.contains(where: genericUseCaseOperationMethodNames.contains)
        || Set(methodNames).count != methodNames.count
}

private func operationallyUsesInwardAbstraction(
    file: ArchitectureFile,
    context: ProjectContext,
    enclosingTypeName: String
) -> Bool {
    let validMethodNames = Set(nonPrivateInstanceUseCaseMethods(
        file: file,
        enclosingTypeName: enclosingTypeName
    ).map(\.name))
    guard !validMethodNames.isEmpty else {
        return false
    }

    let inwardDependencyNames = inwardAbstractionDependencyNames(
        file: file,
        context: context,
        enclosingTypeName: enclosingTypeName
    )
    guard !inwardDependencyNames.isEmpty else {
        return false
    }

    return file.operationalUseOccurrences.contains { occurrence in
        occurrence.enclosingTypeName == enclosingTypeName
            && validMethodNames.contains(occurrence.enclosingMethodName)
            && inwardDependencyNames.contains(occurrence.baseName)
    }
}

private func methodOperationallyUsesInwardAbstraction(
    file: ArchitectureFile,
    context: ProjectContext,
    enclosingTypeName: String,
    methodName: String
) -> Bool {
    let inwardDependencyNames = inwardAbstractionDependencyNames(
        file: file,
        context: context,
        enclosingTypeName: enclosingTypeName
    )
    guard !inwardDependencyNames.isEmpty else {
        return false
    }

    return file.operationalUseOccurrences.contains { occurrence in
        occurrence.enclosingTypeName == enclosingTypeName
            && occurrence.enclosingMethodName == methodName
            && inwardDependencyNames.contains(occurrence.baseName)
    }
}

private func inwardAbstractionDependencyNames(
    file: ArchitectureFile,
    context: ProjectContext,
    enclosingTypeName: String
) -> Set<String> {
    Set(file.storedMemberDeclarations.compactMap { declaration -> String? in
        guard declaration.enclosingTypeName == enclosingTypeName,
              !declaration.isStatic else {
            return nil
        }

        let referencesInwardProtocol = declaration.typeNames.contains { typeName in
            guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
                return false
            }

            guard indexedDeclaration.kind == .protocol else {
                return false
            }

            return indexedDeclaration.roleFolder == .applicationPortsProtocols
                || indexedDeclaration.roleFolder == .domainProtocols
        }

        return referencesInwardProtocol ? declaration.name : nil
    })
}

private func returnsApplicationContractResult(
    _ declaration: ArchitectureMethodDeclaration,
    context: ProjectContext
) -> Bool {
    guard declaration.hasExplicitReturnType, !declaration.returnsVoidLike else {
        return false
    }

    return declaration.returnTypeNames.contains { typeName in
        guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
            return false
        }

        guard indexedDeclaration.layer == .application else {
            return false
        }

        switch indexedDeclaration.roleFolder {
        case .applicationContractsCommands,
                .applicationContractsPorts,
                .applicationContractsWorkflow:
            return indexedDeclaration.name.hasSuffix("Contract")
        default:
            return false
        }
    }
}

private func isServiceLikeDeclaration(_ declaration: ArchitectureTopLevelDeclaration) -> Bool {
    declaration.kind != .protocol && declaration.name.hasSuffix("Service")
}

private func isServiceLike(_ declaration: IndexedDeclaration) -> Bool {
    switch declaration.kind {
    case .class, .actor:
        return true
    case .struct, .protocol:
        return declaration.name.hasSuffix("Service")
    case .enum:
        return false
    }
}
