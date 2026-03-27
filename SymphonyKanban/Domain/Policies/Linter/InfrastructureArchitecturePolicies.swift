import Foundation

public struct InfrastructureRepositoriesShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.repositories.shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureRepositoryFile else {
            return []
        }

        var diagnostics = file.topLevelDeclarations.compactMap { declaration -> ArchitectureDiagnostic? in
            guard declaration.kind == .protocol else {
                return nil
            }
            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Repositories should provide concrete repository implementations, not protocols; move '\(declaration.name)' to the inward layer that owns the contract.",
                coordinate: declaration.coordinate
            )
        }

        diagnostics.append(contentsOf: file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind != .protocol && declaration.kind != .enum else {
                return nil
            }
            guard !declaration.name.hasSuffix("Repository") else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Repositories files should expose concrete repository types ending in 'Repository'; rename or move '\(declaration.name)'.",
                coordinate: declaration.coordinate
            )
        })

        let hasConcreteRepository = file.topLevelDeclarations.contains { declaration in
            switch declaration.kind {
            case .class, .struct, .actor:
                return declaration.name.hasSuffix("Repository")
            case .protocol, .enum:
                return false
            }
        }

        if !hasConcreteRepository {
            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Infrastructure/Repositories files should expose at least one concrete repository type ending in 'Repository'."
                )
            )
        }

        return diagnostics
    }
}

public struct InfrastructureGatewaysShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.gateways.shape"
    private let forbiddenSuffixes = ["Repository", "UseCase", "UseCases", "Policy", "Controller", "Route", "ViewModel", "PortAdapter", "Service"]

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureGatewayFile else {
            return []
        }

        var diagnostics = file.topLevelDeclarations.compactMap { declaration -> ArchitectureDiagnostic? in
            guard declaration.kind == .protocol else {
                return nil
            }
            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Gateways should implement inward contracts, not declare new protocols like '\(declaration.name)'.",
                coordinate: declaration.coordinate
            )
        }

        diagnostics.append(contentsOf: file.topLevelDeclarations.compactMap { declaration in
            guard forbiddenSuffixes.contains(where: { declaration.name.hasSuffix($0) }) else {
                return nil
            }
            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Gateways should model external boundary adapters, not '\(declaration.name)'.",
                coordinate: declaration.coordinate
            )
        })

        diagnostics.append(contentsOf: file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind != .protocol && declaration.kind != .enum else {
                return nil
            }
            guard !declaration.name.hasSuffix("Gateway") else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Gateways files should expose concrete gateway types ending in 'Gateway'; rename or move '\(declaration.name)'.",
                coordinate: declaration.coordinate
            )
        })

        let hasGatewayShapedType = file.topLevelDeclarations.contains { declaration in
            switch declaration.kind {
            case .class, .struct, .actor:
                return declaration.name.hasSuffix("Gateway")
            case .protocol, .enum:
                return false
            }
        }

        if !hasGatewayShapedType {
            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Infrastructure/Gateways files should expose at least one concrete gateway-shaped type ending in 'Gateway'."
                )
            )
        }

        return diagnostics
    }
}

public struct InfrastructureGatewaysRoleFitPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.gateways.role_fit"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureGatewayFile else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind != .protocol,
                  declaration.kind != .enum,
                  declaration.name.hasSuffix("Gateway") else {
                return nil
            }

            let methods = file.methodDeclarations.filter { $0.enclosingTypeName == declaration.name }
            guard !hasGatewayExecutionFlowEvidence(
                in: file,
                gatewayTypeName: declaration.name,
                methods: methods
            ),
            hasGatewayRoleFitMisclassificationEvidence(
                in: file,
                gatewayTypeName: declaration.name,
                methods: methods,
                context: context
            ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "'\(declaration.name)' is gateway-shaped but does not appear to execute an external or runtime boundary. Likely categories: boundary-executing gateway (signs: fetches, loads, discovers, starts, continues, cancels, launches, runs, monitors, schedules, sends, waits on, processes, paginates, streams, or otherwise performs concrete runtime, process, filesystem, network, queue, or provider work; architectural note: gateways own concrete boundary execution and orchestration; destination: Infrastructure/Gateways); concrete port adapter (signs: mainly prepares, builds, creates, resolves, or assembles boundary inputs for another adapter to execute while still honestly representing a seam implementation; architectural note: this is a concrete inward-port implementation rather than the boundary executor; destination: Infrastructure/PortAdapters); adapter-owned intermediary shaping (signs: normalizes configuration, assembles request-definition, launch-definition, startup, command, context, or other intermediary boundary carriers before the final provider or transport shape exists; architectural note: intermediary shaping belongs in translation models rather than in a gateway shell; destination: Infrastructure/Translation/Models); final provider or transport request or response shaping (signs: assembles passive request, response, envelope, body, params, data, payload, URLRequest, or HTTPURLResponse boundary shapes without executing them; architectural note: final boundary-facing shapes and adjacent DTO-side translators belong on the DTO side of Infrastructure translation; destination: Infrastructure/Translation/DTOs). Explicit decomposition guidance: split boundary execution flow such as fetch, load, start, continue, cancel, launch, run, monitor, schedule, send, wait, paginate, transport handling, or provider response handling into the gateway; split normalized configuration and intermediary request-definition shaping into Infrastructure/Translation/Models; split final provider or transport request or response carriers and any adjacent DTO-side translator or builder into Infrastructure/Translation/DTOs; and keep only any remaining concrete seam façade in Infrastructure/PortAdapters when a distinct adapter surface is still needed.",
                coordinate: firstGatewayRoleFitCoordinate(
                    in: file,
                    gatewayTypeName: declaration.name,
                    methods: methods,
                    context: context
                ) ?? declaration.coordinate
            )
        }
    }
}

public struct InfrastructureGatewaysInlineBoundaryConfigurationShapingPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.gateways.inline_boundary_configuration_shaping"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureGatewayFile else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind != .protocol,
                  declaration.kind != .enum,
                  declaration.name.hasSuffix("Gateway") else {
                return nil
            }

            let methods = file.methodDeclarations.filter { $0.enclosingTypeName == declaration.name }
            guard hasInlineGatewayBoundaryConfigurationShapingEvidence(
                in: file,
                gatewayTypeName: declaration.name,
                methods: methods,
                context: context
            ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: gatewayInlineBoundaryConfigurationShapingMessage(for: declaration.name),
                coordinate: firstInlineGatewayBoundaryConfigurationShapingCoordinate(
                    in: file,
                    gatewayTypeName: declaration.name,
                    methods: methods,
                    context: context
                ) ?? declaration.coordinate
            )
        }
    }
}

public struct InfrastructureGatewaysInlineBoundaryDefinitionShapingPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.gateways.inline_boundary_definition_shaping"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureGatewayFile else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind != .protocol,
                  declaration.kind != .enum,
                  declaration.name.hasSuffix("Gateway") else {
                return nil
            }

            let methods = file.methodDeclarations.filter { $0.enclosingTypeName == declaration.name }
            guard hasInlineGatewayBoundaryDefinitionShapingEvidence(
                in: file,
                gatewayTypeName: declaration.name,
                methods: methods,
                context: context
            ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: gatewayInlineBoundaryDefinitionShapingMessage(for: declaration.name),
                coordinate: firstInlineGatewayBoundaryDefinitionShapingCoordinate(
                    in: file,
                    gatewayTypeName: declaration.name,
                    methods: methods,
                    context: context
                ) ?? declaration.coordinate
            )
        }
    }
}

public struct InfrastructureGatewaysInlineOutboundRequestTranslationPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.gateways.inline_outbound_request_translation"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureGatewayFile else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind != .protocol,
                  declaration.kind != .enum,
                  declaration.name.hasSuffix("Gateway") else {
                return nil
            }

            let methods = file.methodDeclarations.filter { $0.enclosingTypeName == declaration.name }
            guard hasInlineGatewayOutboundRequestTranslationEvidence(
                in: file,
                gatewayTypeName: declaration.name,
                methods: methods,
                context: context
            ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: gatewayInlineOutboundRequestTranslationMessage(for: declaration.name),
                coordinate: firstInlineGatewayOutboundRequestTranslationCoordinate(
                    in: file,
                    gatewayTypeName: declaration.name,
                    methods: methods,
                    context: context
                ) ?? declaration.coordinate
            )
        }
    }
}

public struct InfrastructureGatewaysInlineNormalizationPreparationPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.gateways.inline_normalization_preparation"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureGatewayFile else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind != .protocol,
                  declaration.kind != .enum,
                  declaration.name.hasSuffix("Gateway") else {
                return nil
            }

            let methods = file.methodDeclarations.filter { $0.enclosingTypeName == declaration.name }
            guard hasGatewayExecutionFlowEvidence(
                in: file,
                gatewayTypeName: declaration.name,
                methods: methods
            ),
            let culprit = firstInlineGatewayNormalizationPreparationMethod(
                in: file,
                gatewayTypeName: declaration.name,
                methods: methods,
                context: context
            ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: gatewayInlineNormalizationPreparationMessage(for: declaration.name),
                coordinate: culprit.coordinate
            )
        }
    }
}

public struct InfrastructureGatewaysInlineObviousBoundaryDecisionLogicPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.gateways.inline_obvious_boundary_decision_logic"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureGatewayFile else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind != .protocol,
                  declaration.kind != .enum,
                  declaration.name.hasSuffix("Gateway") else {
                return nil
            }

            let methods = file.methodDeclarations.filter { $0.enclosingTypeName == declaration.name }
            guard hasGatewayExecutionFlowEvidence(
                in: file,
                gatewayTypeName: declaration.name,
                methods: methods
            ),
            let culprit = firstInlineGatewayObviousBoundaryDecisionLogicMethod(
                in: file,
                gatewayTypeName: declaration.name,
                methods: methods,
                context: context
            ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: gatewayInlineObviousBoundaryDecisionLogicMessage(for: declaration.name),
                coordinate: culprit.coordinate
            )
        }
    }
}

public struct InfrastructureGatewaysInlineTypedBoundaryCompatibilityEvaluationPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.gateways.inline_typed_boundary_compatibility_evaluation"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureGatewayFile else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind != .protocol,
                  declaration.kind != .enum,
                  declaration.name.hasSuffix("Gateway") else {
                return nil
            }

            let methods = file.methodDeclarations.filter { $0.enclosingTypeName == declaration.name }
            guard hasGatewayExecutionFlowEvidence(
                in: file,
                gatewayTypeName: declaration.name,
                methods: methods
            ),
            let culprit = firstInlineGatewayTypedBoundaryCompatibilityEvaluationMethod(
                in: file,
                gatewayTypeName: declaration.name,
                methods: methods,
                context: context
            ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: gatewayInlineTypedBoundaryCompatibilityEvaluationMessage(for: declaration.name),
                coordinate: culprit.coordinate
            )
        }
    }
}

public struct InfrastructureGatewaysInlineTypedInteractionDispatchPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.gateways.inline_typed_interaction_dispatch"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureGatewayFile else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind != .protocol,
                  declaration.kind != .enum,
                  declaration.name.hasSuffix("Gateway") else {
                return nil
            }

            let methods = file.methodDeclarations.filter { $0.enclosingTypeName == declaration.name }
            guard hasGatewayExecutionFlowEvidence(
                in: file,
                gatewayTypeName: declaration.name,
                methods: methods
            ),
            let culprit = firstInlineGatewayTypedInteractionDispatchMethod(
                in: file,
                gatewayTypeName: declaration.name,
                methods: methods,
                context: context
            ) else {
                return nil
            }

            let passiveShapeDestinations = inlineTypedInteractionDispatchPassiveShapeDestinations(
                culprit,
                in: file,
                context: context
            )

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: gatewayInlineTypedInteractionDispatchMessage(
                    for: declaration.name,
                    passiveShapeDestinations: passiveShapeDestinations
                ),
                coordinate: culprit.coordinate
            )
        }
    }
}

public struct InfrastructurePortAdaptersShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.port_adapters.shape"
    private let forbiddenSuffixes = ["Repository", "Gateway", "UseCase", "UseCases", "Policy", "Controller", "Route", "ViewModel", "Service"]

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructurePortAdapterFile else {
            return []
        }

        var diagnostics = file.topLevelDeclarations.compactMap { declaration -> ArchitectureDiagnostic? in
            guard declaration.kind == .protocol else {
                return nil
            }
            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/PortAdapters should provide concrete adapter implementations; move protocol '\(declaration.name)' inward.",
                coordinate: declaration.coordinate
            )
        }

        diagnostics.append(contentsOf: file.topLevelDeclarations.compactMap { declaration in
            guard forbiddenSuffixes.contains(where: { declaration.name.hasSuffix($0) }) else {
                return nil
            }
            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/PortAdapters should hold boundary adapters and support types, not '\(declaration.name)'.",
                coordinate: declaration.coordinate
            )
        })

        diagnostics.append(contentsOf: file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind != .protocol else {
                return nil
            }
            guard !declaration.name.hasSuffix("PortAdapter") else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/PortAdapters files should expose concrete adapter types ending in 'PortAdapter'; rename or move '\(declaration.name)'.",
                coordinate: declaration.coordinate
            )
        })

        let hasPortAdapterType = file.topLevelDeclarations.contains {
            $0.kind != .protocol && $0.name.hasSuffix("PortAdapter")
        }

        if !hasPortAdapterType {
            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Infrastructure/PortAdapters files should expose at least one concrete type ending in 'PortAdapter'."
                )
            )
        }

        return diagnostics
    }
}

public struct InfrastructurePortAdaptersInlineTranslationSubsystemPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.port_adapters.inline_translation_subsystem"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructurePortAdapterFile else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind != .protocol,
                  declaration.name.hasSuffix("PortAdapter") else {
                return nil
            }

            let nestedDeclarations = file.nestedNominalDeclarations.filter {
                $0.enclosingTypeName == declaration.name && $0.kind != .protocol
            }
            let parserDeclarations = nestedDeclarations.filter(isParserTranslationShape)
            let modelDeclarations = nestedDeclarations.filter(isParserModelCarrierShape)

            guard !parserDeclarations.isEmpty,
                  !modelDeclarations.isEmpty,
                  hasPublicRawSyntaxEntrypointUsingNestedParser(
                    in: file,
                    adapterTypeName: declaration.name
                  ),
                  hasNonPublicParserModelFlowHelper(
                    in: file,
                    adapterTypeName: declaration.name,
                    parserModelShapeNames: Set(modelDeclarations.map(\.name))
                  ),
                  hasNonPublicInwardProjectionHelper(
                    in: file,
                    adapterTypeName: declaration.name,
                    parserModelShapeNames: Set(modelDeclarations.map(\.name)),
                    context: context
                  ) else {
                return nil
            }

            let culprit = parserDeclarations.first?.name ?? declaration.name
            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/PortAdapters should not keep inline parser/model subsystems like '\(culprit)' inside '\(declaration.name)' when the adapter both parses raw syntax and projects inward data into nested parser-model shapes. Move the parser mechanics, AST/expression/context/value carriers, and context-building helpers to Infrastructure/Translation/Models. Keep the public render entry point, final rendering/interpreting to the boundary output, and parse-plus-render orchestration in the port adapter.",
                coordinate: parserDeclarations.first?.coordinate ?? declaration.coordinate
            )
        }
    }
}

public struct InfrastructurePortAdaptersInlineNormalizationPreparationPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.port_adapters.inline_normalization_preparation"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructurePortAdapterFile else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind != .protocol,
                  declaration.kind != .enum,
                  declaration.name.hasSuffix("PortAdapter") else {
                return nil
            }

            let methods = file.methodDeclarations.filter { $0.enclosingTypeName == declaration.name }
            guard let culprit = firstInlinePortAdapterNormalizationPreparationMethod(
                in: file,
                portAdapterTypeName: declaration.name,
                methods: methods,
                context: context
            ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: portAdapterInlineNormalizationPreparationMessage(for: declaration.name),
                coordinate: culprit.coordinate
            )
        }
    }
}

public struct InfrastructurePortAdaptersInlineObviousBoundaryDecisionLogicPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.port_adapters.inline_obvious_boundary_decision_logic"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructurePortAdapterFile else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind != .protocol,
                  declaration.kind != .enum,
                  declaration.name.hasSuffix("PortAdapter") else {
                return nil
            }

            let methods = file.methodDeclarations.filter { $0.enclosingTypeName == declaration.name }
            guard let culprit = firstInlinePortAdapterObviousBoundaryDecisionLogicMethod(
                in: file,
                portAdapterTypeName: declaration.name,
                methods: methods,
                context: context
            ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: portAdapterInlineObviousBoundaryDecisionLogicMessage(for: declaration.name),
                coordinate: culprit.coordinate
            )
        }
    }
}

public struct InfrastructurePortAdaptersInlineTypedBoundaryCompatibilityEvaluationPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.port_adapters.inline_typed_boundary_compatibility_evaluation"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructurePortAdapterFile else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind != .protocol,
                  declaration.kind != .enum,
                  declaration.name.hasSuffix("PortAdapter") else {
                return nil
            }

            let methods = file.methodDeclarations.filter { $0.enclosingTypeName == declaration.name }
            guard let culprit = firstInlinePortAdapterTypedBoundaryCompatibilityEvaluationMethod(
                in: file,
                portAdapterTypeName: declaration.name,
                methods: methods,
                context: context
            ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: portAdapterInlineTypedBoundaryCompatibilityEvaluationMessage(for: declaration.name),
                coordinate: culprit.coordinate
            )
        }
    }
}

public struct InfrastructurePortAdaptersInlineTypedInteractionDispatchPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.port_adapters.inline_typed_interaction_dispatch"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructurePortAdapterFile else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind != .protocol,
                  declaration.kind != .enum,
                  declaration.name.hasSuffix("PortAdapter") else {
                return nil
            }

            let methods = file.methodDeclarations.filter { $0.enclosingTypeName == declaration.name }
            guard let culprit = firstInlinePortAdapterTypedInteractionDispatchMethod(
                in: file,
                portAdapterTypeName: declaration.name,
                methods: methods,
                context: context
            ) else {
                return nil
            }

            let passiveShapeDestinations = inlineTypedInteractionDispatchPassiveShapeDestinations(
                culprit,
                in: file,
                context: context
            )

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: portAdapterInlineTypedInteractionDispatchMessage(
                    for: declaration.name,
                    passiveShapeDestinations: passiveShapeDestinations
                ),
                coordinate: culprit.coordinate
            )
        }
    }
}

public struct InfrastructureEvaluatorsShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.evaluators.shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureEvaluatorFile else {
            return []
        }

        var diagnostics = file.topLevelDeclarations.compactMap { declaration -> ArchitectureDiagnostic? in
            guard declaration.kind == .protocol else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Evaluators should expose concrete evaluator types rather than protocol '\(declaration.name)'. Likely categories: boundary-specific classifier, selector, or resolver (signs: consumes already-shaped technical inputs and returns a technical classification, selected option, resolved decision, or stable typed failure result without parsing raw boundary data or executing the boundary; architectural note: evaluator files are for concrete technical decision surfaces, with preferred concrete shapes such as Classifier, Selector, or Resolver rather than vague evaluator-model buckets; destination: Infrastructure/Evaluators); translation surface (signs: raw parsing, extraction, normalization, request assembly, or DTO/model projection establishes the technical meaning before any decision is made; architectural note: translation still belongs in Infrastructure/Translation before evaluator logic begins; destination: Infrastructure/Translation); execution or orchestration surface (signs: send, read, write, wait, stream, load, save, retry, emit, or other live boundary work; architectural note: evaluators decide, while adapters execute; destination: Infrastructure/Gateways, Infrastructure/PortAdapters, or Infrastructure/Repositories depending on the boundary). Explicit decomposition guidance: if the logic is still mixed extraction plus evaluation, decompose it before moving it; keep raw parsing and translation in Infrastructure/Translation, keep execution in the owning adapter, and keep only concrete decision-shaped technical logic plus any stable typed classifier/selector/resolver result in Infrastructure/Evaluators.",
                coordinate: declaration.coordinate
            )
        }

        guard !hasEvaluatorDecisionSurface(in: file, context: context) else {
            return diagnostics
        }

        diagnostics.append(
            file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Evaluators does not currently expose a behavior-first evaluator surface. Likely categories: boundary-specific classifier, selector, or resolver (signs: already-shaped technical input comes in, a technical classification, selected option, resolved decision, or stable typed failure result comes out, and the body does not perform raw parsing or boundary execution; architectural note: evaluator classification should be driven by role and behavior first, with concrete shapes like Classifier, Selector, or Resolver preferred over vague evaluator-model naming; destination: Infrastructure/Evaluators); translation surface (signs: inputs are still raw strings, dictionaries, response payload fragments, or other pre-translation values that must be parsed or normalized before any decision is possible; architectural note: translation establishes typed technical meaning before evaluators operate; destination: Infrastructure/Translation); execution or orchestration surface (signs: the type sends, reads, writes, waits, streams, loads, saves, retries, emits, or otherwise coordinates live boundary work; architectural note: execution remains in adapters, not evaluator files; destination: Infrastructure/Gateways, Infrastructure/PortAdapters, or Infrastructure/Repositories). Explicit decomposition guidance: if the logic is still mixed extraction plus evaluation, decompose it before moving it; move raw parsing and translation to Infrastructure/Translation, move execution/orchestration to the owning adapter, and keep only pure decision-shaped technical logic plus any stable typed classifier/selector/resolver result in Infrastructure/Evaluators."
            )
        )

        return diagnostics
    }
}

public struct InfrastructureEvaluatorsNoExecutionOrchestrationSurfacePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.evaluators.no_execution_orchestration_surface"

    public init() {}

    public func evaluate(file: ArchitectureFile, context _: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureEvaluatorFile else {
            return []
        }

        let topLevelConcreteTypeNames = Set(
            file.topLevelDeclarations.compactMap { declaration -> String? in
                guard declaration.kind != .protocol else {
                    return nil
                }

                return declaration.name
            }
        )

        return file.methodDeclarations.compactMap { declaration in
            guard topLevelConcreteTypeNames.contains(declaration.enclosingTypeName),
                  hasEvaluatorExecutionOrchestrationViolation(
                    declaration,
                    in: file
                  ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Evaluators keeps execution or orchestration in '\(declaration.name)'. Likely categories: evaluator surface (signs: already-shaped technical inputs come in and a technical classification, selected option, resolved decision, or stable typed failure result comes out without live boundary work; architectural note: evaluators decide, but do not execute; destination: Infrastructure/Evaluators); gateway, port adapter, or repository execution surface (signs: sends, reads, writes, waits, streams, loads, saves, retries, fetches, performs, dispatches, starts, continues, cancels, or otherwise coordinates live boundary work; architectural note: execution stays in the owning adapter rather than in evaluator files; destination: Infrastructure/Gateways, Infrastructure/PortAdapters, or Infrastructure/Repositories depending on the boundary). Explicit decomposition guidance: keep only pure classifier/selector/resolver logic plus any stable typed evaluator result in Infrastructure/Evaluators, and move live boundary execution or orchestration back to the owning gateway, port adapter, or repository.",
                coordinate: declaration.coordinate
            )
        }
    }
}

public struct InfrastructureEvaluatorsNoTranslationSurfacePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.evaluators.no_translation_surface"

    public init() {}

    public func evaluate(file: ArchitectureFile, context _: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureEvaluatorFile else {
            return []
        }

        let topLevelConcreteTypeNames = Set(
            file.topLevelDeclarations.compactMap { declaration -> String? in
                guard declaration.kind != .protocol else {
                    return nil
                }

                return declaration.name
            }
        )

        return file.methodDeclarations.compactMap { declaration in
            guard topLevelConcreteTypeNames.contains(declaration.enclosingTypeName),
                  hasEvaluatorTranslationViolation(
                    declaration,
                    in: file
                  ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Evaluators keeps translation or parsing in '\(declaration.name)'. Likely categories: evaluator surface (signs: already-shaped technical inputs come in and a technical classification, selected option, resolved decision, or stable typed failure result comes out without raw parsing or request/response shaping; architectural note: evaluators consume translated facts rather than creating them; destination: Infrastructure/Evaluators); translation surface (signs: parses, extracts, decodes, normalizes, encodes, assembles, converts, or otherwise establishes technical meaning from raw or pre-translation values before any decision is possible; architectural note: translation still belongs in Infrastructure/Translation before evaluation begins; destination: Infrastructure/Translation/Models or Infrastructure/Translation/DTOs depending on the boundary shape). Explicit decomposition guidance: move raw parsing, extraction, normalization, and request or response shaping to Infrastructure/Translation first, then keep only the pure classifier/selector/resolver logic in Infrastructure/Evaluators.",
                coordinate: declaration.coordinate
            )
        }
    }
}

public struct InfrastructureTranslationShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.translation.shape"
    private let forbiddenSuffixes = ["Repository", "Gateway", "PortAdapter", "UseCase", "UseCases", "Policy", "Controller", "Route", "ViewModel", "Service"]

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureTranslationFile else {
            return []
        }

        var diagnostics = file.topLevelDeclarations.compactMap { declaration -> ArchitectureDiagnostic? in
            guard declaration.kind == .protocol else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Translation files should contain concrete translation shapes, not protocol '\(declaration.name)'.",
                coordinate: declaration.coordinate
            )
        }

        diagnostics.append(contentsOf: file.topLevelDeclarations.compactMap { declaration in
            guard forbiddenSuffixes.contains(where: { declaration.name.hasSuffix($0) }) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Translation files should hold translation shapes, not '\(declaration.name)'.",
                coordinate: declaration.coordinate
            )
        })

        return diagnostics
    }
}

public struct InfrastructureTranslationModelsIntermediaryShapingSurfacePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.translation.models.intermediary_shaping_surface"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureTranslationModelFile else {
            return []
        }

        guard !hasInwardTranslationSurface(in: file, context: context)
                && !hasParserModelTranslationSurface(in: file, context: context)
                && !hasConfigurationNormalizationSurface(in: file, context: context)
                && !hasIntermediaryRequestDefinitionTranslationSurface(in: file, context: context) else {
            return []
        }

        return [
            file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Translation/Models does not currently expose an intermediary-shaping surface. Likely categories: inward normalization or mapping surface (signs: translates provider or storage data inward to Domain types, Application contracts, or explicit Infrastructure errors; architectural note: model files may still own explicit inward normalization when they translate boundary data into inward shapes; destination: Infrastructure/Translation/Models); normalized boundary-configuration shaping (signs: canonicalizes, defaults, coerces, or otherwise reshapes raw config, configuration, sandbox, policy, access, approval, posture, capability, or similar boundary inputs into adapter-owned normalized carriers; architectural note: model files own adapter-side normalization before any final provider or transport request shape exists; destination: Infrastructure/Translation/Models); intermediary request-definition shaping (signs: assembles adapter-owned request-definition, launch-definition, startup, command, context, or other intermediary carriers before the final provider or transport request or response shape exists; architectural note: model files stop at intermediary meaning and should not own finalized provider or transport request or response shapes; destination: Infrastructure/Translation/Models). Explicit decomposition guidance: if this file only contains final provider or transport request or response shapes, move those passive carriers and any adjacent DTO-side translators to Infrastructure/Translation/DTOs; if it contains execution, pagination, transport lifecycle, HTTP/status handling, or response orchestration, move that work to Infrastructure/Gateways; and keep only normalized config, intermediary request-definition carriers, parser-model shaping, or explicit inward normalization in Infrastructure/Translation/Models."
            )
        ]
    }
}

public struct InfrastructureTranslationModelsNoFinalTransportProviderShapeSurfacePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.translation.models.no_final_transport_provider_shape_surface"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureTranslationModelFile else {
            return []
        }

        return finalTransportProviderShapeDiagnostics(
            in: file,
            context: context
        ).map { culprit in
            file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Translation/Models keeps final provider or transport request or response shaping in '\(culprit.name)'. Likely categories: passive provider-facing or transport-facing request or response carrier (signs: request, response, envelope, body, params, data, payload, URLRequest, or HTTPURLResponse shapes that represent what actually crosses the boundary; architectural note: final boundary request and response representations belong on the DTO side of Infrastructure translation, not in intermediary models; destination: Infrastructure/Translation/DTOs); DTO-side directional translator or builder (signs: assembles a final outbound request shape such as URLRequest, request body, headers, params, or provider envelope from intermediary model inputs, or shapes inbound response carriers before inward mapping; architectural note: DTO-side translation may live adjacent to passive DTO carriers, but the DTO structs themselves should remain passive; destination: Infrastructure/Translation/DTOs); mixed intermediary plus final boundary shaping (signs: the same model both normalizes config or intermediary request-definition carriers and also emits final provider or transport request or response shapes; architectural note: intermediary shaping belongs in Models, while final provider or transport request or response shaping belongs in DTOs; destination: split between Infrastructure/Translation/Models and Infrastructure/Translation/DTOs). Explicit decomposition guidance: keep normalized config and intermediary request-definition carriers in Infrastructure/Translation/Models, move passive final request or response carriers to Infrastructure/Translation/DTOs, place any DTO-side directional translator or builder adjacent to those DTO carriers, and keep execution or orchestration out of both translation buckets.",
                coordinate: culprit.coordinate
            )
        }
    }
}

public struct InfrastructureTranslationModelsSplitRequestShapingPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.translation.models.split_request_shaping"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureTranslationModelFile else {
            return []
        }

        let topLevelConcreteTypeNames = Set(
            file.topLevelDeclarations.compactMap { declaration -> String? in
                guard declaration.kind != .protocol else {
                    return nil
                }

                return declaration.name
            }
        )

        return topLevelConcreteTypeNames.compactMap { typeName in
            let methods = file.methodDeclarations.filter { declaration in
                declaration.enclosingTypeName == typeName
                    && !declaration.isPrivateOrFileprivate
            }

            guard hasConfigurationNormalizationResponsibility(
                in: methods,
                file: file,
                context: context
            ),
            hasIntermediaryRequestDefinitionShapingResponsibility(
                in: methods,
                file: file,
                context: context
            ) else {
                return nil
            }

            let coordinate = file.topLevelDeclarations.first(where: { $0.name == typeName })?.coordinate
            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Translation/Models combines normalized boundary-configuration shaping and intermediary request-definition shaping inside '\(typeName)'. Likely categories: normalized boundary-configuration model (signs: canonicalizes, defaults, coerces, or otherwise reshapes config, configuration, sandbox, policy, access, approval, posture, capability, or similar boundary inputs into stable adapter-owned carriers; architectural note: normalized boundary configuration is one intermediary responsibility; destination: Infrastructure/Translation/Models); intermediary request-definition model (signs: assembles request-definition, launch-definition, startup, command, context, or similar adapter-owned carriers before the final provider or transport request or response shape exists; architectural note: request-definition shaping is a separate intermediary responsibility from normalized config; destination: Infrastructure/Translation/Models); mixed model (signs: the same type normalizes raw boundary configuration and also assembles intermediary request-definition carriers; architectural note: keep intermediary roles small and separate before DTO-side final shaping or gateway execution begins; destination: split into dedicated Infrastructure/Translation/Models types). Explicit decomposition guidance: keep one model dedicated to normalized boundary configuration, keep a second model dedicated to intermediary request-definition shaping, move any final provider or transport request or response carriers or DTO-side builders to Infrastructure/Translation/DTOs, and keep execution or orchestration in Infrastructure/Gateways.",
                coordinate: coordinate
            )
        }
    }
}

public struct InfrastructureTranslationDTOsShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.translation.dtos.shape"
    private let forbiddenSuffixes = [
        "Gateway",
        "Repository",
        "PortAdapter",
        "UseCase",
        "Policy",
        "Service",
        "Controller",
        "Route",
        "ViewModel"
    ]

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureTranslationDTOFile else {
            return []
        }

        var diagnostics = file.topLevelDeclarations.compactMap { declaration -> ArchitectureDiagnostic? in
            guard declaration.kind == .protocol else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Translation/DTOs exposes protocol '\(declaration.name)' instead of DTO-side boundary shapes. Likely categories: passive DTO carrier (signs: provider-facing or transport-facing request, response, envelope, body, params, or data fields with no execution behavior; architectural note: DTO types themselves stay passive; destination: Infrastructure/Translation/DTOs); adjacent DTO-side directional translator or builder (signs: a sibling translator shapes final outbound request carriers or inbound response carriers next to passive DTOs without owning execution; architectural note: DTO-side translation may live adjacent to DTO carriers, but should not be declared as a protocol abstraction here; destination: Infrastructure/Translation/DTOs); invalid abstraction or orchestration surface (signs: protocol seams, execution entry points, transport lifecycle, or workflow behavior; architectural note: DTO space is for passive carriers plus adjacent concrete DTO-side translation helpers only; destination: concrete DTO carriers and translators stay in Infrastructure/Translation/DTOs, while execution belongs in Infrastructure/Gateways or inward seams elsewhere). Explicit decomposition guidance: keep passive request or response carriers as concrete DTO types, keep any DTO-side directional translators or builders concrete and adjacent to those carriers, and move protocol abstractions or execution logic out of Infrastructure/Translation/DTOs.",
                coordinate: declaration.coordinate
            )
        }

        diagnostics.append(contentsOf: file.topLevelDeclarations.compactMap { declaration in
            guard forbiddenSuffixes.contains(where: { declaration.name.hasSuffix($0) }) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Translation/DTOs uses '\(declaration.name)' for a non-DTO-shaped transport role. Likely categories: passive DTO carrier (signs: concrete request, response, envelope, body, params, payload, or data carriers that mirror provider-facing or transport-facing shapes; architectural note: DTO files should reveal concrete boundary payload types explicitly; destination: Infrastructure/Translation/DTOs); adjacent DTO-side directional translator or builder (signs: a concrete sibling type builds final outbound request carriers or shapes inbound response carriers next to DTOs; architectural note: DTO-side builders are allowed when they remain shaping-only and adjacent to passive DTO carriers; destination: Infrastructure/Translation/DTOs); invalid role (signs: repository, gateway, port adapter, use case, policy, service, controller, route, or other execution or orchestration role; architectural note: DTO files are not catch-all infrastructure buckets; destination: move the non-DTO role to its owning folder and keep only DTO carriers or adjacent DTO-side translators here). Explicit decomposition guidance: keep passive DTO carriers and any adjacent shaping-only translator or builder in Infrastructure/Translation/DTOs, but move execution, orchestration, or other adapter roles to their owning Infrastructure folders.",
                coordinate: declaration.coordinate
            )
        })

        let hasDTOType = file.topLevelDeclarations.contains { declaration in
            switch declaration.kind {
            case .class, .struct, .actor:
                return declaration.name.hasSuffix("DTO")
            case .protocol, .enum:
                return false
            }
        }

        if !hasDTOType {
            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Infrastructure/Translation/DTOs does not expose a concrete DTO carrier. Likely categories: passive DTO carrier missing (signs: the file only contains helpers or translators without a request, response, envelope, body, params, payload, or data carrier ending in 'DTO'; architectural note: DTO-side translators must be adjacent to concrete passive DTO carriers rather than replacing them; destination: Infrastructure/Translation/DTOs); adjacent DTO-side directional translator without a carrier (signs: builder or translator behavior exists, but no DTO carrier anchors the file's provider-facing or transport-facing payload role; architectural note: DTO-side translation is allowed only when it is anchored by passive DTO carriers; destination: Infrastructure/Translation/DTOs); invalid non-DTO role (signs: the file is really an execution helper, normalization model, or unrelated infrastructure type; architectural note: DTO folders should not host non-DTO work under a misleading name; destination: move intermediary shaping to Infrastructure/Translation/Models or execution to Infrastructure/Gateways as appropriate). Explicit decomposition guidance: add the passive DTO carrier that represents the final provider or transport request or response shape, keep any adjacent DTO-side translator or builder next to it, and move intermediary normalization or execution responsibilities out of the DTO file."
                )
            )
        }

        return diagnostics
    }
}

public struct InfrastructureTranslationDTOsPassiveCarrierPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.translation.dtos.passive_carrier_surface"

    public init() {}

    public func evaluate(file: ArchitectureFile, context _: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureTranslationDTOFile else {
            return []
        }

        let dtoTypeNames = Set(
            file.topLevelDeclarations.compactMap { declaration -> String? in
                guard declaration.kind != .protocol,
                      declaration.name.hasSuffix("DTO") else {
                    return nil
                }

                return declaration.name
            }
        )

        var diagnostics = file.methodDeclarations.compactMap { declaration -> ArchitectureDiagnostic? in
            guard dtoTypeNames.contains(declaration.enclosingTypeName),
                  !declaration.isPrivateOrFileprivate else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "DTO type '\(declaration.enclosingTypeName)' owns behavior through method '\(declaration.name)'. Likely categories: passive DTO carrier (signs: stores request, response, envelope, body, params, payload, or data fields only; architectural note: DTO types themselves must stay passive; destination: Infrastructure/Translation/DTOs); adjacent DTO-side directional translator or builder (signs: a sibling translator builds the final outbound request shape or shapes the inbound response carrier without turning the DTO itself into a behavior bag; architectural note: DTO-side translation is allowed only adjacent to the carrier, not on the DTO struct itself; destination: Infrastructure/Translation/DTOs); misplaced intermediary or execution behavior (signs: normalization, request-definition shaping, inward projection, execution, pagination, or transport lifecycle work lives directly on the DTO type; architectural note: intermediary shaping belongs in Models and execution belongs in Gateways; destination: Infrastructure/Translation/Models or Infrastructure/Gateways depending on the behavior). Explicit decomposition guidance: keep the DTO type passive, move final outbound or inbound DTO-side shaping to an adjacent translator or builder in Infrastructure/Translation/DTOs, move normalized or intermediary shaping to Infrastructure/Translation/Models, and move execution or orchestration to Infrastructure/Gateways.",
                coordinate: declaration.coordinate
            )
        }

        diagnostics.append(contentsOf: file.computedPropertyDeclarations.compactMap { declaration in
            guard dtoTypeNames.contains(declaration.enclosingTypeName) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "DTO type '\(declaration.enclosingTypeName)' owns behavior through computed property '\(declaration.name)'. Likely categories: passive DTO carrier (signs: stores provider-facing or transport-facing request or response fields only; architectural note: DTO carriers must stay passive; destination: Infrastructure/Translation/DTOs); adjacent DTO-side directional translator or builder (signs: any shaping logic needed for final outbound or inbound boundary carriers lives in a sibling translator rather than on the DTO; architectural note: keep DTO translation adjacent, not attached to the carrier type; destination: Infrastructure/Translation/DTOs); misplaced intermediary or execution behavior (signs: derived normalization, request-definition shaping, inward projection, or transport lifecycle behavior is embedded on the DTO type; architectural note: Models and Gateways own those concerns, not DTO carriers; destination: Infrastructure/Translation/Models or Infrastructure/Gateways depending on the behavior). Explicit decomposition guidance: keep passive DTO fields on the DTO type, move DTO-side shaping to an adjacent translator or builder, and move intermediary normalization or execution logic out of the DTO carrier.",
                coordinate: declaration.coordinate
            )
        })

        return diagnostics
    }
}

public struct InfrastructureTranslationDTOsNoIntermediaryOrNormalizationSurfacePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.translation.dtos.no_intermediary_or_normalization_surface"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureTranslationDTOFile else {
            return []
        }

        let topLevelConcreteTypeNames = Set(
            file.topLevelDeclarations.compactMap { declaration -> String? in
                guard declaration.kind != .protocol else {
                    return nil
                }

                return declaration.name
            }
        )

        return file.methodDeclarations.compactMap { declaration in
            guard topLevelConcreteTypeNames.contains(declaration.enclosingTypeName),
                  !declaration.isPrivateOrFileprivate,
                  hasDTOIntermediaryOrNormalizationViolation(
                    declaration,
                    file: file,
                    context: context
                  ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Translation/DTOs keeps intermediary or normalization shaping in '\(declaration.name)'. Likely categories: passive DTO carrier (signs: provider-facing or transport-facing request, response, envelope, body, params, payload, or data fields with no intermediary normalization behavior; architectural note: DTO carriers should stay passive and represent only final boundary-facing shapes; destination: Infrastructure/Translation/DTOs); adapter-owned intermediary or normalized shaping (signs: config normalization, fallback/defaulting, coercion, request-definition assembly, intermediary context shaping, or other adapter-owned shaping before a final provider or transport shape exists; architectural note: that intermediary work belongs in Models, not in DTO space; destination: Infrastructure/Translation/Models); mixed DTO plus intermediary shaping (signs: the same DTO-side file both represents final boundary payloads and performs normalized or intermediary shaping; architectural note: final provider or transport shapes and intermediary shaping should be decomposed before execution; destination: split between Infrastructure/Translation/DTOs and Infrastructure/Translation/Models). Explicit decomposition guidance: keep passive final request or response carriers in Infrastructure/Translation/DTOs, place any DTO-side directional translator adjacent to those carriers only when it assembles the final boundary-facing shape, move normalized config and intermediary request-definition shaping to Infrastructure/Translation/Models, and keep execution out of both.",
                coordinate: declaration.coordinate
            )
        }
    }
}

public struct InfrastructureTranslationDTOsNoExecutionOrchestrationSurfacePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.translation.dtos.no_execution_orchestration_surface"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureTranslationDTOFile else {
            return []
        }

        let topLevelConcreteTypeNames = Set(
            file.topLevelDeclarations.compactMap { declaration -> String? in
                guard declaration.kind != .protocol else {
                    return nil
                }

                return declaration.name
            }
        )

        return file.methodDeclarations.compactMap { declaration in
            guard topLevelConcreteTypeNames.contains(declaration.enclosingTypeName),
                  !declaration.isPrivateOrFileprivate,
                  hasDTOExecutionOrchestrationViolation(declaration) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Translation/DTOs keeps execution or orchestration in '\(declaration.name)'. Likely categories: passive DTO carrier (signs: stores request, response, envelope, body, params, or data fields only; architectural note: DTO carriers stay passive and should not own execution; destination: Infrastructure/Translation/DTOs); adjacent DTO-side directional translator or builder (signs: shapes the final outbound request or inbound response carrier without sending it, waiting on it, or handling transport lifecycle; architectural note: DTO-side translation is allowed only while it remains shaping-only; destination: Infrastructure/Translation/DTOs); invalid execution or orchestration logic (signs: fetches, sends, loads, streams, waits, paginates, retries, processes responses, or otherwise performs transport lifecycle work; architectural note: execution belongs in gateways, not in DTO files; destination: Infrastructure/Gateways). Explicit decomposition guidance: keep passive DTO carriers and shaping-only DTO-side translators in Infrastructure/Translation/DTOs, move send/fetch/execute/decode-orchestrate/stream/wait/paginate logic to Infrastructure/Gateways, and keep normalized or intermediary shaping in Infrastructure/Translation/Models.",
                coordinate: declaration.coordinate
            )
        }
    }
}

public struct InfrastructureGatewaysRejectPrivateInwardTranslationHelpersPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.gateways.private_inward_translation_helpers"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureGatewayFile else {
            return []
        }

        return file.methodDeclarations.compactMap { declaration in
            guard !declaration.isPublicOrOpen else {
                return nil
            }

            guard returnsInwardNormalizedType(declaration, context: context) else {
                return nil
            }

            guard declaration.parameterTypeNames.contains(where: { typeName in
                isInwardTranslationSourceTypeName(
                    typeName,
                    in: file,
                    enclosingTypeName: declaration.enclosingTypeName,
                    context: context
                )
            }) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Gateways should orchestrate translation, not hide non-public helper methods like '\(declaration.name)' that accept translation-source shapes and return Domain types, Application contracts, or explicit Infrastructure error types. Move the boundary-crossing translation onto an Infrastructure/Translation/Models shape and expose it with an explicit directional method such as toDomain, toContract, or toInfrastructureError.",
                coordinate: declaration.coordinate
            )
        }
    }
}

public struct InfrastructureApplicationContractBehaviorAttachmentPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.application_contract_behavior_attachment"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructure else {
            return []
        }

        var diagnostics: [ArchitectureDiagnostic] = []

        diagnostics.append(contentsOf: file.initializerDeclarations.compactMap { declaration in
            guard let contractDeclaration = infrastructureAttachedApplicationContractDeclaration(
                named: declaration.enclosingTypeName,
                from: file,
                context: context
            ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: infrastructureApplicationContractBehaviorAttachmentMessage(
                    surfaceDescription: "Initializer '\(declaration.enclosingTypeName).init(...)'",
                    contractName: contractDeclaration.name,
                    ownerPath: contractDeclaration.repoRelativePath
                ),
                coordinate: declaration.coordinate
            )
        })

        diagnostics.append(contentsOf: file.methodDeclarations.compactMap { declaration in
            guard let contractDeclaration = infrastructureAttachedApplicationContractDeclaration(
                named: declaration.enclosingTypeName,
                from: file,
                context: context
            ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: infrastructureApplicationContractBehaviorAttachmentMessage(
                    surfaceDescription: "Method '\(declaration.name)' on contract '\(declaration.enclosingTypeName)'",
                    contractName: contractDeclaration.name,
                    ownerPath: contractDeclaration.repoRelativePath
                ),
                coordinate: declaration.coordinate
            )
        })

        diagnostics.append(contentsOf: file.computedPropertyDeclarations.compactMap { declaration in
            guard let contractDeclaration = infrastructureAttachedApplicationContractDeclaration(
                named: declaration.enclosingTypeName,
                from: file,
                context: context
            ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: infrastructureApplicationContractBehaviorAttachmentMessage(
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

public struct InfrastructureGatewaysNestedIntermediaryTranslationShapesPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.gateways.nested_intermediary_translation_shapes"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureGatewayFile else {
            return []
        }

        let normalizationClusterKeys = nestedGatewayNormalizationClusterShapeKeys(
            in: file,
            context: context
        )

        return file.nestedNominalDeclarations.compactMap { declaration in
            guard normalizationClusterKeys.contains(shapeKey(for: declaration)) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure/Gateways should not declare nested intermediary translation shape '\(declaration.name)' inside '\(declaration.enclosingTypeName)' when that shape participates in inward normalization or a staged gateway-owned normalization pipeline. Move the adapter-owned intermediary shape to Infrastructure/Translation/Models and let the gateway consume it through an explicit directional translator such as toDomain, toContract, or toInfrastructureError.",
                coordinate: declaration.coordinate
            )
        }
    }

    private func nestedGatewayNormalizationClusterShapeKeys(
        in file: ArchitectureFile,
        context: ProjectContext
    ) -> Set<String> {
        let nestedDeclarations = file.nestedNominalDeclarations.filter { declaration in
            declaration.kind != .protocol && isLikelyNestedIntermediaryShape(declaration)
        }
        guard !nestedDeclarations.isEmpty else {
            return []
        }

        var clusterShapeKeys = Set(
            nestedDeclarations.compactMap { declaration -> String? in
                directlyParticipatesInInwardNormalization(
                    declaration,
                    file: file,
                    context: context
                ) ? shapeKey(for: declaration) : nil
            }
        )
        guard !clusterShapeKeys.isEmpty else {
            return []
        }

        var changed = true
        while changed {
            changed = false

            for declaration in nestedDeclarations {
                let declarationKey = shapeKey(for: declaration)
                guard !clusterShapeKeys.contains(declarationKey) else {
                    continue
                }

                guard participatesInStagedNormalizationPipeline(
                    declaration,
                    file: file,
                    clusterShapeKeys: clusterShapeKeys
                ) else {
                    continue
                }

                clusterShapeKeys.insert(declarationKey)
                changed = true
            }
        }

        return clusterShapeKeys
    }

    private func directlyParticipatesInInwardNormalization(
        _ declaration: ArchitectureNestedNominalDeclaration,
        file: ArchitectureFile,
        context: ProjectContext
    ) -> Bool {
        file.methodDeclarations.contains { method in
            guard method.enclosingTypeName == declaration.enclosingTypeName else {
                return false
            }

            let referencesNestedShape = method.parameterTypeNames.contains(declaration.name)
                || method.returnTypeNames.contains(declaration.name)
            guard referencesNestedShape else {
                return false
            }

            return returnsInwardNormalizedType(method, context: context)
                || acceptsInwardNormalizedType(method, context: context)
                || returnsExtractedInwardTranslationSourceType(method, context: context)
        }
    }

    private func participatesInStagedNormalizationPipeline(
        _ declaration: ArchitectureNestedNominalDeclaration,
        file: ArchitectureFile,
        clusterShapeKeys: Set<String>
    ) -> Bool {
        let methods = file.methodDeclarations.filter { $0.enclosingTypeName == declaration.enclosingTypeName }
        let methodsReturningDeclaration = methods.filter { $0.returnTypeNames.contains(declaration.name) }
        guard !methodsReturningDeclaration.isEmpty else {
            return false
        }

        let returningMethodNames = Set(methodsReturningDeclaration.map(\.name))

        return methods.contains { method in
            let operationalUses = operationalUses(
                in: file,
                enclosingTypeName: method.enclosingTypeName,
                methodName: method.name
            )
            let usesExistingClusterShape = operationalUses.contains { occurrence in
                clusterShapeKeys.contains(shapeKey(enclosingTypeName: method.enclosingTypeName, name: occurrence.baseName))
            }
            guard usesExistingClusterShape else {
                return false
            }

            return method.returnTypeNames.contains(declaration.name)
                || operationalUses.contains { occurrence in
                    returningMethodNames.contains(occurrence.baseName)
                }
        }
    }

    private func operationalUses(
        in file: ArchitectureFile,
        enclosingTypeName: String,
        methodName: String
    ) -> [ArchitectureOperationalUseOccurrence] {
        file.operationalUseOccurrences.filter { occurrence in
            occurrence.enclosingTypeName == enclosingTypeName
                && occurrence.enclosingMethodName == methodName
        }
    }

    private func shapeKey(for declaration: ArchitectureNestedNominalDeclaration) -> String {
        shapeKey(enclosingTypeName: declaration.enclosingTypeName, name: declaration.name)
    }

    private func shapeKey(enclosingTypeName: String, name: String) -> String {
        "\(enclosingTypeName).\(name)"
    }
}

public struct InfrastructureGatewaysNoNestedBoundaryShapingHelpersPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.gateways.no_nested_boundary_shaping_helpers"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureGatewayFile else {
            return []
        }

        return file.nestedNominalDeclarations.compactMap { declaration in
            guard let classification = classifyNestedBoundaryShapingHelper(
                declaration,
                in: file,
                context: context
            ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: nestedBoundaryShapingHelperMessage(
                    nestedTypeName: declaration.name,
                    gatewayTypeName: declaration.enclosingTypeName,
                    classification: classification
                ),
                coordinate: declaration.coordinate
            )
        }
    }
}

public struct InfrastructureGatewaysInlineRequestDefinitionShapingPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.gateways.inline_request_definition_shaping"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureGatewayFile else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard declaration.kind != .protocol,
                  declaration.name.hasSuffix("Gateway") else {
                return nil
            }

            let methods = file.methodDeclarations.filter { $0.enclosingTypeName == declaration.name }
            guard gatewayUsesExtractedRequestShapingModel(
                in: file,
                gatewayTypeName: declaration.name,
                methods: methods,
                context: context
            ) else {
                return nil
            }

            guard hasInlineGatewayRequestShapingEvidence(
                in: file,
                gatewayTypeName: declaration.name,
                methods: methods,
                context: context
            ) else {
                return nil
            }

            guard hasGatewayExecutionFlowEvidence(
                in: file,
                gatewayTypeName: declaration.name,
                methods: methods
            ) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: gatewayInlineRequestDefinitionRegressionMessage(for: declaration.name),
                coordinate: firstInlineGatewayRequestShapingCoordinate(
                    in: file,
                    gatewayTypeName: declaration.name,
                    methods: methods,
                    context: context
                ) ?? declaration.coordinate
            )
        }
    }
}

private func returnsExtractedInwardTranslationSourceType(
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

        return isInwardTranslationSourceDeclaration(indexedDeclaration)
    }
}

private func infrastructureApplicationContractBehaviorAttachmentMessage(
    surfaceDescription: String,
    contractName: String,
    ownerPath: String
) -> String {
    "\(surfaceDescription) attaches Infrastructure-owned behavior to Application contract type '\(contractName)'. Adapter-local parsing, accessor, normalization, or request-shaping behavior must not be attached to Application contracts. Likely categories: contract-local observational evaluator (signs: direct case projection or simple collaborator-free derivation that expresses contract-owned meaning only; architectural note: if the behavior is truly part of the contract's meaning, keep it with the contract surface in its owning file; destination: \(ownerPath)); infrastructure parsing or intermediary shaping helper (signs: primitive coercion, key lookup, fallback/defaulting, trimming, recursive search, provider or runtime config interpretation, normalized config shaping, request-definition ingredient extraction, or boundary-specific accessor helpers before a final provider or transport shape exists; architectural note: this is adapter-owned intermediary translation rather than contract-owned meaning; destination: Infrastructure/Translation/Models); final provider or transport request or response shaping helper (signs: URLRequest assembly, request body or headers construction, response envelope shaping, or other final boundary-facing carrier work; architectural note: final provider or transport request or response shaping belongs with passive DTO carriers and adjacent DTO-side translators, not on Application contracts; destination: Infrastructure/Translation/DTOs); gateway or port-adapter orchestration (signs: combines normalized values with transport handling, workspace or runtime defaults, or other boundary execution flow; architectural note: gateways and port adapters coordinate boundary execution but should consume explicit translation shapes instead of attaching helpers to inward contracts; destination: Infrastructure/Gateways or Infrastructure/PortAdapters); seam-backed application operation (signs: the behavior actually belongs to an abstraction seam rather than a concrete adapter; architectural note: if the logic is not concrete Infrastructure, route it inward through an Application seam instead of leaving it attached to the contract; destination: Application/UseCases). Explicit decomposition guidance: separate direct case projection or pure contract-local derivation from adapter coercion, key lookup, fallback/defaulting, recursive search, provider or runtime interpretation, intermediary request-definition shaping, and final boundary-facing request or response shaping. After the split, keep only truly contract-local observational evaluation in \(ownerPath), move adapter-local parsing/accessor/normalization/intermediary shaping to Infrastructure/Translation/Models, move final provider or transport request or response shaping to Infrastructure/Translation/DTOs, keep boundary execution orchestration in Infrastructure/Gateways or Infrastructure/PortAdapters, and move seam-backed application behavior to Application/UseCases."
}

private func infrastructureAttachedApplicationContractDeclaration(
    named typeName: String,
    from file: ArchitectureFile,
    context: ProjectContext
) -> IndexedDeclaration? {
    guard let declaration = context.uniqueDeclaration(named: typeName),
          declaration.repoRelativePath != file.repoRelativePath else {
        return nil
    }

    switch declaration.roleFolder {
    case .applicationContractsCommands, .applicationContractsPorts, .applicationContractsWorkflow:
        return declaration
        default:
        return nil
    }
}

private func gatewayInlineBoundaryConfigurationShapingMessage(for gatewayTypeName: String) -> String {
    "'\(gatewayTypeName)' keeps inline boundary-configuration shaping inside Infrastructure/Gateways. Likely categories: boundary configuration normalization (signs: trims, defaults, canonicalizes, coerces, interprets, or otherwise reshapes raw config, configuration, sandbox, policy, access, approval, posture, capability, option, or similar boundary inputs into adapter-owned normalized carriers; architectural note: gateways should consume explicit normalized boundary-configuration shapes instead of deriving them inline; destination: Infrastructure/Translation/Models); mixed intermediary plus final boundary shaping (signs: the same gateway normalizes raw boundary configuration and also participates in request-definition, payload, startup, launch, session, turn, command, message, input, context, policy, or final provider or transport request assembly; architectural note: split intermediary normalization from final boundary-facing shapes before execution begins; destination: split between Infrastructure/Translation/Models and Infrastructure/Translation/DTOs); execution or orchestration surface (signs: send, fetch, perform, stream, paginate, wait, or other transport lifecycle work; architectural note: execution remains in the gateway only after shaping is extracted; destination: Infrastructure/Gateways). Explicit decomposition guidance: extract a translation model dedicated to boundary-configuration shaping and a stable normalized carrier, move any final provider or transport request or response carriers or adjacent DTO-side translators to Infrastructure/Translation/DTOs, and keep only concrete boundary execution, transport handling, pagination, response handling, and real gateway orchestration in the gateway."
}

private func gatewayInlineBoundaryDefinitionShapingMessage(for gatewayTypeName: String) -> String {
    "'\(gatewayTypeName)' keeps inline boundary-definition shaping inside Infrastructure/Gateways. Likely categories: intermediary boundary-definition shaping (signs: assembles request-definition, startup, launch, session, turn, command, message, input, context, policy, query, operation, variables, or similar adapter-owned carriers before the final provider or transport request or response shape exists; architectural note: gateways should execute or orchestrate boundaries, not own intermediary boundary-definition shaping; destination: Infrastructure/Translation/Models); final provider or transport request or response shaping (signs: assembles final outbound request or inbound response carriers such as passive request, response, envelope, body, params, data, payload, URLRequest, or HTTPURLResponse shapes; architectural note: final provider or transport boundary-facing shapes belong to DTO files, with any directional translator or builder adjacent to passive DTO carriers; destination: Infrastructure/Translation/DTOs); mixed boundary configuration plus boundary definition shaping (signs: the same gateway normalizes raw boundary configuration and then combines it with identifiers, prompts, titles, workspace paths, variables, flags, options, policy values, or transport-facing request ingredients; architectural note: split normalized config, intermediary boundary-definition shaping, and final boundary-facing DTO shaping before execution; destination: split between Infrastructure/Translation/Models and Infrastructure/Translation/DTOs). Explicit decomposition guidance: extract boundary-configuration shaping into Infrastructure/Translation/Models when raw config interpretation is present, extract intermediary boundary-definition carriers into Infrastructure/Translation/Models, move passive final provider or transport request or response carriers and any adjacent DTO-side translator or builder to Infrastructure/Translation/DTOs, and keep only concrete boundary execution, transport handling, pagination, response handling, and real gateway orchestration in the gateway."
}

private func gatewayInlineOutboundRequestTranslationMessage(for gatewayTypeName: String) -> String {
    "'\(gatewayTypeName)' performs final outbound API/protocol/provider/transport translation inline inside a real execution gateway. This rule is narrower than infrastructure.gateways.inline_boundary_definition_shaping: that broader rule covers broad boundary-definition shaping, while this rule owns the case where a gateway constructs a final outbound request/protocol translation result and immediately hands it to send, write, or execute transport logic. Likely categories: DTO-class outbound translation work (signs: a real execution method or gateway-local private helper constructs the final outbound API/protocol/provider/transport-facing shape and hands it straight to concrete transport execution; architectural note: DTO-class translation belongs in DTO-side translation surfaces that the gateway consumes rather than rebuilding inline; destination: Infrastructure/Translation/DTOs); mixed non-DTO shaping plus DTO-class outbound translation (signs: config, parser, storage, or other non-DTO technical shaping is mixed together with final outbound translation before the transport handoff; architectural note: split non-DTO technical translation from DTO-class outbound translation before execution begins; destination: split between Infrastructure/Translation/Models and Infrastructure/Translation/DTOs); execution-only gateway orchestration (signs: the remaining behavior is concrete send/write/execute flow, waiting, streaming, lifecycle handling, transport coordination, or response handling; architectural note: gateways should keep only boundary execution and orchestration once translation is extracted; destination: Infrastructure/Gateways). Explicit decomposition guidance: extract final outbound request/protocol translation into Infrastructure/Translation/DTOs, including any DTO-class shapes and adjacent DTO-side builders, translators, or parsers that still perform DTO-class translation work; if raw config, parser, storage, or other non-DTO technical shaping is mixed in, split that work into Infrastructure/Translation/Models; keep only gateway execution/orchestration such as send/write/execute, waiting, streaming, transport lifecycle handling, and response processing in Infrastructure/Gateways."
}

private func gatewayInlineNormalizationPreparationMessage(for gatewayTypeName: String) -> String {
    "'\(gatewayTypeName)' keeps inline normalization/preparation helper logic inside a real execution gateway. This rule is intentionally under-inclusive: it only targets gateway-local private helpers that take raw or pre-translation technical input, return a normalized technical value or small passive intermediary shape, and show a real normalization/preparation role without executing the boundary. Likely categories: normalized intermediary technical shaping (signs: raw or pre-translation technical input such as primitives, primitive collections, config fragments, path/input/request fragments, or other unnormalized technical carriers is trimmed, defaulted, canonicalized, standardized, coerced, expanded, sanitized, or otherwise prepared into a stable technical value or small passive intermediary shape; architectural note: once normalization/preparation becomes a distinct shaping concern, it belongs in Translation rather than inline gateway code; destination: Infrastructure/Translation/Models); final passive boundary-facing shaping (signs: the helper's normalization/preparation work is actually producing a passive final provider or transport request, response, envelope, body, params, payload, URLRequest, or HTTPURLResponse-facing shape; architectural note: when normalization/preparation owns final passive boundary-facing output, route that passive shape to DTO-side translation instead of hiding it in the gateway; destination: Infrastructure/Translation/DTOs); execution, runtime control, or orchestration helper (signs: response correlation, timeout/deadline handling, loop/runtime control, transport lifecycle behavior, send/write/execute/wait/stream flow, or other live boundary coordination remains present; architectural note: real execution, runtime control, and orchestration stay in Infrastructure/Gateways and are intentionally excluded from this rule; destination: Infrastructure/Gateways). Explicit decomposition guidance: if normalization/preparation is mixed with execution or runtime control, split it first; keep normalization/preparation in Infrastructure/Translation/Models by default, use Infrastructure/Translation/DTOs only when the extracted passive output is clearly final boundary-facing, and keep execution, runtime control, transport lifecycle handling, and orchestration in Infrastructure/Gateways."
}

private func gatewayInlineObviousBoundaryDecisionLogicMessage(for gatewayTypeName: String) -> String {
    "'\(gatewayTypeName)' keeps obvious typed technical decision logic inline inside a real execution gateway. This rule is intentionally narrow: it only targets gateway-local helpers that take already-shaped technical inputs, return a typed technical decision, and do not perform raw parsing or execution. Likely categories: boundary-specific selector, classifier, or resolver (signs: typed technical inputs go in, a typed technical selection/classification/resolution comes out, and the helper body is mostly comparison or selection logic rather than transport work; architectural note: gateways may consume evaluator results, but pure decision-shaped technical logic should live in Infrastructure/Evaluators once translation is complete; destination: Infrastructure/Evaluators); translation helper (signs: raw strings, dictionaries, payload fragments, or other pre-translation values still need parsing, extraction, normalization, or request/response shaping before a decision is possible; architectural note: translation establishes typed technical meaning before evaluator logic begins; destination: Infrastructure/Translation); execution or loop-control helper (signs: response-id matching, timeout/deadline checks, exit handling, loop control, send/read/write/wait/stream/load/save/retry/emit behavior, or other live boundary coordination remains present; architectural note: those mechanics stay in the gateway even when adjacent technical decisions are extracted; destination: Infrastructure/Gateways). Explicit decomposition guidance: if the logic is still mixed extraction plus evaluation, decompose it before moving it; leave raw parsing and translation in Infrastructure/Translation, leave execution and loop control in Infrastructure/Gateways, and move only the pure decision-shaped technical logic to Infrastructure/Evaluators."
}

private func gatewayInlineTypedBoundaryCompatibilityEvaluationMessage(for gatewayTypeName: String) -> String {
    "'\(gatewayTypeName)' still performs typed boundary compatibility or allowance evaluation inline inside a real execution gateway. This rule is intentionally narrow: it only targets gateway-local helpers that compare already-shaped typed technical inputs such as translated requirements, capabilities, posture, request, or state carriers, then map incompatibility or disallowed outcomes into Infrastructure error construction, throwing, or typed failure-result handling in the same helper. Likely categories: boundary-specific compatibility classifier or resolver (signs: translated requirements, capabilities, posture, or request facts are compared through membership checks or repeated typed fact checks to decide compatible versus incompatible or allowed versus disallowed, and the extracted surface would naturally read as a Classifier or Resolver with a stable typed result; architectural note: that technical evaluation belongs in Infrastructure/Evaluators once translation is complete; destination: Infrastructure/Evaluators); gateway-local failure mapping or orchestration (signs: Infrastructure error construction, failure event emission, throwing, or other runtime failure handling occurs after the classifier or resolver result is known; architectural note: the gateway may keep failure mapping and orchestration after calling a classifier or resolver; destination: Infrastructure/Gateways); mixed extraction plus evaluation helper (signs: the helper still parses, extracts, normalizes, or walks raw payload data before the technical comparison happens; architectural note: decompose extraction before moving the decision logic; destination: raw parsing and translation in Infrastructure/Translation, then only the decision core in Infrastructure/Evaluators). Explicit decomposition guidance: isolate the pure typed compatibility or allowance decision into a concrete classifier or resolver under Infrastructure/Evaluators, let that type own any stable typed failure/result surface and details needed to describe the incompatibility, keep Infrastructure error construction, failure event emission, throwing, and orchestration in Infrastructure/Gateways after the classifier/resolver result is returned, and if raw extraction is still mixed in, decompose translation to Infrastructure/Translation before moving the decision logic."
}

private func portAdapterInlineObviousBoundaryDecisionLogicMessage(for portAdapterTypeName: String) -> String {
    "'\(portAdapterTypeName)' keeps obvious typed technical decision logic inline inside Infrastructure/PortAdapters. This rule is intentionally narrow: it only targets non-public adapter-local helpers that take already-shaped technical inputs, return a typed technical decision, and do not perform raw parsing or concrete adapter execution. Likely categories: boundary-specific selector, classifier, or resolver (signs: typed technical inputs go in, a typed technical selection/classification/resolution comes out, and the helper body is mostly comparison or selection logic rather than adapter execution; architectural note: port adapters may consume evaluator results, but pure decision-shaped technical logic should live in Infrastructure/Evaluators once translation is complete; destination: Infrastructure/Evaluators); translation helper (signs: raw strings, dictionaries, payload fragments, or other pre-translation values still need parsing, extraction, normalization, or shaping before a decision is possible; architectural note: translation establishes typed technical meaning before evaluator logic begins; destination: Infrastructure/Translation); concrete adapter execution or final-boundary rendering helper (signs: the helper sends, writes, executes, renders, formats, interprets to the final boundary output, or otherwise performs the concrete adapter step rather than just deciding; architectural note: port adapters may keep final execution or final output interpretation, so only the pure decision core moves out; destination: Infrastructure/PortAdapters). Explicit decomposition guidance: if the logic is still mixed extraction plus evaluation, decompose it before moving it; leave raw parsing and translation in Infrastructure/Translation, leave concrete adapter execution or final-boundary rendering in Infrastructure/PortAdapters, and move only the pure decision-shaped technical logic to Infrastructure/Evaluators."
}

private func portAdapterInlineTypedBoundaryCompatibilityEvaluationMessage(for portAdapterTypeName: String) -> String {
    "'\(portAdapterTypeName)' still performs typed boundary compatibility or allowance evaluation inline inside Infrastructure/PortAdapters. This rule is intentionally narrow: it only targets non-public adapter-local helpers that compare already-shaped typed technical inputs such as translated requirements, capabilities, posture, request, or state carriers, then map incompatibility or disallowed outcomes into adapter-local rejection, throwing, Infrastructure error construction, or typed failure-result handling in the same helper. Likely categories: boundary-specific compatibility classifier or resolver (signs: translated requirements, capabilities, posture, or request facts are compared through membership checks or repeated typed fact checks to decide compatible versus incompatible or allowed versus disallowed, and the extracted surface would naturally read as a Classifier or Resolver with a stable typed result; architectural note: that technical evaluation belongs in Infrastructure/Evaluators once translation is complete; destination: Infrastructure/Evaluators); concrete adapter rejection or failure mapping (signs: after compatibility is known, the adapter throws, constructs an Infrastructure error, returns a typed rejection/failure result, or otherwise maps the evaluator outcome into concrete adapter behavior; architectural note: port adapters may keep rejection or failure mapping after calling a classifier or resolver; destination: Infrastructure/PortAdapters); legitimate final-boundary output choice helper (signs: the helper only chooses among final string, data, formatting, or interpretation paths for boundary output and does not perform real support, allowance, or compatibility evaluation plus failure mapping; architectural note: simple render or format branching stays in port adapters and is intentionally excluded from this rule; destination: Infrastructure/PortAdapters); mixed extraction plus evaluation helper (signs: the helper still parses, extracts, normalizes, or walks raw payload data before the technical comparison happens; architectural note: decompose extraction before moving the decision logic; destination: raw parsing and translation in Infrastructure/Translation, then only the decision core in Infrastructure/Evaluators). Explicit decomposition guidance: isolate the pure typed compatibility or allowance decision into a concrete classifier or resolver under Infrastructure/Evaluators, let that type own any stable typed failure/result surface and details needed to describe incompatibility, keep adapter-local rejection, Infrastructure error construction, throwing, final-boundary formatting, and final adapter behavior in Infrastructure/PortAdapters after the classifier/resolver result is returned, and if raw extraction is still mixed in, decompose translation to Infrastructure/Translation before moving the decision logic."
}

private func portAdapterInlineNormalizationPreparationMessage(for portAdapterTypeName: String) -> String {
    "'\(portAdapterTypeName)' keeps inline normalization/preparation helper logic inside Infrastructure/PortAdapters. This rule is intentionally under-inclusive: it only targets non-public adapter-local helpers that take raw or pre-translation technical input, return a normalized technical value or small passive intermediary shape, and show a real normalization/preparation role without performing the final adapter step. Likely categories: normalized intermediary technical shaping (signs: raw or pre-translation technical input such as primitives, primitive collections, config fragments, path/input/request fragments, or other unnormalized technical carriers is trimmed, defaulted, canonicalized, standardized, coerced, expanded, sanitized, or otherwise prepared into a stable technical value or small passive intermediary shape; architectural note: once normalization/preparation becomes a distinct shaping concern, it belongs in Translation rather than inline port-adapter code; destination: Infrastructure/Translation/Models); final passive boundary-facing shaping (signs: the helper's normalization/preparation work is actually producing a passive final provider or transport request, response, envelope, body, params, payload, URLRequest, or HTTPURLResponse-facing shape; architectural note: when normalization/preparation owns final passive boundary-facing output, route that passive shape to DTO-side translation instead of hiding it in the adapter; destination: Infrastructure/Translation/DTOs); execution, render, or orchestration helper (signs: the helper performs concrete write/send/dispatch behavior or legitimate final render/format/interpret/output work for the boundary; architectural note: concrete adapter execution and valid final boundary output ownership stay in Infrastructure/PortAdapters and are intentionally excluded from this rule; destination: Infrastructure/PortAdapters). Explicit decomposition guidance: if normalization/preparation is mixed with execution or final rendering, split it first; keep normalization/preparation in Infrastructure/Translation/Models by default, use Infrastructure/Translation/DTOs only when the extracted passive output is clearly final boundary-facing, and keep execution, final rendering, interpretation, and orchestration in Infrastructure/PortAdapters."
}

private enum InlineTypedInteractionDispatchPassiveShapeDestination {
    case models
    case dtos
}

private func gatewayInlineTypedInteractionDispatchMessage(
    for gatewayTypeName: String,
    passiveShapeDestinations: Set<InlineTypedInteractionDispatchPassiveShapeDestination>
) -> String {
    let passiveShapeCategories = passiveShapeDestinations.compactMap { destination -> String? in
        switch destination {
        case .models:
            return "passive intermediary branch shape building (signs: branch bodies instantiate or assemble passive intermediary carriers such as model, payload, request-definition, context, command, or similar non-final translation shapes before execution; architectural note: passive intermediary branch-specific shapes belong in translation models, not inline in the dispatch helper; destination: Infrastructure/Translation/Models)"
        case .dtos:
            return "passive final branch request or response shaping (signs: branch bodies instantiate or assemble passive final provider or transport request, response, envelope, body, params, payload, URLRequest, or HTTPURLResponse shapes before execution; architectural note: passive final boundary-facing shapes belong on the DTO side, not inline in the dispatch helper; destination: Infrastructure/Translation/DTOs)"
        }
    }.sorted()
    let passiveShapeCategoryClause = passiveShapeCategories.isEmpty
        ? ""
        : "; " + passiveShapeCategories.joined(separator: "; ")
    let passiveShapeGuidance = passiveShapeDestinations
        .sorted { lhs, rhs in
            switch (lhs, rhs) {
            case (.models, .dtos):
                return true
            case (.dtos, .models):
                return false
            default:
                return true
            }
        }
        .map { destination -> String in
            switch destination {
            case .models:
                return "move passive intermediary branch-specific shapes to Infrastructure/Translation/Models"
            case .dtos:
                return "move passive final branch-specific request or response shapes to Infrastructure/Translation/DTOs"
            }
        }
        .joined(separator: ", ")
    let passiveShapeGuidanceClause = passiveShapeGuidance.isEmpty ? "" : ", \(passiveShapeGuidance)"

    return "'\(gatewayTypeName)' keeps typed interaction dispatch inline inside a real execution gateway helper. This rule is intentionally strict: it only targets gateway-local private helpers that take already-shaped typed technical input, fan out across two or more dispatch arms, perform branch-local boundary work in multiple distinct arms, and do not begin from raw parsing or loop/control mechanics. Likely categories: typed interaction-kind selector or classifier (signs: already-shaped typed technical input is inspected to choose among two or more interaction paths before branch execution begins; architectural note: typed interaction-path selection belongs in Infrastructure/Evaluators first once translation is complete; destination: Infrastructure/Evaluators); gateway branch execution or orchestration (signs: after a typed interaction path is known, the remaining work sends, writes, performs, dispatches, emits, starts, continues, cancels, streams, or otherwise executes branch-specific boundary behavior; architectural note: gateways may execute the selected path, but should consume a selected interaction result rather than deciding the path inline; destination: Infrastructure/Gateways)\(passiveShapeCategoryClause). Explicit decomposition guidance: first extract typed interaction-kind selection or classification to a concrete selector, classifier, or resolver in Infrastructure/Evaluators. Then keep only boundary execution or orchestration in Infrastructure/Gateways\(passiveShapeGuidanceClause). If raw extraction is still mixed in, decompose translation before applying this split."
}

private func portAdapterInlineTypedInteractionDispatchMessage(
    for portAdapterTypeName: String,
    passiveShapeDestinations: Set<InlineTypedInteractionDispatchPassiveShapeDestination>
) -> String {
    let passiveShapeCategories = passiveShapeDestinations.compactMap { destination -> String? in
        switch destination {
        case .models:
            return "passive intermediary branch shape building (signs: branch bodies instantiate or assemble passive intermediary carriers such as model, payload, request-definition, context, command, or similar non-final translation shapes before execution; architectural note: passive intermediary branch-specific shapes belong in translation models, not inline in the adapter dispatch helper; destination: Infrastructure/Translation/Models)"
        case .dtos:
            return "passive final branch request or response shaping (signs: branch bodies instantiate or assemble passive final provider or transport request, response, envelope, body, params, payload, URLRequest, or HTTPURLResponse shapes before execution; architectural note: passive final boundary-facing shapes belong on the DTO side, not inline in the adapter dispatch helper; destination: Infrastructure/Translation/DTOs)"
        }
    }.sorted()
    let passiveShapeCategoryClause = passiveShapeCategories.isEmpty
        ? ""
        : "; " + passiveShapeCategories.joined(separator: "; ")
    let passiveShapeGuidance = passiveShapeDestinations
        .sorted { lhs, rhs in
            switch (lhs, rhs) {
            case (.models, .dtos):
                return true
            case (.dtos, .models):
                return false
            default:
                return true
            }
        }
        .map { destination -> String in
            switch destination {
            case .models:
                return "move passive intermediary branch-specific shapes to Infrastructure/Translation/Models"
            case .dtos:
                return "move passive final branch-specific request or response shapes to Infrastructure/Translation/DTOs"
            }
        }
        .joined(separator: ", ")
    let passiveShapeGuidanceClause = passiveShapeGuidance.isEmpty ? "" : ", \(passiveShapeGuidance)"

    return "'\(portAdapterTypeName)' keeps typed interaction dispatch inline inside Infrastructure/PortAdapters. This rule is intentionally strict: it only targets adapter-local private helpers that take already-shaped typed technical input, fan out across two or more dispatch arms, perform branch-local boundary work in multiple distinct arms, and are not merely legitimate final render/format/interpret-to-boundary helpers. Likely categories: typed interaction-kind selector or classifier (signs: already-shaped typed technical input is inspected to choose among two or more interaction paths before branch execution begins; architectural note: typed interaction-path selection belongs in Infrastructure/Evaluators first once translation is complete; destination: Infrastructure/Evaluators); concrete adapter branch execution or orchestration (signs: after a typed interaction path is known, the remaining work writes, emits, performs, dispatches, or otherwise executes branch-specific boundary behavior; architectural note: port adapters may execute the selected path, but should consume a selected interaction result rather than deciding the path inline; destination: Infrastructure/PortAdapters); legitimate final-boundary render/format/interpret helper (signs: the helper's branch differences are just final string/data/output formatting or interpretation for the boundary without separate typed interaction selection plus branch-local execution; architectural note: final output rendering stays in port adapters and is intentionally excluded from this rule; destination: Infrastructure/PortAdapters)\(passiveShapeCategoryClause). Explicit decomposition guidance: first extract typed interaction-kind selection or classification to a concrete selector, classifier, or resolver in Infrastructure/Evaluators. Then keep only final-boundary rendering or concrete adapter execution in Infrastructure/PortAdapters\(passiveShapeGuidanceClause). If raw extraction is still mixed in, decompose translation before applying this split."
}

private func gatewayInlineRequestDefinitionRegressionMessage(for gatewayTypeName: String) -> String {
    "'\(gatewayTypeName)' still keeps inline request-definition shaping in the gateway even though extracted translation shapes already exist. Likely categories: extracted intermediary request-definition regression (signs: inline query text, operation-name assembly, variables assembly, launch/startup inputs, or equivalent intermediary request-definition ingredients remain in the gateway after model extraction; architectural note: once intermediary shaping models exist, the gateway should consume them rather than rebuilding those ingredients inline; destination: Infrastructure/Translation/Models); extracted final provider or transport request or response regression (signs: inline URLRequest, request body, headers, params, envelope, or equivalent final boundary-facing shapes remain in the gateway after DTO-side extraction exists or should exist; architectural note: gateways should consume DTO-side final shapes or adjacent DTO-side builders rather than hiding them in execution code; destination: Infrastructure/Translation/DTOs); mixed regression (signs: the gateway still assembles both intermediary request-definition ingredients and final provider or transport request or response shapes inline; architectural note: keep intermediary shaping, DTO-side final shaping, and execution distinct; destination: split between Infrastructure/Translation/Models and Infrastructure/Translation/DTOs). Explicit decomposition guidance: keep boundary-configuration shaping in Infrastructure/Translation/Models, keep intermediary request-definition shaping in dedicated model types, keep passive final request or response carriers and any adjacent DTO-side translator or builder in Infrastructure/Translation/DTOs, and keep only request execution, pagination, HTTP/status handling, transport orchestration, and response decoding in the gateway."
}

private enum NestedBoundaryShapingHelperClassification {
    case intermediary
    case finalBoundary
    case mixed
}

private func nestedBoundaryShapingHelperMessage(
    nestedTypeName: String,
    gatewayTypeName: String,
    classification: NestedBoundaryShapingHelperClassification
) -> String {
    switch classification {
    case .intermediary:
        return "Gateway '\(gatewayTypeName)' hides intermediary or normalized shaping inside nested helper '\(nestedTypeName)'. Likely categories: intermediary or normalized shaping helper (signs: config normalization, fallback/defaulting, coercion, request-definition assembly, startup or launch shaping, context shaping, or other adapter-owned shaping before a final provider or transport request or response shape exists; architectural note: nested helper existence alone is not the problem, but intermediary shaping ownership belongs outside the gateway; destination: Infrastructure/Translation/Models); final provider or transport request or response shaping helper (signs: not present here, but if the nested helper later starts emitting final request or response carriers it belongs on the DTO side instead; architectural note: final boundary-facing shapes and adjacent translators live in DTO files, not in gateway-local helpers; destination: Infrastructure/Translation/DTOs); execution helper (signs: send, fetch, stream, wait, paginate, or other transport lifecycle work; architectural note: execution can remain in the gateway once shaping is extracted; destination: Infrastructure/Gateways). Explicit decomposition guidance: move normalized config and intermediary request-definition shaping out to Infrastructure/Translation/Models, keep any final provider or transport request or response carrier work out of the gateway entirely, and leave only execution or orchestration helpers in the gateway."
    case .finalBoundary:
        return "Gateway '\(gatewayTypeName)' hides final provider or transport request or response shaping inside nested helper '\(nestedTypeName)'. Likely categories: passive DTO carrier (signs: request, response, envelope, body, params, data, payload, URLRequest, or HTTPURLResponse shapes representing what crosses the boundary; architectural note: final boundary-facing carriers belong on the DTO side of Infrastructure translation; destination: Infrastructure/Translation/DTOs); adjacent DTO-side directional translator or builder (signs: assembles the final outbound request or shapes the inbound response carrier from intermediary inputs without executing it; architectural note: DTO-side translation may live adjacent to passive DTO carriers, but not as a gateway-local hidden helper; destination: Infrastructure/Translation/DTOs); execution helper (signs: send, fetch, stream, paginate, or transport lifecycle work; architectural note: execution remains in the gateway only after final request or response shaping is extracted; destination: Infrastructure/Gateways). Explicit decomposition guidance: move passive final request or response carriers and any adjacent DTO-side translator or builder to Infrastructure/Translation/DTOs, keep normalized or intermediary shaping in Infrastructure/Translation/Models, and leave only execution or orchestration helpers in the gateway."
    case .mixed:
        return "Gateway '\(gatewayTypeName)' hides both intermediary shaping and final provider or transport request or response shaping inside nested helper '\(nestedTypeName)'. Likely categories: intermediary or normalized shaping (signs: config normalization, request-definition assembly, startup or launch shaping, or other adapter-owned intermediary shaping before the final boundary-facing shape exists; architectural note: intermediary shaping belongs in Models; destination: Infrastructure/Translation/Models); final provider or transport request or response shaping (signs: URLRequest, request body, headers, params, envelope, response carrier, or other final boundary-facing shapes are assembled in the same helper; architectural note: final boundary-facing shapes and adjacent DTO-side translators belong in DTO files; destination: Infrastructure/Translation/DTOs); execution helper (signs: send, fetch, paginate, stream, wait, or transport lifecycle work remains around the helper; architectural note: execution stays in the gateway only after shaping is split out; destination: Infrastructure/Gateways). Explicit decomposition guidance: split normalized config and intermediary request-definition shaping into Infrastructure/Translation/Models, split passive final request or response carriers plus any adjacent DTO-side translator or builder into Infrastructure/Translation/DTOs, and keep only boundary execution or orchestration in the gateway."
    }
}

public struct InfrastructureTranslationDirectionalNamingPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.translation.directional_naming"
    private let allowedNames: Set<String> = [
        "toDomain",
        "fromDomain",
        "toContract",
        "fromContract",
        "toInfrastructureError",
        "fromInfrastructureError"
    ]

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureTranslationFile else {
            return []
        }

        return file.methodDeclarations.compactMap { declaration in
            guard isBoundaryCrossingTranslationMethod(
                declaration,
                file: file,
                context: context
            ) else {
                return nil
            }

            guard !allowedNames.contains(declaration.name) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Boundary-crossing translation methods in Infrastructure/Translation must use one of these exact names only: toDomain, fromDomain, toContract, fromContract, toInfrastructureError, or fromInfrastructureError. Rename '\(declaration.name)'.",
                coordinate: declaration.coordinate
            )
        }
    }
}

public struct InfrastructureErrorsShapePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.errors.shape"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureErrorFile else {
            return []
        }
        return structuredErrorDiagnostics(
            file: file,
            ruleID: Self.ruleID,
            rolePath: "Infrastructure/Errors",
            namingDescription: "<Boundary>InfrastructureError, <Provider>GatewayError, or another explicit adapter/provider error name ending in Error",
            namingValidator: { declaration in
                declaration.name.hasSuffix("InfrastructureError")
                    || declaration.name.hasSuffix("GatewayError")
                    || declaration.name.hasSuffix("Error")
            }
        )
    }
}

public struct InfrastructureErrorsPlacementPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.errors.placement"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructure else {
            return []
        }
        guard !file.classification.isInfrastructureErrorFile else {
            return []
        }

        return structuredErrorPlacementDiagnostics(
            file: file,
            ruleID: Self.ruleID,
            rolePath: "Infrastructure/Errors",
            namingValidator: { declaration in
                declaration.name.hasSuffix("InfrastructureError")
                    || declaration.name.hasSuffix("GatewayError")
                    || declaration.name.hasSuffix("Error")
            }
        )
    }
}

public struct InfrastructureForbiddenPresentationDependencyPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.forbidden_presentation_dependency"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructure else {
            return []
        }

        var diagnostics: [ArchitectureDiagnostic] = []
        var seenNames = Set<String>()

        for reference in file.typeReferences {
            guard seenNames.insert(reference.name).inserted else { continue }
            guard let declaration = context.uniqueDeclaration(named: reference.name) else { continue }
            guard declaration.layer == .presentation else { continue }

            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: "Infrastructure must not depend on presentation type '\(reference.name)' from \(declaration.repoRelativePath).",
                    coordinate: reference.coordinate
                )
            )
        }

        return diagnostics
    }
}

public struct InfrastructureCrossLayerProtocolConformancePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "infrastructure.cross_layer_protocol_conformance"
    private let adapterSuffixes = ["Repository", "Gateway", "PortAdapter"]

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isInfrastructureAdapterRole else {
            return []
        }

        return file.topLevelDeclarations.compactMap { declaration in
            guard isAdapterCandidate(declaration) else {
                return nil
            }
            guard !conformsToInwardProtocol(declaration, context: context) else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: "Infrastructure adapter '\(declaration.name)' should conform to a protocol from Application/Ports/Protocols or Domain/Protocols so the composition root can inject it across the layer boundary.",
                coordinate: declaration.coordinate
            )
        }
    }

    private func isAdapterCandidate(_ declaration: ArchitectureTopLevelDeclaration) -> Bool {
        switch declaration.kind {
        case .class, .struct, .actor:
            return adapterSuffixes.contains { declaration.name.hasSuffix($0) }
        case .protocol, .enum:
            return false
        }
    }

    private func conformsToInwardProtocol(
        _ declaration: ArchitectureTopLevelDeclaration,
        context: ProjectContext
    ) -> Bool {
        declaration.inheritedTypeNames.contains { inheritedTypeName in
            guard let inheritedDeclaration = context.uniqueDeclaration(named: inheritedTypeName) else {
                return false
            }
            guard inheritedDeclaration.kind == .protocol else {
                return false
            }
            return inheritedDeclaration.roleFolder == .applicationPortsProtocols
                || inheritedDeclaration.roleFolder == .domainProtocols
        }
    }
}

private func hasInwardTranslationSurface(
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let concreteTopLevelTypeNames = Set(
        file.topLevelDeclarations.compactMap { declaration -> String? in
            guard declaration.kind != .protocol else {
                return nil
            }

            return declaration.name
        }
    )

    return file.methodDeclarations.contains { declaration in
        concreteTopLevelTypeNames.contains(declaration.enclosingTypeName)
            && !declaration.isPrivateOrFileprivate
            && returnsInwardNormalizedType(declaration, context: context)
    }
}

private func hasParserModelTranslationSurface(
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let concreteTopLevelTypeNames = Set(
        file.topLevelDeclarations.compactMap { declaration -> String? in
            guard declaration.kind != .protocol else {
                return nil
            }

            return declaration.name
        }
    )
    let parserModelTypeNamesInFile = Set(
        file.topLevelDeclarations.compactMap { declaration -> String? in
            guard declaration.kind != .protocol,
                  isParserModelTranslationTypeName(declaration.name, file: file, context: context) else {
                return nil
            }

            return declaration.name
        }
    )

    guard !parserModelTypeNamesInFile.isEmpty else {
        return false
    }

    return file.methodDeclarations.contains { declaration in
        guard concreteTopLevelTypeNames.contains(declaration.enclosingTypeName),
              !declaration.isPrivateOrFileprivate,
              returnsParserModelTranslationType(declaration, file: file, context: context) else {
            return false
        }

        return acceptsRawSyntaxInput(declaration)
            || acceptsInwardProjectionInput(declaration, context: context)
    }
}

private func hasConfigurationNormalizationSurface(
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let concreteTopLevelTypeNames = Set(
        file.topLevelDeclarations.compactMap { declaration -> String? in
            guard declaration.kind != .protocol else {
                return nil
            }

            return declaration.name
        }
    )

    return file.methodDeclarations.contains { declaration in
        guard concreteTopLevelTypeNames.contains(declaration.enclosingTypeName),
              !declaration.isPrivateOrFileprivate else {
            return false
        }

        return hasConfigurationNormalizationResponsibility(
            in: [declaration],
            file: file,
            context: context
        )
    }
}

private func hasIntermediaryRequestDefinitionTranslationSurface(
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    guard !hasNonPrivateTransportOrExecutionSurface(in: file) else {
        return false
    }

    let concreteTopLevelTypeNames = Set(
        file.topLevelDeclarations.compactMap { declaration -> String? in
            guard declaration.kind != .protocol else {
                return nil
            }

            return declaration.name
        }
    )

    return file.methodDeclarations.contains { declaration in
        guard concreteTopLevelTypeNames.contains(declaration.enclosingTypeName),
              !declaration.isPrivateOrFileprivate,
              declaration.hasExplicitReturnType,
              !declaration.returnsVoidLike,
              returnsIntermediaryRequestDefinitionTranslationType(
                declaration,
                file: file,
                context: context
              ) else {
            return false
        }

        return acceptsRequestDefinitionTranslationInput(declaration, context: context)
    }
}

private func hasConfigurationNormalizationResponsibility(
    in methods: [ArchitectureMethodDeclaration],
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    methods.contains { declaration in
        let lowercasedName = declaration.name.lowercased()
        let referencesConfigurationInput = declaration.parameterTypeNames.contains { typeName in
            isConfigurationInputTypeName(typeName, context: context)
        }
        let returnsConfigurationCarrier = declaration.returnTypeNames.contains { typeName in
            isConfigurationTranslationCarrierTypeName(typeName, file: file, context: context)
        }

        guard referencesConfigurationInput || lowercasedName.contains("config") else {
            return false
        }

        return returnsConfigurationCarrier
            || (declaration.hasExplicitReturnType && !declaration.returnsVoidLike && lowercasedName.contains("normalize"))
            || lowercasedName == "fromcontract"
    }
}

private func hasIntermediaryRequestDefinitionShapingResponsibility(
    in methods: [ArchitectureMethodDeclaration],
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    methods.contains { declaration in
        let lowercasedName = declaration.name.lowercased()
        let returnsRequestDefinitionLikeType = returnsIntermediaryRequestDefinitionTranslationType(
            declaration,
            file: file,
            context: context
        )
        let acceptsNormalizedConfig = declaration.parameterTypeNames.contains { typeName in
            isConfigurationTranslationCarrierTypeName(typeName, file: file, context: context)
        }

        guard returnsRequestDefinitionLikeType || lowercasedName.contains("requestdefinition") else {
            return false
        }

        return acceptsNormalizedConfig
            || hasGatewayRequestDefinitionIngredientEvidence(declaration, context: context)
            || lowercasedName.contains("query")
            || lowercasedName.contains("request")
    }
}

private func returnsIntermediaryRequestDefinitionTranslationType(
    _ declaration: ArchitectureMethodDeclaration,
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    declaration.returnTypeNames.contains { typeName in
        if file.topLevelDeclarations.contains(where: {
            $0.kind != .protocol && $0.name == typeName && isLikelyIntermediaryRequestDefinitionTranslationTypeName(typeName)
        }) {
            return true
        }

        guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
            return false
        }

        return indexedDeclaration.roleFolder == .infrastructureTranslationModels
            && isLikelyIntermediaryRequestDefinitionTranslationTypeName(typeName)
    }
}

private func returnsInwardNormalizedType(
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

        return indexedDeclaration.layer == .domain
            || isApplicationContractDeclaration(indexedDeclaration)
            || isInfrastructureErrorDeclaration(indexedDeclaration)
    }
}

private func returnsRequestDefinitionTranslationType(
    _ declaration: ArchitectureMethodDeclaration,
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    declaration.returnTypeNames.contains { typeName in
        if file.topLevelDeclarations.contains(where: {
            $0.kind != .protocol && $0.name == typeName && isLikelyBoundaryDefinitionTranslationTypeName(typeName)
        }) {
            return true
        }

        guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
            return false
        }

        if indexedDeclaration.roleFolder == .infrastructureTranslationDTOs {
            return true
        }

        return indexedDeclaration.roleFolder == .infrastructureTranslationModels
            && isLikelyBoundaryDefinitionTranslationTypeName(typeName)
    }
}

private func acceptsInwardNormalizedType(
    _ declaration: ArchitectureMethodDeclaration,
    context: ProjectContext
) -> Bool {
    declaration.parameterTypeNames.contains { typeName in
        guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
            return false
        }

        return indexedDeclaration.layer == .domain
            || isApplicationContractDeclaration(indexedDeclaration)
            || isInfrastructureErrorDeclaration(indexedDeclaration)
    }
}

private func acceptsRequestDefinitionTranslationInput(
    _ declaration: ArchitectureMethodDeclaration,
    context: ProjectContext
) -> Bool {
    let stringCount = declaration.parameterTypeNames.filter { $0 == "String" }.count
    let hasModelOrContractInput = declaration.parameterTypeNames.contains { typeName in
        guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
            return false
        }

        return indexedDeclaration.roleFolder == .infrastructureTranslationModels
            || indexedDeclaration.roleFolder == .infrastructureTranslationDTOs
            || isApplicationContractDeclaration(indexedDeclaration)
    }

    return stringCount >= 2 || (stringCount >= 1 && hasModelOrContractInput)
}

private func isBoundaryCrossingTranslationMethod(
    _ declaration: ArchitectureMethodDeclaration,
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let translationTopLevelTypeNames = Set(
        file.topLevelDeclarations.compactMap { declaration -> String? in
            guard declaration.kind != .protocol else {
                return nil
            }

            return declaration.name
        }
    )

    guard translationTopLevelTypeNames.contains(declaration.enclosingTypeName) else {
        return false
    }

    guard declaration.enclosingTypeName.hasSuffix("Model")
        || declaration.enclosingTypeName.hasSuffix("DTO") else {
        return false
    }

    return returnsInwardNormalizedType(declaration, context: context)
        || acceptsInwardNormalizedType(declaration, context: context)
}

private func isInwardTranslationSourceDeclaration(_ declaration: IndexedDeclaration) -> Bool {
    guard declaration.layer == .infrastructure else {
        return false
    }

    switch declaration.roleFolder {
    case .infrastructureTranslationModels:
        return true
    case .infrastructureTranslationDTOs:
        return declaration.name.hasSuffix("ResponseDTO")
    default:
        return false
    }
}

private func isInwardTranslationSourceTypeName(
    _ typeName: String,
    in file: ArchitectureFile,
    enclosingTypeName: String,
    context: ProjectContext
) -> Bool {
    if let nestedDeclaration = file.nestedNominalDeclarations.first(where: { declaration in
        declaration.enclosingTypeName == enclosingTypeName
            && declaration.name == typeName
            && declaration.kind != .protocol
    }) {
        return isLikelyNestedIntermediaryShape(nestedDeclaration)
    }

    guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
        return false
    }

    return isInwardTranslationSourceDeclaration(indexedDeclaration)
}

private func hasGatewayRequestDefinitionIngredientEvidence(
    _ declaration: ArchitectureMethodDeclaration,
    context: ProjectContext
) -> Bool {
    let stringCount = declaration.parameterTypeNames.filter { $0 == "String" }.count
    let hasPayloadCarrier = declaration.parameterTypeNames.contains { typeName in
        guard typeName != "URLRequest",
              let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
            return false
        }

        return indexedDeclaration.roleFolder == .infrastructureTranslationDTOs
            || indexedDeclaration.roleFolder == .infrastructureTranslationModels
    }

    return stringCount >= 2 || (stringCount >= 1 && hasPayloadCarrier)
}

private func gatewayUsesExtractedRequestShapingModel(
    in file: ArchitectureFile,
    gatewayTypeName: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> Bool {
    let hasMethodSignatureReference = methods.contains { declaration in
        declaration.parameterTypeNames.contains { typeName in
            isExtractedRequestShapingTranslationModelTypeName(typeName, context: context)
        } || declaration.returnTypeNames.contains { typeName in
            isExtractedRequestShapingTranslationModelTypeName(typeName, context: context)
        }
    }

    if hasMethodSignatureReference {
        return true
    }

    let topLevelTypeNames = Set(
        file.topLevelDeclarations.compactMap { declaration -> String? in
            guard declaration.kind != .protocol else {
                return nil
            }

            return declaration.name
        }
    )
    let gatewayMemberTypeNames = Set(
        file.storedMemberDeclarations
            .filter { $0.enclosingTypeName == gatewayTypeName }
            .flatMap(\.typeNames)
    )

    if gatewayMemberTypeNames.contains(where: { typeName in
        isExtractedRequestShapingTranslationModelTypeName(typeName, context: context)
    }) {
        return true
    }

    return file.typeReferences.contains { reference in
        guard topLevelTypeNames.contains(gatewayTypeName) else {
            return false
        }

        return isExtractedRequestShapingTranslationModelTypeName(reference.name, context: context)
    }
}

private func hasGatewayRoleFitMisclassificationEvidence(
    in file: ArchitectureFile,
    gatewayTypeName _: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> Bool {
    methods.contains { declaration in
        isLikelyGatewayRoleFitPreparationMethod(
            declaration,
            file: file,
            context: context
        )
    } || hasConfigurationNormalizationResponsibility(
        in: methods,
        file: file,
        context: context
    ) || hasRequestDefinitionShapingResponsibility(
        in: methods,
        file: file,
        context: context
    )
}

private func firstGatewayRoleFitCoordinate(
    in file: ArchitectureFile,
    gatewayTypeName _: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> SourceCoordinate? {
    methods.first(where: { declaration in
        isLikelyGatewayRoleFitPreparationMethod(
            declaration,
            file: file,
            context: context
        )
    })?.coordinate
}

private func isLikelyGatewayRoleFitPreparationMethod(
    _ declaration: ArchitectureMethodDeclaration,
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let lowercasedName = declaration.name.lowercased()
    guard declaration.hasExplicitReturnType,
          !declaration.returnsVoidLike,
          isLikelyGatewayBoundaryPreparationMethodName(lowercasedName),
          returnsPreparedBoundaryShape(
            declaration,
            file: file,
            context: context
          ) else {
        return false
    }

    return acceptsRequestDefinitionTranslationInput(declaration, context: context)
        || acceptsInwardProjectionInput(declaration, context: context)
        || hasConfigurationNormalizationResponsibility(
            in: [declaration],
            file: file,
            context: context
        )
}

private func hasInlineGatewayBoundaryConfigurationShapingEvidence(
    in file: ArchitectureFile,
    gatewayTypeName: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> Bool {
    let configurationMethods = methods.filter { declaration in
        isLikelyInlineGatewayBoundaryConfigurationShapingMethod(
            declaration,
            file: file,
            context: context
        )
    }

    guard !configurationMethods.isEmpty else {
        return false
    }

    let strongConfigurationMethods = configurationMethods.filter { declaration in
        isStrongGatewayBoundaryConfigurationShapingMethod(
            declaration,
            file: file,
            context: context
        )
    }

    let hasDefinitionFlow = hasInlineGatewayBoundaryDefinitionShapingEvidence(
        in: file,
        gatewayTypeName: gatewayTypeName,
        methods: methods,
        context: context
    )
    let hasConfigurationMembers = hasGatewayBoundaryConfigurationMemberEvidence(
        in: file,
        gatewayTypeName: gatewayTypeName
    )

    return !strongConfigurationMethods.isEmpty
        && (hasDefinitionFlow || hasConfigurationMembers || configurationMethods.count > 1)
}

private func firstInlineGatewayBoundaryConfigurationShapingCoordinate(
    in file: ArchitectureFile,
    gatewayTypeName: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> SourceCoordinate? {
    if let method = methods.first(where: { declaration in
        isLikelyInlineGatewayBoundaryConfigurationShapingMethod(
            declaration,
            file: file,
            context: context
        )
    }) {
        return method.coordinate
    }

    if let computedProperty = file.computedPropertyDeclarations.first(where: { declaration in
        declaration.enclosingTypeName == gatewayTypeName
            && isLikelyGatewayBoundaryConfigurationMemberName(declaration.name)
    }) {
        return computedProperty.coordinate
    }

    return file.storedMemberDeclarations.first(where: { declaration in
        declaration.enclosingTypeName == gatewayTypeName
            && isLikelyGatewayBoundaryConfigurationMemberName(declaration.name)
    })?.coordinate
}

private func hasInlineGatewayBoundaryDefinitionShapingEvidence(
    in file: ArchitectureFile,
    gatewayTypeName: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> Bool {
    hasGatewayOperationLikeBoundaryDefinitionShapingEvidence(
        in: file,
        gatewayTypeName: gatewayTypeName,
        methods: methods,
        context: context
    ) || hasGatewayFactoryStyleBoundaryDefinitionShapingEvidence(
        in: file,
        gatewayTypeName: gatewayTypeName,
        methods: methods,
        context: context
    )
}

private func firstInlineGatewayBoundaryDefinitionShapingCoordinate(
    in file: ArchitectureFile,
    gatewayTypeName: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> SourceCoordinate? {
    if let method = methods.first(where: { declaration in
        isLikelyInlineGatewayBoundaryDefinitionShapingMethod(
            declaration,
            context: context
        )
    }) {
        return method.coordinate
    }

    if let computedProperty = file.computedPropertyDeclarations.first(where: { declaration in
        declaration.enclosingTypeName == gatewayTypeName
            && isLikelyGatewayBoundaryDefinitionMemberName(declaration.name)
    }) {
        return computedProperty.coordinate
    }

    return file.storedMemberDeclarations.first(where: { declaration in
        declaration.enclosingTypeName == gatewayTypeName
            && isLikelyGatewayBoundaryDefinitionMemberName(declaration.name)
    })?.coordinate
}

private func hasInlineGatewayOutboundRequestTranslationEvidence(
    in file: ArchitectureFile,
    gatewayTypeName: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> Bool {
    firstInlineGatewayOutboundRequestTranslationCoordinate(
        in: file,
        gatewayTypeName: gatewayTypeName,
        methods: methods,
        context: context
    ) != nil
}

private func firstInlineGatewayOutboundRequestTranslationCoordinate(
    in file: ArchitectureFile,
    gatewayTypeName: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> SourceCoordinate? {
    let helperMethodsByName = methods.reduce(into: [String: ArchitectureMethodDeclaration]()) { partialResult, method in
        partialResult[method.name] = partialResult[method.name] ?? method
    }

    for method in methods {
        let methodOperationalUses = gatewayOperationalUses(
            in: file,
            enclosingTypeName: gatewayTypeName,
            methodName: method.name
        )
        guard hasImmediateGatewayTransportHandoff(
            in: methodOperationalUses,
            gatewayTypeName: gatewayTypeName,
            helperMethodsByName: helperMethodsByName
        ) else {
            continue
        }

        if let coordinate = firstDirectOutboundGatewayTranslationCoordinate(
            in: file,
            gatewayTypeName: gatewayTypeName,
            methodName: method.name,
            context: context
        ) {
            return coordinate
        }

        let directHelperNames = Set(methodOperationalUses.compactMap { occurrence -> String? in
            guard let helper = helperMethodsByName[occurrence.baseName],
                  helper.enclosingTypeName == gatewayTypeName,
                  helper.isPrivateOrFileprivate,
                  helper.hasExplicitReturnType,
                  !helper.returnsVoidLike,
                  returnsGatewayOutboundTranslationCarrier(helper, context: context),
                  firstDirectOutboundGatewayTranslationCoordinate(
                    in: file,
                    gatewayTypeName: gatewayTypeName,
                    methodName: helper.name,
                    context: context
                  ) != nil else {
                return nil
            }

            return helper.name
        })

        if let helperCoordinate = directHelperNames.compactMap({ helperName in
            firstDirectOutboundGatewayTranslationCoordinate(
                in: file,
                gatewayTypeName: gatewayTypeName,
                methodName: helperName,
                context: context
            )
        }).first {
            return helperCoordinate
        }
    }

    return nil
}

private func firstDirectOutboundGatewayTranslationCoordinate(
    in file: ArchitectureFile,
    gatewayTypeName: String,
    methodName: String,
    context: ProjectContext
) -> SourceCoordinate? {
    gatewayOperationalUses(
        in: file,
        enclosingTypeName: gatewayTypeName,
        methodName: methodName
    ).first(where: { occurrence in
        isDirectGatewayOutboundTranslationConstruction(
            occurrence,
            context: context
        )
    })?.coordinate
}

private func gatewayOperationalUses(
    in file: ArchitectureFile,
    enclosingTypeName: String,
    methodName: String
) -> [ArchitectureOperationalUseOccurrence] {
    file.operationalUseOccurrences.filter { occurrence in
        occurrence.enclosingTypeName == enclosingTypeName
            && occurrence.enclosingMethodName == methodName
    }
}

private func hasImmediateGatewayTransportHandoff(
    in operationalUses: [ArchitectureOperationalUseOccurrence],
    gatewayTypeName: String,
    helperMethodsByName: [String: ArchitectureMethodDeclaration]
) -> Bool {
    operationalUses.contains { occurrence in
        if let helper = helperMethodsByName[occurrence.baseName],
           helper.enclosingTypeName == gatewayTypeName {
            return isLikelyImmediateTransportExecutionCallName(helper.name.lowercased())
        }

        return isLikelyImmediateTransportExecutionCallName(occurrence.baseName.lowercased())
            || isLikelyImmediateTransportExecutionCallName(occurrence.memberName.lowercased())
    }
}

private func isDirectGatewayOutboundTranslationConstruction(
    _ occurrence: ArchitectureOperationalUseOccurrence,
    context: ProjectContext
) -> Bool {
    guard occurrence.memberName == "callAsFunction" else {
        return false
    }

    return isGatewayOutboundTranslationCarrierTypeName(
        occurrence.baseName,
        context: context
    )
}

private func returnsGatewayOutboundTranslationCarrier(
    _ declaration: ArchitectureMethodDeclaration,
    context: ProjectContext
) -> Bool {
    declaration.returnTypeNames.contains { typeName in
        isGatewayOutboundTranslationCarrierTypeName(typeName, context: context)
    }
}

private func isGatewayOutboundTranslationCarrierTypeName(
    _ typeName: String,
    context: ProjectContext
) -> Bool {
    if gatewayTransportCarrierTypeNames.contains(typeName) {
        return true
    }

    guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
        return false
    }

    return indexedDeclaration.roleFolder == .infrastructureTranslationDTOs
}

private func firstInlineGatewayObviousBoundaryDecisionLogicMethod(
    in file: ArchitectureFile,
    gatewayTypeName: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> ArchitectureMethodDeclaration? {
    methods.first { declaration in
        guard declaration.enclosingTypeName == gatewayTypeName,
              !declaration.isPublicOrOpen else {
            return false
        }

        return isObviousTechnicalDecisionMethod(
            declaration,
            in: file,
            context: context
        ) && !isExcludedGatewayDecisionControlMethod(declaration)
    }
}

private func firstInlineGatewayNormalizationPreparationMethod(
    in file: ArchitectureFile,
    gatewayTypeName: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> ArchitectureMethodDeclaration? {
    methods.first { declaration in
        guard declaration.enclosingTypeName == gatewayTypeName else {
            return false
        }

        return isInlineNormalizationPreparationMethod(
            declaration,
            in: file,
            context: context,
            owner: .gateway
        )
    }
}

private func firstInlineGatewayTypedBoundaryCompatibilityEvaluationMethod(
    in file: ArchitectureFile,
    gatewayTypeName: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> ArchitectureMethodDeclaration? {
    methods.first { declaration in
        guard declaration.enclosingTypeName == gatewayTypeName,
              declaration.isPrivateOrFileprivate,
              !isExcludedGatewayDecisionControlMethod(declaration),
              !isObviousTechnicalDecisionMethod(
                declaration,
                in: file,
                context: context
              ) else {
            return false
        }

        return isTypedBoundaryCompatibilityEvaluationMethod(
            declaration,
            in: file,
            context: context
        )
    }
}

private func firstInlineGatewayTypedInteractionDispatchMethod(
    in file: ArchitectureFile,
    gatewayTypeName: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> ArchitectureMethodDeclaration? {
    methods.first { declaration in
        guard declaration.enclosingTypeName == gatewayTypeName,
              declaration.isPrivateOrFileprivate,
              !isExcludedGatewayDecisionControlMethod(declaration),
              !isObviousTechnicalDecisionMethod(
                declaration,
                in: file,
                context: context
              ),
              !isTypedBoundaryCompatibilityEvaluationMethod(
                declaration,
                in: file,
                context: context
              ),
              hasTypedInteractionDispatchInput(
                declaration,
                file: file,
                context: context
              ),
              !hasGatewayInteractionDispatchControlPattern(
                declaration,
                in: file
              ) else {
            return false
        }

        return hasInlineTypedInteractionDispatchStructure(
            declaration,
            in: file
        )
    }
}

private func firstInlinePortAdapterNormalizationPreparationMethod(
    in file: ArchitectureFile,
    portAdapterTypeName: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> ArchitectureMethodDeclaration? {
    methods.first { declaration in
        guard declaration.enclosingTypeName == portAdapterTypeName else {
            return false
        }

        return isInlineNormalizationPreparationMethod(
            declaration,
            in: file,
            context: context,
            owner: .portAdapter
        )
    }
}

private func firstInlinePortAdapterObviousBoundaryDecisionLogicMethod(
    in file: ArchitectureFile,
    portAdapterTypeName: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> ArchitectureMethodDeclaration? {
    methods.first { declaration in
        guard declaration.enclosingTypeName == portAdapterTypeName,
              declaration.isPrivateOrFileprivate else {
            return false
        }

        return isObviousTechnicalDecisionMethod(
            declaration,
            in: file,
            context: context
        ) && !hasPortAdapterLegitimateFinalRenderOutputPattern(
            declaration,
            in: file
        )
    }
}

private func firstInlinePortAdapterTypedBoundaryCompatibilityEvaluationMethod(
    in file: ArchitectureFile,
    portAdapterTypeName: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> ArchitectureMethodDeclaration? {
    methods.first { declaration in
        guard declaration.enclosingTypeName == portAdapterTypeName,
              declaration.isPrivateOrFileprivate,
              !isExcludedGatewayDecisionControlMethod(declaration),
              !isObviousTechnicalDecisionMethod(
                declaration,
                in: file,
                context: context
              ),
              !hasPortAdapterLegitimateFinalRenderOutputPattern(
                declaration,
                in: file
              ) else {
            return false
        }

        return isTypedBoundaryCompatibilityEvaluationMethod(
            declaration,
            in: file,
            context: context
        )
    }
}

private func firstInlinePortAdapterTypedInteractionDispatchMethod(
    in file: ArchitectureFile,
    portAdapterTypeName: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> ArchitectureMethodDeclaration? {
    methods.first { declaration in
        guard declaration.enclosingTypeName == portAdapterTypeName,
              declaration.isPrivateOrFileprivate,
              !isExcludedGatewayDecisionControlMethod(declaration),
              !isObviousTechnicalDecisionMethod(
                declaration,
                in: file,
                context: context
              ),
              !isTypedBoundaryCompatibilityEvaluationMethod(
                declaration,
                in: file,
                context: context
              ),
              hasTypedInteractionDispatchInput(
                declaration,
                file: file,
                context: context
              ),
              !hasGatewayInteractionDispatchControlPattern(
                declaration,
                in: file
              ),
              !hasPortAdapterLegitimateFinalRenderOutputPattern(
                declaration,
                in: file
              ) else {
            return false
        }

        return hasInlineTypedInteractionDispatchStructure(
            declaration,
            in: file
        )
    }
}

private func hasEvaluatorDecisionSurface(
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let concreteTopLevelTypeNames = Set(
        file.topLevelDeclarations.compactMap { declaration -> String? in
            guard declaration.kind != .protocol else {
                return nil
            }

            return declaration.name
        }
    )

    return file.methodDeclarations.contains { declaration in
        guard concreteTopLevelTypeNames.contains(declaration.enclosingTypeName) else {
            return false
        }

        return isObviousTechnicalDecisionMethod(
            declaration,
            in: file,
            context: context
        )
    }
}

private func hasEvaluatorExecutionOrchestrationViolation(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile
) -> Bool {
    let operationalUses = gatewayOperationalUses(
        in: file,
        enclosingTypeName: declaration.enclosingTypeName,
        methodName: declaration.name
    )

    return operationalUses.contains { occurrence in
        let baseName = occurrence.baseName.lowercased()
        let memberName = occurrence.memberName.lowercased()

        return executionLikeOperationNameFragments.contains(where: baseName.contains)
            || executionLikeOperationNameFragments.contains(where: memberName.contains)
    }
}

private func hasEvaluatorTranslationViolation(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile
) -> Bool {
    if declaration.parameterTypeNames.contains(where: isPrimitiveOrRawTechnicalTypeName) {
        return true
    }

    let operationalUses = gatewayOperationalUses(
        in: file,
        enclosingTypeName: declaration.enclosingTypeName,
        methodName: declaration.name
    )

    return operationalUses.contains { occurrence in
        let baseName = occurrence.baseName.lowercased()
        let memberName = occurrence.memberName.lowercased()

        return evaluatorTranslationOperationNameFragments.contains(where: baseName.contains)
            || evaluatorTranslationOperationNameFragments.contains(where: memberName.contains)
    }
}

private func hasPortAdapterLegitimateFinalRenderOutputPattern(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile
) -> Bool {
    guard declaration.returnTypeNames.contains(where: { portAdapterRenderOutputTypeNames.contains($0) }) else {
        return false
    }

    let lowercasedName = declaration.name.lowercased()
    let operationalUses = gatewayOperationalUses(
        in: file,
        enclosingTypeName: declaration.enclosingTypeName,
        methodName: declaration.name
    )

    let hasRenderIntentEvidence = portAdapterRenderIntentNameFragments.contains(where: lowercasedName.contains)
        || operationalUses.contains { occurrence in
            let baseName = occurrence.baseName.lowercased()
            let memberName = occurrence.memberName.lowercased()
            return portAdapterRenderIntentNameFragments.contains(where: baseName.contains)
                || portAdapterRenderIntentNameFragments.contains(where: memberName.contains)
        }

    guard hasRenderIntentEvidence else {
        return false
    }

    let hasExecutionLikeOperations = operationalUses.contains { occurrence in
        let baseName = occurrence.baseName.lowercased()
        let memberName = occurrence.memberName.lowercased()

        return executionLikeOperationNameFragments.contains(where: baseName.contains)
            || executionLikeOperationNameFragments.contains(where: memberName.contains)
    }

    guard !hasExecutionLikeOperations else {
        return false
    }

    let hasBranchLocalBoundaryWork = operationalUses.contains { occurrence in
        guard occurrence.branchGroupIndex != nil,
              occurrence.branchArmIndex != nil else {
            return false
        }

        return isBranchLocalGatewayBoundaryWorkOccurrence(occurrence)
    }

    guard !hasBranchLocalBoundaryWork else {
        return false
    }

    let hasSimpleFinalOutputChoicePattern = hasMultipleBranchArms(
        in: operationalUses
    )

    return hasRenderIntentEvidence || hasSimpleFinalOutputChoicePattern
}

private enum InlineNormalizationPreparationOwner {
    case gateway
    case portAdapter
}

private func isObviousTechnicalDecisionMethod(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    guard declaration.hasExplicitReturnType,
          !declaration.returnsVoidLike,
          hasAlreadyShapedTypedTechnicalInput(
            declaration,
            file: file,
            context: context
          ),
          returnsTypedTechnicalDecision(
            declaration,
            file: file,
            context: context
          ),
          !hasRawExtractionOrTranslationSignature(
            declaration,
            in: file,
            context: context
          ) else {
        return false
    }

    let operationalUses = gatewayOperationalUses(
        in: file,
        enclosingTypeName: declaration.enclosingTypeName,
        methodName: declaration.name
    )

    return operationalUses.allSatisfy(isAllowedDecisionSupportOperation)
}

private func isInlineNormalizationPreparationMethod(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile,
    context: ProjectContext,
    owner: InlineNormalizationPreparationOwner
) -> Bool {
    guard declaration.isPrivateOrFileprivate,
          declaration.hasExplicitReturnType,
          !declaration.returnsVoidLike,
          hasInlineNormalizationPreparationInputCluster(
            declaration,
            in: file,
            context: context
          ),
          returnsInlineNormalizationPreparationOutput(
            declaration,
            in: file,
            context: context
          ),
          hasInlineNormalizationPreparationRoleCluster(
            declaration,
            in: file,
            context: context
          ),
          !returnsInlineNormalizationPreparationDecisionOutput(declaration),
          !hasInlineNormalizationPreparationParserSubsystemSignals(
            declaration,
            in: file,
            context: context
          ),
          !hasInlineNormalizationPreparationExecutionSignals(
            declaration,
            in: file
          ),
          !isObviousTechnicalDecisionMethod(
            declaration,
            in: file,
            context: context
          ),
          !isTypedBoundaryCompatibilityEvaluationMethod(
            declaration,
            in: file,
            context: context
          ) else {
        return false
    }

    let returnsPrimitiveLikeOutput = declaration.returnTypeNames.allSatisfy { typeName in
        isPrimitiveOrRawTechnicalTypeName(typeName) || containerTypeNames.contains(typeName)
    }

    guard !returnsPrimitiveLikeOutput
            || hasInlineNormalizationPreparationBoundaryContextEvidence(
                declaration,
                in: file,
                context: context
            ) else {
        return false
    }

    switch owner {
    case .gateway:
        return !hasGatewayNormalizationPreparationControlSignals(
            declaration,
            in: file
        )
    case .portAdapter:
        return !hasPortAdapterLegitimateFinalRenderOutputPattern(
            declaration,
            in: file
        )
    }
}

private func isTypedBoundaryCompatibilityEvaluationMethod(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    guard hasTypedBoundaryCompatibilityInputCluster(
        declaration,
        in: file,
        context: context
    ),
    hasGatewayCompatibilityEvaluationStructure(
        declaration,
        in: file,
        context: context
    ),
    hasStrongGatewayCompatibilityFailureMappingSignal(
        declaration,
        in: file,
        context: context
    ),
    !hasDisqualifyingGatewayCompatibilityOperations(
        declaration,
        in: file
    ) else {
        return false
    }

    return true
}

private func hasAlreadyShapedTypedTechnicalInput(
    _ declaration: ArchitectureMethodDeclaration,
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    declaration.parameterTypeNames.contains { typeName in
        isAlreadyShapedTypedTechnicalTypeName(
            typeName,
            in: file,
            context: context
        )
    }
}

private func hasTypedInteractionDispatchInput(
    _ declaration: ArchitectureMethodDeclaration,
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    declaration.parameterTypeNames.contains { typeName in
        isTypedInteractionDispatchInputTypeName(
            typeName,
            in: file,
            context: context
        )
    }
}

private func hasTypedBoundaryCompatibilityInputCluster(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let compatibilityInputCount = declaration.parameterTypeNames.filter { typeName in
        isTypedBoundaryCompatibilityInputTypeName(
            typeName,
            in: file,
            context: context
        )
    }.count

    return compatibilityInputCount >= 2
}

private func returnsTypedTechnicalDecision(
    _ declaration: ArchitectureMethodDeclaration,
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    declaration.returnTypeNames.contains { typeName in
        isTypedTechnicalDecisionTypeName(
            typeName,
            in: file,
            context: context
        )
    }
}

private func isTypedBoundaryCompatibilityInputTypeName(
    _ typeName: String,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    guard !isPrimitiveOrRawTechnicalTypeName(typeName),
          !containerTypeNames.contains(typeName) else {
        return false
    }

    if hasLocalConcreteTechnicalTypeNamed(typeName, in: file) {
        return true
    }

    guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
        return false
    }

    switch indexedDeclaration.roleFolder {
    case .applicationContractsCommands,
         .applicationContractsPorts,
         .applicationContractsWorkflow,
         .infrastructureTranslationModels,
         .infrastructureTranslationDTOs,
         .infrastructureEvaluators:
        return true
    default:
        return false
    }
}

private func isTypedInteractionDispatchInputTypeName(
    _ typeName: String,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    guard !isPrimitiveOrRawTechnicalTypeName(typeName),
          !containerTypeNames.contains(typeName) else {
        return false
    }

    if hasLocalConcreteTechnicalTypeNamed(typeName, in: file) {
        return true
    }

    guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
        return false
    }

    switch indexedDeclaration.roleFolder {
    case .applicationContractsCommands,
         .applicationContractsPorts,
         .applicationContractsWorkflow,
         .infrastructureTranslationModels,
         .infrastructureTranslationDTOs,
         .infrastructureEvaluators,
         .infrastructureErrors:
        return true
    default:
        return false
    }
}

private func isAlreadyShapedTypedTechnicalTypeName(
    _ typeName: String,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    guard !isPrimitiveOrRawTechnicalTypeName(typeName),
          !containerTypeNames.contains(typeName) else {
        return false
    }

    if hasLocalConcreteTechnicalTypeNamed(typeName, in: file) {
        return true
    }

    guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
        return false
    }

    switch indexedDeclaration.roleFolder {
    case .infrastructureTranslationModels,
         .infrastructureTranslationDTOs,
         .infrastructureEvaluators,
         .infrastructureErrors:
        return true
    default:
        return false
    }
}

private func hasGatewayCompatibilityEvaluationStructure(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let compatibilityInputCount = declaration.parameterTypeNames.filter { typeName in
        isTypedBoundaryCompatibilityInputTypeName(
            typeName,
            in: file,
            context: context
        )
    }.count
    let operationalUses = gatewayOperationalUses(
        in: file,
        enclosingTypeName: declaration.enclosingTypeName,
        methodName: declaration.name
    )

    let compatibilityComparisonCount = operationalUses.reduce(into: 0) { count, occurrence in
        let memberName = occurrence.memberName.lowercased()
        if compatibilityEvaluationOperationNames.contains(memberName) {
            count += 1
        }
    }

    return compatibilityInputCount >= 2 && compatibilityComparisonCount >= 2
}

private func hasInlineNormalizationPreparationInputCluster(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let rawInputCount = declaration.parameterTypeNames.filter { typeName in
        isInlineNormalizationPreparationInputTypeName(
            typeName,
            in: file,
            context: context
        )
    }.count

    return rawInputCount >= 1
}

private func returnsInlineNormalizationPreparationOutput(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    declaration.returnTypeNames.contains { typeName in
        isInlineNormalizationPreparationOutputTypeName(
            typeName,
            in: file,
            context: context
        )
    }
}

private func isTypedTechnicalDecisionTypeName(
    _ typeName: String,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    guard !isPrimitiveOrRawTechnicalTypeName(typeName),
          !containerTypeNames.contains(typeName) else {
        return false
    }

    if hasLocalConcreteTechnicalTypeNamed(typeName, in: file) {
        return true
    }

    guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
        return false
    }

    switch indexedDeclaration.roleFolder {
    case .infrastructureTranslationModels,
         .infrastructureTranslationDTOs,
         .infrastructureEvaluators,
         .infrastructureErrors:
        return true
    default:
        return false
    }
}

private func hasStrongGatewayCompatibilityFailureMappingSignal(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let operationalUses = gatewayOperationalUses(
        in: file,
        enclosingTypeName: declaration.enclosingTypeName,
        methodName: declaration.name
    )

    let constructsInfrastructureError = operationalUses.contains { occurrence in
        isInfrastructureErrorTypeName(
            occurrence.baseName,
            in: file,
            context: context
        )
    }

    let returnsTypedFailure = declaration.returnTypeNames.contains { typeName in
        let lowercased = typeName.lowercased()
        guard !isPrimitiveOrRawTechnicalTypeName(typeName),
              !containerTypeNames.contains(typeName) else {
            return false
        }

        return lowercased.contains("failure")
            || lowercased.contains("outcome")
            || lowercased.contains("result")
    }

    return constructsInfrastructureError || returnsTypedFailure
}

private func hasInlineNormalizationPreparationRoleCluster(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let normalizationOperationCount = inlineNormalizationPreparationOperationSignalCount(
        declaration,
        in: file
    )
    let hasNameEvidence = hasInlineNormalizationPreparationNameEvidence(declaration)
    let hasPassiveShapeConstruction = hasInlineNormalizationPreparationPassiveShapeConstruction(
        declaration,
        in: file,
        context: context
    )

    return normalizationOperationCount >= 2
        || (normalizationOperationCount >= 1 && hasPassiveShapeConstruction)
        || (normalizationOperationCount >= 1
            && hasNameEvidence
            && hasInlineNormalizationPreparationBoundaryContextEvidence(
                declaration,
                in: file,
                context: context
            ))
}

private func hasInlineTypedInteractionDispatchStructure(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile
) -> Bool {
    let branchOperationalUses = gatewayOperationalUses(
        in: file,
        enclosingTypeName: declaration.enclosingTypeName,
        methodName: declaration.name
    ).filter { occurrence in
        occurrence.branchGroupIndex != nil && occurrence.branchArmIndex != nil
    }

    let branchArmsWithBoundaryWorkByGroup = branchOperationalUses.reduce(into: [Int: Set<Int>]()) { result, occurrence in
        guard let branchGroupIndex = occurrence.branchGroupIndex,
              let branchArmIndex = occurrence.branchArmIndex,
              isBranchLocalGatewayBoundaryWorkOccurrence(occurrence) else {
            return
        }

        result[branchGroupIndex, default: []].insert(branchArmIndex)
    }

    return branchArmsWithBoundaryWorkByGroup.values.contains { $0.count >= 2 }
}

private func hasMultipleBranchArms(
    in operationalUses: [ArchitectureOperationalUseOccurrence]
) -> Bool {
    let branchArmsByGroup = operationalUses.reduce(into: [Int: Set<Int>]()) { result, occurrence in
        guard let branchGroupIndex = occurrence.branchGroupIndex,
              let branchArmIndex = occurrence.branchArmIndex else {
            return
        }

        result[branchGroupIndex, default: []].insert(branchArmIndex)
    }

    return branchArmsByGroup.values.contains { $0.count >= 2 }
}

private func hasGatewayInteractionDispatchControlPattern(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile
) -> Bool {
    if gatewayInteractionDispatchControlNameFragments.contains(where: declaration.name.lowercased().contains) {
        return true
    }

    let operationalUses = gatewayOperationalUses(
        in: file,
        enclosingTypeName: declaration.enclosingTypeName,
        methodName: declaration.name
    )

    return operationalUses.contains { occurrence in
        let baseName = occurrence.baseName.lowercased()
        let memberName = occurrence.memberName.lowercased()

        return gatewayInteractionDispatchControlNameFragments.contains(where: baseName.contains)
            || gatewayInteractionDispatchControlNameFragments.contains(where: memberName.contains)
    }
}

private func isBranchLocalGatewayBoundaryWorkOccurrence(
    _ occurrence: ArchitectureOperationalUseOccurrence
) -> Bool {
    let baseName = occurrence.baseName.lowercased()
    let memberName = occurrence.memberName.lowercased()

    return isLikelyImmediateTransportExecutionCallName(baseName)
        || isLikelyImmediateTransportExecutionCallName(memberName)
        || isLikelyGatewayBoundaryExecutionMethodName(baseName)
        || isLikelyGatewayBoundaryExecutionMethodName(memberName)
        || branchBoundaryWorkOperationNameFragments.contains(where: baseName.contains)
        || branchBoundaryWorkOperationNameFragments.contains(where: memberName.contains)
}

private func inlineTypedInteractionDispatchPassiveShapeDestinations(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Set<InlineTypedInteractionDispatchPassiveShapeDestination> {
    let branchOperationalUses = gatewayOperationalUses(
        in: file,
        enclosingTypeName: declaration.enclosingTypeName,
        methodName: declaration.name
    ).filter { occurrence in
        occurrence.branchGroupIndex != nil && occurrence.branchArmIndex != nil
    }

    return branchOperationalUses.reduce(into: Set<InlineTypedInteractionDispatchPassiveShapeDestination>()) { result, occurrence in
        if isInlinePassiveBranchDTOShapeOccurrence(occurrence, in: file, context: context) {
            result.insert(.dtos)
        }

        if isInlinePassiveBranchModelShapeOccurrence(occurrence, in: file, context: context) {
            result.insert(.models)
        }
    }
}

private func isInlinePassiveBranchDTOShapeOccurrence(
    _ occurrence: ArchitectureOperationalUseOccurrence,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let typeName = occurrence.baseName
    guard occurrence.memberName == "callAsFunction"
            || occurrence.memberName == "init"
            || occurrence.memberName == "response"
            || occurrence.memberName == "request" else {
        return false
    }

    return isFinalProviderTransportBoundaryShapeTypeName(
        typeName,
        file: file,
        context: context
    ) || isLikelyFinalProviderTransportCarrierTypeName(typeName)
}

private func isInlinePassiveBranchModelShapeOccurrence(
    _ occurrence: ArchitectureOperationalUseOccurrence,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let typeName = occurrence.baseName
    guard occurrence.memberName == "callAsFunction"
            || occurrence.memberName == "init" else {
        return false
    }

    if let localDeclaration = file.topLevelDeclarations.first(where: {
        $0.kind != .protocol && $0.name == typeName
    }) {
        return localDeclaration.name.hasSuffix("Model")
            || localDeclaration.name.hasSuffix("Payload")
            || localDeclaration.name.hasSuffix("Record")
            || isLikelyBoundaryDefinitionCarrierTypeName(localDeclaration.name)
    }

    guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
        return false
    }

    return indexedDeclaration.roleFolder == .infrastructureTranslationModels
        && (indexedDeclaration.name.hasSuffix("Model")
            || indexedDeclaration.name.hasSuffix("Payload")
            || indexedDeclaration.name.hasSuffix("Record")
            || isLikelyBoundaryDefinitionCarrierTypeName(indexedDeclaration.name))
}

private func hasRawExtractionOrTranslationSignature(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let lowercasedName = declaration.name.lowercased()
    if rawExtractionOrTranslationNameFragments.contains(where: lowercasedName.contains) {
        return true
    }

    if declaration.parameterTypeNames.contains(where: isPrimitiveOrRawTechnicalTypeName) {
        return true
    }

    let operationalUses = gatewayOperationalUses(
        in: file,
        enclosingTypeName: declaration.enclosingTypeName,
        methodName: declaration.name
    )

    return operationalUses.contains { occurrence in
        rawExtractionOrTranslationNameFragments.contains(where: occurrence.baseName.lowercased().contains)
            || rawExtractionOrTranslationNameFragments.contains(where: occurrence.memberName.lowercased().contains)
    }
}

private func isInlineNormalizationPreparationInputTypeName(
    _ typeName: String,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    if isPrimitiveOrRawTechnicalTypeName(typeName) || containerTypeNames.contains(typeName) {
        return true
    }

    guard isInlineNormalizationPreparationBoundaryContextTypeName(
        typeName,
        in: file,
        context: context
    ) else {
        return false
    }

    if hasLocalConcreteTechnicalTypeNamed(typeName, in: file) {
        return true
    }

    guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
        return false
    }

    return indexedDeclaration.layer != .domain
        && indexedDeclaration.roleFolder != .infrastructureEvaluators
}

private func isInlineNormalizationPreparationOutputTypeName(
    _ typeName: String,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    if isPrimitiveOrRawTechnicalTypeName(typeName) || containerTypeNames.contains(typeName) {
        return true
    }

    if isFinalProviderTransportBoundaryShapeTypeName(
        typeName,
        file: file,
        context: context
    ) {
        return true
    }

    if hasLocalConcreteTechnicalTypeNamed(typeName, in: file) {
        let lowercasedName = typeName.lowercased()
        return inlineNormalizationPreparationOutputTypeNameFragments.contains(where: lowercasedName.contains)
            && !returnsInlineNormalizationPreparationDecisionOutputTypeName(typeName)
    }

    guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
        return false
    }

    switch indexedDeclaration.roleFolder {
    case .infrastructureTranslationModels, .infrastructureTranslationDTOs:
        return true
    default:
        let lowercasedName = indexedDeclaration.name.lowercased()
        return inlineNormalizationPreparationOutputTypeNameFragments.contains(where: lowercasedName.contains)
            && !returnsInlineNormalizationPreparationDecisionOutputTypeName(indexedDeclaration.name)
    }
}

private func hasInlineNormalizationPreparationNameEvidence(
    _ declaration: ArchitectureMethodDeclaration
) -> Bool {
    let lowercasedName = declaration.name.lowercased()
    return inlineNormalizationPreparationNameFragments.contains(where: lowercasedName.contains)
}

private func inlineNormalizationPreparationOperationSignalCount(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile
) -> Int {
    let operationalUses = gatewayOperationalUses(
        in: file,
        enclosingTypeName: declaration.enclosingTypeName,
        methodName: declaration.name
    )

    let matchedSignals = operationalUses.reduce(into: Set<String>()) { result, occurrence in
        let baseName = occurrence.baseName.lowercased()
        let memberName = occurrence.memberName.lowercased()

        if inlineNormalizationPreparationOperationNames.contains(memberName) {
            result.insert("member:\(memberName)")
        }

        if inlineNormalizationPreparationOperationNames.contains(baseName) {
            result.insert("base:\(baseName)")
        }

        if let fragment = inlineNormalizationPreparationOperationFragments.first(where: memberName.contains) {
            result.insert("fragment-member:\(fragment)")
        }

        if let fragment = inlineNormalizationPreparationOperationFragments.first(where: baseName.contains) {
            result.insert("fragment-base:\(fragment)")
        }
    }

    return matchedSignals.count
}

private func hasInlineNormalizationPreparationPassiveShapeConstruction(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let operationalUses = gatewayOperationalUses(
        in: file,
        enclosingTypeName: declaration.enclosingTypeName,
        methodName: declaration.name
    )

    return operationalUses.contains { occurrence in
        isInlineNormalizationPreparationPassiveShapeOccurrence(
            occurrence,
            in: file,
            context: context
        )
    }
}

private func isInlineNormalizationPreparationPassiveShapeOccurrence(
    _ occurrence: ArchitectureOperationalUseOccurrence,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    guard occurrence.memberName == "callAsFunction"
            || occurrence.memberName == "init" else {
        return false
    }

    return isInlineNormalizationPreparationOutputTypeName(
        occurrence.baseName,
        in: file,
        context: context
    )
}

private func hasInlineNormalizationPreparationBoundaryContextEvidence(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    if hasInlineNormalizationPreparationNameEvidence(declaration) {
        return true
    }

    if declaration.parameterTypeNames.contains(where: { typeName in
        isInlineNormalizationPreparationBoundaryContextTypeName(
            typeName,
            in: file,
            context: context
        )
    }) || declaration.returnTypeNames.contains(where: { typeName in
        isInlineNormalizationPreparationBoundaryContextTypeName(
            typeName,
            in: file,
            context: context
        )
    }) {
        return true
    }

    let operationalUses = gatewayOperationalUses(
        in: file,
        enclosingTypeName: declaration.enclosingTypeName,
        methodName: declaration.name
    )

    return operationalUses.contains { occurrence in
        let baseName = occurrence.baseName.lowercased()
        let memberName = occurrence.memberName.lowercased()

        return inlineNormalizationPreparationBoundaryContextFragments.contains(where: baseName.contains)
            || inlineNormalizationPreparationBoundaryContextFragments.contains(where: memberName.contains)
    } || hasInlineNormalizationPreparationPassiveShapeConstruction(
        declaration,
        in: file,
        context: context
    )
}

private func isInlineNormalizationPreparationBoundaryContextTypeName(
    _ typeName: String,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let lowercasedName = typeName.lowercased()
    if inlineNormalizationPreparationBoundaryContextFragments.contains(where: lowercasedName.contains) {
        return true
    }

    if isFinalProviderTransportBoundaryShapeTypeName(
        typeName,
        file: file,
        context: context
    ) {
        return true
    }

    if hasLocalConcreteTechnicalTypeNamed(typeName, in: file) {
        return false
    }

    guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
        return false
    }

    switch indexedDeclaration.roleFolder {
    case .infrastructureTranslationModels, .infrastructureTranslationDTOs:
        return true
    default:
        return inlineNormalizationPreparationBoundaryContextFragments.contains(where: indexedDeclaration.name.lowercased().contains)
    }
}

private func returnsInlineNormalizationPreparationDecisionOutput(
    _ declaration: ArchitectureMethodDeclaration
) -> Bool {
    declaration.returnTypeNames.contains(where: returnsInlineNormalizationPreparationDecisionOutputTypeName)
}

private func returnsInlineNormalizationPreparationDecisionOutputTypeName(_ typeName: String) -> Bool {
    if typeName == "Bool" {
        return true
    }

    let lowercasedName = typeName.lowercased()
    return inlineNormalizationPreparationDecisionOutputFragments.contains(where: lowercasedName.contains)
}

private func hasInlineNormalizationPreparationParserSubsystemSignals(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let lowercasedName = declaration.name.lowercased()
    if inlineNormalizationPreparationParserFragments.contains(where: lowercasedName.contains) {
        return true
    }

    if returnsParserModelTranslationType(
        declaration,
        file: file,
        context: context
    ) {
        return true
    }

    if declaration.parameterTypeNames.contains(where: {
        isParserModelTranslationTypeName(
            $0,
            file: file,
            context: context
        )
    }) {
        return true
    }

    let operationalUses = gatewayOperationalUses(
        in: file,
        enclosingTypeName: declaration.enclosingTypeName,
        methodName: declaration.name
    )

    return operationalUses.contains { occurrence in
        let baseName = occurrence.baseName.lowercased()
        let memberName = occurrence.memberName.lowercased()

        return inlineNormalizationPreparationParserFragments.contains(where: baseName.contains)
            || inlineNormalizationPreparationParserFragments.contains(where: memberName.contains)
    }
}

private func hasInlineNormalizationPreparationExecutionSignals(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile
) -> Bool {
    let lowercasedName = declaration.name.lowercased()
    if inlineNormalizationPreparationExecutionFragments.contains(where: lowercasedName.contains) {
        return true
    }

    let operationalUses = gatewayOperationalUses(
        in: file,
        enclosingTypeName: declaration.enclosingTypeName,
        methodName: declaration.name
    )

    return operationalUses.contains { occurrence in
        let baseName = occurrence.baseName.lowercased()
        let memberName = occurrence.memberName.lowercased()

        return inlineNormalizationPreparationExecutionFragments.contains(where: baseName.contains)
            || inlineNormalizationPreparationExecutionFragments.contains(where: memberName.contains)
            || isLikelyImmediateTransportExecutionCallName(baseName)
            || isLikelyImmediateTransportExecutionCallName(memberName)
    }
}

private func hasGatewayNormalizationPreparationControlSignals(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile
) -> Bool {
    let lowercasedName = declaration.name.lowercased()
    if inlineNormalizationPreparationGatewayControlFragments.contains(where: lowercasedName.contains) {
        return true
    }

    let operationalUses = gatewayOperationalUses(
        in: file,
        enclosingTypeName: declaration.enclosingTypeName,
        methodName: declaration.name
    )

    return operationalUses.contains { occurrence in
        let baseName = occurrence.baseName.lowercased()
        let memberName = occurrence.memberName.lowercased()

        return inlineNormalizationPreparationGatewayControlFragments.contains(where: baseName.contains)
            || inlineNormalizationPreparationGatewayControlFragments.contains(where: memberName.contains)
    }
}

private func hasDisqualifyingGatewayCompatibilityOperations(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile
) -> Bool {
    if excludedGatewayDecisionControlNameFragments.contains(where: declaration.name.lowercased().contains) {
        return true
    }

    let operationalUses = gatewayOperationalUses(
        in: file,
        enclosingTypeName: declaration.enclosingTypeName,
        methodName: declaration.name
    )

    return operationalUses.contains { occurrence in
        let baseName = occurrence.baseName.lowercased()
        let memberName = occurrence.memberName.lowercased()

        return disallowedGatewayCompatibilityOperationNames.contains(memberName)
            || disallowedGatewayCompatibilityOperationNames.contains(baseName)
            || gatewayCompatibilityControlFragments.contains(where: memberName.contains)
            || gatewayCompatibilityControlFragments.contains(where: baseName.contains)
    }
}

private func isExcludedGatewayDecisionControlMethod(_ declaration: ArchitectureMethodDeclaration) -> Bool {
    let lowercasedName = declaration.name.lowercased()

    return excludedGatewayDecisionControlNameFragments.contains(where: lowercasedName.contains)
}

private func isAllowedDecisionSupportOperation(_ occurrence: ArchitectureOperationalUseOccurrence) -> Bool {
    let baseName = occurrence.baseName.lowercased()
    let memberName = occurrence.memberName.lowercased()

    if executionLikeOperationNameFragments.contains(where: baseName.contains)
        || executionLikeOperationNameFragments.contains(where: memberName.contains) {
        return false
    }

    if rawExtractionOrTranslationNameFragments.contains(where: baseName.contains)
        || rawExtractionOrTranslationNameFragments.contains(where: memberName.contains) {
        return false
    }

    if excludedGatewayDecisionControlNameFragments.contains(where: baseName.contains)
        || excludedGatewayDecisionControlNameFragments.contains(where: memberName.contains) {
        return false
    }

    return allowedDecisionSupportOperationNames.contains(memberName)
}

private func isPrimitiveOrRawTechnicalTypeName(_ typeName: String) -> Bool {
    primitiveOrRawTechnicalTypeNames.contains(typeName)
}

private func hasLocalConcreteTechnicalTypeNamed(
    _ typeName: String,
    in file: ArchitectureFile
) -> Bool {
    file.topLevelDeclarations.contains(where: {
        $0.kind != .protocol && $0.name == typeName
    }) || file.nestedNominalDeclarations.contains(where: {
        $0.kind != .protocol && $0.name == typeName
    })
}

private func isInfrastructureErrorTypeName(
    _ typeName: String,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    if file.topLevelDeclarations.contains(where: {
        $0.kind != .protocol
            && $0.name == typeName
            && ($0.name.hasSuffix("Error")
                || $0.inheritedTypeNames.contains("StructuredErrorProtocol")
                || $0.inheritedTypeNames.contains("Error")
                || $0.inheritedTypeNames.contains("LocalizedError"))
    }) {
        return true
    }

    guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
        return false
    }

    return isInfrastructureErrorDeclaration(indexedDeclaration)
}

private func isLikelyInlineGatewayBoundaryConfigurationShapingMethod(
    _ declaration: ArchitectureMethodDeclaration,
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let lowercasedName = declaration.name.lowercased()
    guard isLikelyGatewayBoundaryConfigurationMethodName(lowercasedName) else {
        return false
    }

    let hasConfigurationInput = declaration.parameterTypeNames.contains { typeName in
        isLikelyBoundaryConfigurationSourceTypeName(typeName, context: context)
    }
    let returnsConfigurationCarrier = declaration.returnTypeNames.contains { typeName in
        isLikelyBoundaryConfigurationCarrierTypeName(typeName)
            || isConfigurationTranslationCarrierTypeName(typeName, file: file, context: context)
    }

    return hasConfigurationInput
        || returnsConfigurationCarrier
        || hasGatewayBoundaryConfigurationOperationEvidence(
            declaration,
            in: file
        )
}

private func isStrongGatewayBoundaryConfigurationShapingMethod(
    _ declaration: ArchitectureMethodDeclaration,
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    declaration.parameterTypeNames.contains { typeName in
        isLikelyBoundaryConfigurationSourceTypeName(typeName, context: context)
    } || declaration.returnTypeNames.contains { typeName in
        isLikelyBoundaryConfigurationCarrierTypeName(typeName)
            || isConfigurationTranslationCarrierTypeName(typeName, file: file, context: context)
    }
}

private func hasGatewayOperationLikeBoundaryDefinitionShapingEvidence(
    in file: ArchitectureFile,
    gatewayTypeName: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> Bool {
    return methods.contains { declaration in
        isLikelyInlineGatewayBoundaryDefinitionShapingMethod(
            declaration,
            context: context
        )
    }
}

private func hasGatewayFactoryStyleBoundaryDefinitionShapingEvidence(
    in file: ArchitectureFile,
    gatewayTypeName: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> Bool {
    let publicSurfaces = methods.filter { declaration in
        declaration.isPublicOrOpen
            && isLikelyGatewayFactoryStyleBoundaryDefinitionSurface(
                declaration,
                file: file,
                context: context
            )
    }

    guard !publicSurfaces.isEmpty else {
        return false
    }

    let privateHelpers = methods.filter { declaration in
        !declaration.isPublicOrOpen
            && isLikelyGatewayFactoryStyleBoundaryDefinitionSurface(
                declaration,
                file: file,
                context: context
            )
    }

    return !privateHelpers.isEmpty
        || hasGatewayBoundaryDefinitionMemberEvidence(
            in: file,
            gatewayTypeName: gatewayTypeName
        )
}

private func isLikelyInlineGatewayBoundaryDefinitionShapingMethod(
    _ declaration: ArchitectureMethodDeclaration,
    context: ProjectContext
) -> Bool {
    let lowercasedName = declaration.name.lowercased()
    let hasBoundaryDefinitionMethodName = isLikelyGatewayBoundaryDefinitionMethodName(lowercasedName)
    let hasOperationDefinitionSurface = (declaration.parameterTypeNames.filter { $0 == "String" }.count >= 2
        && hasGatewayRequestDefinitionIngredientEvidence(declaration, context: context))
        || lowercasedName.contains("requestdefinition")
        || lowercasedName.contains("variables")
        || lowercasedName.contains("query")
        || lowercasedName.contains("operation")

    if hasBoundaryDefinitionMethodName
        && (hasOperationDefinitionSurface
            || declaration.returnTypeNames.contains(where: isLikelyBoundaryDefinitionCarrierTypeName)) {
        return true
    }

    return (hasBoundaryDefinitionMethodName || hasOperationDefinitionSurface)
        && acceptsGatewayBoundaryDefinitionSourceInput(declaration, context: context)
}

private func isLikelyGatewayFactoryStyleBoundaryDefinitionSurface(
    _ declaration: ArchitectureMethodDeclaration,
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    guard declaration.hasExplicitReturnType,
          !declaration.returnsVoidLike,
          returnsBoundaryDefinitionShape(
            declaration,
            file: file,
            context: context
          ) else {
        return false
    }

    let lowercasedName = declaration.name.lowercased()
    return isLikelyGatewayBoundaryDefinitionMethodName(lowercasedName)
        || acceptsGatewayBoundaryDefinitionSourceInput(
            declaration,
            context: context
        )
}

private func returnsBoundaryDefinitionShape(
    _ declaration: ArchitectureMethodDeclaration,
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    if declaration.returnTypeNames.contains("URLRequest")
        || declaration.returnTypeNames.contains("HTTPURLResponse") {
        return true
    }

    if returnsRequestDefinitionTranslationType(declaration, file: file, context: context) {
        return true
    }

    return declaration.returnTypeNames.contains { typeName in
        if isLikelyBoundaryDefinitionCarrierTypeName(typeName) {
            return true
        }

        guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
            return false
        }

        guard isApplicationContractDeclaration(indexedDeclaration)
                || indexedDeclaration.roleFolder == .infrastructureTranslationModels
                || indexedDeclaration.roleFolder == .infrastructureTranslationDTOs else {
            return false
        }

        return isLikelyBoundaryDefinitionCarrierTypeName(indexedDeclaration.name)
    }
}

private func acceptsGatewayBoundaryDefinitionSourceInput(
    _ declaration: ArchitectureMethodDeclaration,
    context: ProjectContext
) -> Bool {
    let stringCount = declaration.parameterTypeNames.filter { $0 == "String" }.count
    let hasConfigurationInput = declaration.parameterTypeNames.contains { typeName in
        isLikelyBoundaryConfigurationSourceTypeName(typeName, context: context)
    }
    let hasInwardBusinessInput = declaration.parameterTypeNames.contains { typeName in
        guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
            return false
        }

        guard indexedDeclaration.layer == .domain || isApplicationContractDeclaration(indexedDeclaration) else {
            return false
        }

        return !isLikelyBoundaryDefinitionCarrierTypeName(indexedDeclaration.name)
            && !isLikelyBoundaryConfigurationCarrierTypeName(indexedDeclaration.name)
    }

    return (hasConfigurationInput && (stringCount >= 1 || hasInwardBusinessInput))
        || (stringCount >= 2 && hasInwardBusinessInput)
        || stringCount >= 3
}

private func hasGatewayBoundaryConfigurationMemberEvidence(
    in file: ArchitectureFile,
    gatewayTypeName: String
) -> Bool {
    file.storedMemberDeclarations.contains { declaration in
        declaration.enclosingTypeName == gatewayTypeName
            && isLikelyGatewayBoundaryConfigurationMemberName(declaration.name)
    } || file.computedPropertyDeclarations.contains { declaration in
        declaration.enclosingTypeName == gatewayTypeName
            && isLikelyGatewayBoundaryConfigurationMemberName(declaration.name)
    }
}

private func hasGatewayBoundaryDefinitionMemberEvidence(
    in file: ArchitectureFile,
    gatewayTypeName: String
) -> Bool {
    file.storedMemberDeclarations.contains { declaration in
        declaration.enclosingTypeName == gatewayTypeName
            && isLikelyGatewayBoundaryDefinitionMemberName(declaration.name)
    } || file.computedPropertyDeclarations.contains { declaration in
        declaration.enclosingTypeName == gatewayTypeName
            && isLikelyGatewayBoundaryDefinitionMemberName(declaration.name)
    }
}

private func isNestedBoundaryShapingHelper(
    _ declaration: ArchitectureNestedNominalDeclaration,
    in file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    classifyNestedBoundaryShapingHelper(
        declaration,
        in: file,
        context: context
    ) != nil
}

private func classifyNestedBoundaryShapingHelper(
    _ declaration: ArchitectureNestedNominalDeclaration,
    in file: ArchitectureFile,
    context: ProjectContext
) -> NestedBoundaryShapingHelperClassification? {
    let nestedMethods = file.methodDeclarations.filter { $0.enclosingTypeName == declaration.name }
    let hasIntermediaryShaping = hasConfigurationNormalizationResponsibility(
        in: nestedMethods,
        file: file,
        context: context
    ) || hasIntermediaryRequestDefinitionShapingResponsibility(
        in: nestedMethods,
        file: file,
        context: context
    ) || declaration.memberNames.contains(where: { memberName in
        let lowercasedName = memberName.lowercased()
        return lowercasedName.contains("normalize")
            || lowercasedName.contains("config")
            || lowercasedName.contains("configuration")
            || lowercasedName.contains("requestdefinition")
            || lowercasedName.contains("startup")
            || lowercasedName.contains("launch")
            || lowercasedName.contains("context")
    })
    let hasFinalBoundaryShaping = nestedMethods.contains { declaration in
        returnsFinalProviderTransportBoundaryShape(
            declaration,
            file: file,
            context: context
        ) || declaration.parameterTypeNames.contains(where: { typeName in
            isFinalProviderTransportBoundaryShapeTypeName(
                typeName,
                file: file,
                context: context
            )
        })
    } || declaration.memberNames.contains(where: { memberName in
        let lowercasedName = memberName.lowercased()
        return lowercasedName.contains("makerequest")
            || lowercasedName.contains("buildrequest")
            || lowercasedName.contains("tourlrequest")
            || lowercasedName.contains("requestbody")
            || lowercasedName.contains("requestheaders")
            || lowercasedName.contains("responseenvelope")
    })

    switch (hasIntermediaryShaping, hasFinalBoundaryShaping) {
    case (true, true):
        return .mixed
    case (true, false):
        return .intermediary
    case (false, true):
        return .finalBoundary
    case (false, false):
        return nil
    }
}

private func hasGatewayBoundaryConfigurationOperationEvidence(
    _ declaration: ArchitectureMethodDeclaration,
    in file: ArchitectureFile
) -> Bool {
    let operationNames = Set(
        file.operationalUseOccurrences.filter { occurrence in
            occurrence.enclosingTypeName == declaration.enclosingTypeName
                && occurrence.enclosingMethodName == declaration.name
        }.map(\.baseName)
    )

    return !operationNames.intersection(boundaryConfigurationOperationNames).isEmpty
}

private func hasInlineGatewayRequestShapingEvidence(
    in file: ArchitectureFile,
    gatewayTypeName: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> Bool {
    let queryPropertyNames = Set(
        file.computedPropertyDeclarations.compactMap { declaration -> String? in
            guard declaration.enclosingTypeName == gatewayTypeName,
                  declaration.typeNames.contains("String"),
                  isLikelyGatewayOperationDefinitionMemberName(declaration.name) else {
                return nil
            }

            return declaration.name
        }
    )

    let queryStoredMemberNames = Set(
        file.storedMemberDeclarations.compactMap { declaration -> String? in
            guard declaration.enclosingTypeName == gatewayTypeName,
                  declaration.typeNames.contains("String"),
                  isLikelyGatewayOperationDefinitionMemberName(declaration.name) else {
                return nil
            }

            return declaration.name
        }
    )

    let inlineOperationDefinitionUse = file.operationalUseOccurrences.contains { occurrence in
        occurrence.enclosingTypeName == gatewayTypeName
            && (queryPropertyNames.contains(occurrence.baseName) || queryStoredMemberNames.contains(occurrence.baseName))
    }

    let methodLevelIngredientShaping = methods.contains { declaration in
        let lowercasedName = declaration.name.lowercased()

        if declaration.parameterTypeNames.filter({ $0 == "String" }).count >= 2
            && hasGatewayRequestDefinitionIngredientEvidence(declaration, context: context) {
            return true
        }

        return lowercasedName.contains("requestdefinition")
            || lowercasedName.contains("variables")
            || lowercasedName.contains("query")
            || lowercasedName.contains("operation")
    }

    let operationLiteralPresence = file.stringLiteralOccurrences.contains { occurrence in
        isLikelyGatewayOperationIdentifierLiteral(occurrence.value)
    }

    return inlineOperationDefinitionUse
        || methodLevelIngredientShaping
        || operationLiteralPresence
}

private func hasGatewayExecutionFlowEvidence(
    in file: ArchitectureFile,
    gatewayTypeName: String,
    methods: [ArchitectureMethodDeclaration]
) -> Bool {
    let hasURLRequestFlow = methods.contains { declaration in
        declaration.parameterTypeNames.contains("URLRequest")
            || declaration.returnTypeNames.contains("URLRequest")
            || declaration.parameterTypeNames.contains("HTTPURLResponse")
            || declaration.returnTypeNames.contains("HTTPURLResponse")
    }
    let hasExecutionMethod = methods.contains { declaration in
        isLikelyGatewayBoundaryExecutionMethodName(declaration.name.lowercased())
    }
    let hasPaginationEvidence = methods.contains { declaration in
        let lowercasedName = declaration.name.lowercased()
        return lowercasedName.contains("paginated") || lowercasedName.contains("pagination")
    } || file.storedMemberDeclarations.contains { declaration in
        declaration.enclosingTypeName == gatewayTypeName
            && declaration.name.lowercased().contains("cursor")
    } || file.identifierOccurrences.contains { occurrence in
        occurrence.name.lowercased().contains("cursor")
    }

    return hasURLRequestFlow || hasExecutionMethod || hasPaginationEvidence
}

private func firstInlineGatewayRequestShapingCoordinate(
    in file: ArchitectureFile,
    gatewayTypeName: String,
    methods: [ArchitectureMethodDeclaration],
    context: ProjectContext
) -> SourceCoordinate? {
    if let computedProperty = file.computedPropertyDeclarations.first(where: { declaration in
        declaration.enclosingTypeName == gatewayTypeName
            && declaration.typeNames.contains("String")
            && isLikelyGatewayOperationDefinitionMemberName(declaration.name)
    }) {
        return computedProperty.coordinate
    }

    if let storedMember = file.storedMemberDeclarations.first(where: { declaration in
        declaration.enclosingTypeName == gatewayTypeName
            && declaration.typeNames.contains("String")
            && isLikelyGatewayOperationDefinitionMemberName(declaration.name)
    }) {
        return storedMember.coordinate
    }

    return methods.first(where: { declaration in
        let lowercasedName = declaration.name.lowercased()
        return (declaration.parameterTypeNames.filter { $0 == "String" }.count >= 2
            && hasGatewayRequestDefinitionIngredientEvidence(declaration, context: context))
            || lowercasedName.contains("requestdefinition")
            || lowercasedName.contains("variables")
            || lowercasedName.contains("query")
            || lowercasedName.contains("operation")
    })?.coordinate
}

private func isLikelyNestedIntermediaryShape(
    _ declaration: ArchitectureNestedNominalDeclaration
) -> Bool {
    let intermediarySuffixes = ["Error", "Result", "Model", "Record", "Payload"]

    return declaration.inheritedTypeNames.contains("Error")
        || declaration.inheritedTypeNames.contains("LocalizedError")
        || declaration.inheritedTypeNames.contains("StructuredErrorProtocol")
        || intermediarySuffixes.contains(where: { declaration.name.hasSuffix($0) })
}

private func isLikelyGatewayRequestDefinitionShape(_ name: String) -> Bool {
    requestDefinitionShapeSuffixes.contains { name.hasSuffix($0) }
}

private func isLikelyGatewayOperationDefinitionMemberName(_ name: String) -> Bool {
    let lowercasedName = name.lowercased()
    return lowercasedName.contains("query")
        || lowercasedName.contains("mutation")
        || lowercasedName.contains("subscription")
        || lowercasedName.contains("operation")
}

private func isLikelyGatewayOperationIdentifierLiteral(_ value: String) -> Bool {
    let lowercasedValue = value.lowercased()
    return (value.hasPrefix("query ") || value.hasPrefix("mutation ") || value.hasPrefix("subscription "))
        || lowercasedValue.contains("query")
        || lowercasedValue.contains("mutation")
}

private func isLikelyGatewayBoundaryPreparationMethodName(_ name: String) -> Bool {
    name.hasPrefix("make")
        || name.hasPrefix("build")
        || name.hasPrefix("create")
        || name.hasPrefix("compose")
        || name.hasPrefix("resolve")
        || name.hasPrefix("normalize")
        || name == "fromcontract"
        || name.contains("startup")
        || name.contains("payload")
        || name.contains("requestdefinition")
        || name.contains("launchconfiguration")
        || name.contains("sandboxpolicy")
}

private func isLikelyGatewayBoundaryConfigurationMethodName(_ name: String) -> Bool {
    name.contains("config")
        || name.contains("configuration")
        || name.contains("sandbox")
        || name.contains("policy")
        || name.contains("access")
        || name.contains("approval")
        || name.contains("posture")
        || name.contains("capabilit")
        || name.contains("default")
        || name.contains("option")
}

private func isLikelyGatewayBoundaryDefinitionMethodName(_ name: String) -> Bool {
    isLikelyGatewayBoundaryPreparationMethodName(name)
        || name.contains("request")
        || name.contains("definition")
        || name.contains("payload")
        || name.contains("input")
        || name.contains("command")
        || name.contains("message")
        || name.contains("session")
        || name.contains("turn")
        || name.contains("launch")
        || name.contains("context")
        || name.contains("policy")
}

private func isLikelyGatewayBoundaryConfigurationMemberName(_ name: String) -> Bool {
    let lowercasedName = name.lowercased()
    return lowercasedName == "defaults"
        || lowercasedName.contains("config")
        || lowercasedName.contains("configuration")
        || lowercasedName.contains("sandbox")
        || lowercasedName.contains("policy")
        || lowercasedName.contains("access")
        || lowercasedName.contains("approval")
        || lowercasedName.contains("posture")
        || lowercasedName.contains("capabilit")
        || lowercasedName.contains("option")
}

private func isLikelyGatewayBoundaryDefinitionMemberName(_ name: String) -> Bool {
    let lowercasedName = name.lowercased()
    return lowercasedName.contains("query")
        || lowercasedName.contains("mutation")
        || lowercasedName.contains("subscription")
        || lowercasedName.contains("operation")
        || lowercasedName.contains("request")
        || lowercasedName.contains("definition")
        || lowercasedName.contains("payload")
        || lowercasedName.contains("command")
        || lowercasedName.contains("message")
        || lowercasedName.contains("startup")
        || lowercasedName.contains("session")
        || lowercasedName.contains("turn")
        || lowercasedName.contains("launch")
        || lowercasedName.contains("context")
        || lowercasedName.contains("policy")
}

private func isLikelyGatewayBoundaryExecutionMethodName(_ name: String) -> Bool {
    guard !isLikelyGatewayBoundaryPreparationMethodName(name) else {
        return false
    }

    let executionPrefixes = [
        "fetch",
        "load",
        "discover",
        "prepare",
        "complete",
        "cleanup",
        "validate",
        "start",
        "continue",
        "cancel",
        "schedule",
        "monitor",
        "watch",
        "launch",
        "run",
        "execute",
        "perform",
        "process",
        "send",
        "wait",
        "connect",
        "open",
        "close",
        "terminate",
        "poll",
        "stream"
    ]

    return executionPrefixes.contains(where: name.hasPrefix)
        || name.contains("response")
        || name.contains("paginated")
        || name.contains("pagination")
}

private func isLikelyImmediateTransportExecutionCallName(_ name: String) -> Bool {
    immediateTransportExecutionCallPrefixes.contains { name.hasPrefix($0) }
}

private func returnsPreparedBoundaryShape(
    _ declaration: ArchitectureMethodDeclaration,
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    guard !declaration.returnTypeNames.contains("URLRequest"),
          !declaration.returnTypeNames.contains("HTTPURLResponse") else {
        return false
    }

    if returnsRequestDefinitionTranslationType(declaration, file: file, context: context) {
        return true
    }

    return declaration.returnTypeNames.contains { typeName in
        guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
            return false
        }

        return isApplicationContractDeclaration(indexedDeclaration)
            || indexedDeclaration.roleFolder == .infrastructureTranslationModels
            || indexedDeclaration.roleFolder == .infrastructureTranslationDTOs
    }
}

private func isLikelyIntermediaryRequestDefinitionTranslationTypeName(_ name: String) -> Bool {
    isLikelyGatewayRequestDefinitionShape(name)
}

private func isLikelyBoundaryDefinitionTranslationTypeName(_ name: String) -> Bool {
    isLikelyGatewayRequestDefinitionShape(name)
        || isLikelyFinalProviderTransportCarrierTypeName(name)
}

private func hasRequestDefinitionShapingResponsibility(
    in methods: [ArchitectureMethodDeclaration],
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    hasIntermediaryRequestDefinitionShapingResponsibility(
        in: methods,
        file: file,
        context: context
    ) || methods.contains { declaration in
        returnsFinalProviderTransportBoundaryShape(
            declaration,
            file: file,
            context: context
        ) && isLikelyGatewayBoundaryDefinitionMethodName(declaration.name.lowercased())
    }
}

private func isConfigurationInputTypeName(
    _ typeName: String,
    context: ProjectContext
) -> Bool {
    guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
        return false
    }

    guard indexedDeclaration.layer == .application else {
        return false
    }

    let lowercasedName = indexedDeclaration.name.lowercased()
    return lowercasedName.contains("config")
        || lowercasedName.contains("configuration")
        || lowercasedName.contains("sandbox")
        || lowercasedName.contains("policy")
        || lowercasedName.contains("access")
        || lowercasedName.contains("approval")
        || lowercasedName.contains("posture")
        || lowercasedName.contains("capabilit")
        || lowercasedName.contains("tracker")
        || indexedDeclaration.roleFolder == .applicationContractsWorkflow
        || indexedDeclaration.roleFolder == .applicationContractsPorts
}

private func isConfigurationTranslationCarrierTypeName(
    _ typeName: String,
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    let lowercasedName = typeName.lowercased()
    guard lowercasedName.contains("config")
        || lowercasedName.contains("configuration")
        || lowercasedName.contains("sandbox")
        || lowercasedName.contains("policy")
        || lowercasedName.contains("access")
        || lowercasedName.contains("approval")
        || lowercasedName.contains("posture")
        || lowercasedName.contains("capabilit")
        || lowercasedName.contains("tracker") else {
        return false
    }

    if file.topLevelDeclarations.contains(where: {
        $0.kind != .protocol && $0.name == typeName
    }) {
        return true
    }

    guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
        return false
    }

    return indexedDeclaration.roleFolder == .infrastructureTranslationModels
}

private func isLikelyBoundaryConfigurationSourceTypeName(
    _ typeName: String,
    context: ProjectContext
) -> Bool {
    let lowercasedName = typeName.lowercased()
    if lowercasedName.contains("config")
        || lowercasedName.contains("configuration")
        || lowercasedName.contains("sandbox")
        || lowercasedName.contains("policy")
        || lowercasedName.contains("access")
        || lowercasedName.contains("approval")
        || lowercasedName.contains("posture")
        || lowercasedName.contains("capabilit")
        || lowercasedName.contains("tracker") {
        return true
    }

    guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
        return false
    }

    return isApplicationContractDeclaration(indexedDeclaration)
        && isLikelyBoundaryConfigurationCarrierTypeName(indexedDeclaration.name)
}

private func isLikelyBoundaryConfigurationCarrierTypeName(_ name: String) -> Bool {
    let lowercasedName = name.lowercased()
    return lowercasedName.contains("config")
        || lowercasedName.contains("configuration")
        || lowercasedName.contains("sandbox")
        || lowercasedName.contains("policy")
        || lowercasedName.contains("access")
        || lowercasedName.contains("approval")
        || lowercasedName.contains("posture")
        || lowercasedName.contains("capabilit")
        || lowercasedName.contains("option")
}

private func isLikelyBoundaryDefinitionCarrierTypeName(_ name: String) -> Bool {
    let lowercasedName = name.lowercased()
    if lowercasedName.contains("result")
        || lowercasedName.contains("response")
        || lowercasedName.contains("validation")
        || lowercasedName.contains("cleanup")
        || lowercasedName.contains("outcome")
        || lowercasedName.contains("state")
        || lowercasedName.contains("snapshot")
        || lowercasedName.contains("event")
        || lowercasedName.contains("error") {
        return false
    }

    return lowercasedName.contains("request")
        || lowercasedName.contains("definition")
        || lowercasedName.contains("payload")
        || lowercasedName.contains("input")
        || lowercasedName.contains("command")
        || lowercasedName.contains("message")
        || lowercasedName.contains("startup")
        || lowercasedName.contains("session")
        || lowercasedName.contains("turn")
        || lowercasedName.contains("launch")
        || lowercasedName.contains("context")
        || lowercasedName.contains("policy")
}

private func isExtractedRequestShapingTranslationModelTypeName(
    _ typeName: String,
    context: ProjectContext
) -> Bool {
    guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
        return false
    }

    guard indexedDeclaration.roleFolder == .infrastructureTranslationModels
            || indexedDeclaration.roleFolder == .infrastructureTranslationDTOs else {
        return false
    }

    let lowercasedName = indexedDeclaration.name.lowercased()
    return lowercasedName.contains("request")
        || lowercasedName.contains("query")
        || lowercasedName.contains("config")
        || lowercasedName.contains("tracker")
        || lowercasedName.contains("response")
        || lowercasedName.contains("envelope")
        || lowercasedName.contains("body")
        || lowercasedName.contains("params")
        || lowercasedName.contains("payload")
}

private func hasNonPrivateTransportOrExecutionSurface(in file: ArchitectureFile) -> Bool {
    file.methodDeclarations.contains { declaration in
        guard !declaration.isPrivateOrFileprivate else {
            return false
        }

        if declaration.parameterTypeNames.contains("URLRequest")
            || declaration.returnTypeNames.contains("URLRequest")
            || declaration.parameterTypeNames.contains("HTTPURLResponse")
            || declaration.returnTypeNames.contains("HTTPURLResponse") {
            return true
        }

        let lowercasedName = declaration.name.lowercased()
        return lowercasedName.contains("execute")
            || lowercasedName.contains("decode")
            || lowercasedName.contains("perform")
    }
}

private struct TranslationSurfaceCulprit {
    let name: String
    let coordinate: SourceCoordinate?
}

private func finalTransportProviderShapeDiagnostics(
    in file: ArchitectureFile,
    context: ProjectContext
) -> [TranslationSurfaceCulprit] {
    let topLevelConcreteTypeNames = Set(
        file.topLevelDeclarations.compactMap { declaration -> String? in
            guard declaration.kind != .protocol else {
                return nil
            }

            return declaration.name
        }
    )

    var culprits: [TranslationSurfaceCulprit] = file.methodDeclarations.compactMap { declaration in
        guard topLevelConcreteTypeNames.contains(declaration.enclosingTypeName),
              !declaration.isPrivateOrFileprivate,
              returnsFinalProviderTransportBoundaryShape(
                declaration,
                file: file,
                context: context
              ) else {
            return nil
        }

        return TranslationSurfaceCulprit(
            name: "\(declaration.enclosingTypeName).\(declaration.name)",
            coordinate: declaration.coordinate
        )
    }

    culprits.append(contentsOf: file.computedPropertyDeclarations.compactMap { declaration in
        guard topLevelConcreteTypeNames.contains(declaration.enclosingTypeName),
              declaration.typeNames.contains(where: { typeName in
                  isFinalProviderTransportBoundaryShapeTypeName(
                    typeName,
                    file: file,
                    context: context
                  )
              }) else {
            return nil
        }

        return TranslationSurfaceCulprit(
            name: "\(declaration.enclosingTypeName).\(declaration.name)",
            coordinate: declaration.coordinate
        )
    })

    return culprits
}

private func returnsFinalProviderTransportBoundaryShape(
    _ declaration: ArchitectureMethodDeclaration,
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    declaration.returnTypeNames.contains { typeName in
        isFinalProviderTransportBoundaryShapeTypeName(
            typeName,
            file: file,
            context: context
        )
    }
}

private func isFinalProviderTransportBoundaryShapeTypeName(
    _ typeName: String,
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    if typeName == "URLRequest" || typeName == "HTTPURLResponse" {
        return true
    }

    if let localDeclaration = file.topLevelDeclarations.first(where: {
        $0.kind != .protocol && $0.name == typeName
    }) {
        return isLikelyLocalDTOTransportProviderShape(localDeclaration)
    }

    guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
        return false
    }

    return indexedDeclaration.roleFolder == .infrastructureTranslationDTOs
}

private func isLikelyLocalDTOTransportProviderShape(
    _ declaration: ArchitectureTopLevelDeclaration
) -> Bool {
    declaration.name.hasSuffix("DTO")
        || declaration.inheritedTypeNames.contains("Encodable")
        || declaration.inheritedTypeNames.contains("Decodable")
        || declaration.inheritedTypeNames.contains("Codable")
}

private func isLikelyFinalProviderTransportCarrierTypeName(_ name: String) -> Bool {
    let lowercasedName = name.lowercased()
    return lowercasedName.contains("request")
        || lowercasedName.contains("response")
        || lowercasedName.contains("envelope")
        || lowercasedName.contains("body")
        || lowercasedName.contains("params")
        || lowercasedName.contains("payload")
        || lowercasedName.contains("data")
}

private func hasDTOIntermediaryOrNormalizationViolation(
    _ declaration: ArchitectureMethodDeclaration,
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    hasConfigurationNormalizationResponsibility(
        in: [declaration],
        file: file,
        context: context
    ) || hasIntermediaryRequestDefinitionShapingResponsibility(
        in: [declaration],
        file: file,
        context: context
    )
}

private func hasDTOExecutionOrchestrationViolation(
    _ declaration: ArchitectureMethodDeclaration
) -> Bool {
    isLikelyGatewayBoundaryExecutionMethodName(declaration.name.lowercased())
}

private func isApplicationContractDeclaration(_ declaration: IndexedDeclaration) -> Bool {
    guard declaration.layer == .application else {
        return false
    }

    switch declaration.roleFolder {
    case .applicationContractsCommands,
            .applicationContractsPorts,
            .applicationContractsWorkflow:
        return declaration.name.hasSuffix("Contract")
    default:
        return false
    }
}

private func isInfrastructureErrorDeclaration(_ declaration: IndexedDeclaration) -> Bool {
    guard declaration.layer == .infrastructure else {
        return false
    }

    return declaration.roleFolder == .infrastructureErrors
        || declaration.inheritedTypeNames.contains("StructuredErrorProtocol")
        || declaration.inheritedTypeNames.contains("Error")
        || declaration.inheritedTypeNames.contains("LocalizedError")
}

private func hasPublicRawSyntaxEntrypointUsingNestedParser(
    in file: ArchitectureFile,
    adapterTypeName: String
) -> Bool {
    file.methodDeclarations.contains { declaration in
        declaration.enclosingTypeName == adapterTypeName
            && declaration.isPublicOrOpen
            && acceptsRawSyntaxInput(declaration)
    }
}

private func hasNonPublicParserModelFlowHelper(
    in file: ArchitectureFile,
    adapterTypeName: String,
    parserModelShapeNames: Set<String>
) -> Bool {
    file.methodDeclarations.contains { declaration in
        guard declaration.enclosingTypeName == adapterTypeName,
              !declaration.isPublicOrOpen else {
            return false
        }

        return declaration.parameterTypeNames.contains(where: parserModelShapeNames.contains)
            || declaration.returnTypeNames.contains(where: parserModelShapeNames.contains)
    }
}

private func hasNonPublicInwardProjectionHelper(
    in file: ArchitectureFile,
    adapterTypeName: String,
    parserModelShapeNames: Set<String>,
    context: ProjectContext
) -> Bool {
    file.methodDeclarations.contains { declaration in
        guard declaration.enclosingTypeName == adapterTypeName,
              !declaration.isPublicOrOpen,
              declaration.returnTypeNames.contains(where: parserModelShapeNames.contains),
              acceptsInwardProjectionInput(declaration, context: context) else {
            return false
        }

        return true
    }
}

private func acceptsRawSyntaxInput(_ declaration: ArchitectureMethodDeclaration) -> Bool {
    declaration.parameterTypeNames.contains("String")
}

private func acceptsInwardProjectionInput(
    _ declaration: ArchitectureMethodDeclaration,
    context: ProjectContext
) -> Bool {
    declaration.parameterTypeNames.contains { typeName in
        if typeName == "Date" {
            return true
        }

        guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
            return false
        }

        return indexedDeclaration.layer == .domain
            || isApplicationContractDeclaration(indexedDeclaration)
    }
}

private func returnsParserModelTranslationType(
    _ declaration: ArchitectureMethodDeclaration,
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    guard declaration.hasExplicitReturnType, !declaration.returnsVoidLike else {
        return false
    }

    return declaration.returnTypeNames.contains { typeName in
        isParserModelTranslationTypeName(typeName, file: file, context: context)
    }
}

private func isParserModelTranslationTypeName(
    _ typeName: String,
    file: ArchitectureFile,
    context: ProjectContext
) -> Bool {
    if file.topLevelDeclarations.contains(where: {
        $0.kind != .protocol && $0.name == typeName && isParserModelTranslationShapeName(typeName)
    }) {
        return true
    }

    guard let indexedDeclaration = context.uniqueDeclaration(named: typeName) else {
        return false
    }

    return indexedDeclaration.roleFolder == .infrastructureTranslationModels
        && isParserModelTranslationShapeName(typeName)
}

private func isParserTranslationShape(
    _ declaration: ArchitectureNestedNominalDeclaration
) -> Bool {
    isParserTranslationShapeName(declaration.name)
        || declaration.memberNames.contains(where: isParseLikeOperationName)
}

private func isParserModelCarrierShape(
    _ declaration: ArchitectureNestedNominalDeclaration
) -> Bool {
    isParserModelCarrierShapeName(declaration.name)
}

private func isParserTranslationShapeName(_ name: String) -> Bool {
    parserTranslationShapeKeywords.contains { name.localizedCaseInsensitiveContains($0) }
}

private func isParserModelCarrierShapeName(_ name: String) -> Bool {
    parserModelCarrierKeywords.contains { name.hasSuffix($0) }
}

private func isParserModelTranslationShapeName(_ name: String) -> Bool {
    isParserTranslationShapeName(name) || isParserModelCarrierShapeName(name)
}

private func isParseLikeOperationName(_ name: String) -> Bool {
    name == "parse"
        || name == "tokenize"
        || name == "lex"
        || name.hasPrefix("parse")
}

private let parserTranslationShapeKeywords = ["Parser", "Lexer", "Tokenizer"]
private let parserModelCarrierKeywords = ["Node", "Expression", "Token", "AST", "Context", "Value"]
private let boundaryConfigurationOperationNames: Set<String> = [
    "trimmingCharacters",
    "dictionaryValue",
    "arrayValue",
    "boolValue",
    "stringValue",
    "integerValue",
    "doubleValue",
    "mapValues"
]
private let requestDefinitionShapeSuffixes = [
    "Configuration",
    "Config",
    "RequestDefinition",
    "RequestModel",
    "RequestPayload",
    "RequestContext"
]

private let immediateTransportExecutionCallPrefixes = [
    "send",
    "write",
    "execute",
    "perform",
    "dispatch",
    "emit",
    "transmit",
    "stream",
    "post",
    "put",
    "patch",
    "delete",
    "upload"
]

private let gatewayTransportCarrierTypeNames: Set<String> = [
    "URLRequest",
    "URLComponents",
    "URLQueryItem"
]

private let primitiveOrRawTechnicalTypeNames: Set<String> = [
    "String",
    "Substring",
    "Bool",
    "Int",
    "Int8",
    "Int16",
    "Int32",
    "Int64",
    "UInt",
    "UInt8",
    "UInt16",
    "UInt32",
    "UInt64",
    "Double",
    "Float",
    "Decimal",
    "Date",
    "TimeInterval",
    "Data",
    "URL",
    "UUID",
    "Any",
    "AnyHashable",
    "Error",
    "URLRequest",
    "HTTPURLResponse"
]

private let containerTypeNames: Set<String> = [
    "Array",
    "Set",
    "Dictionary",
    "Optional"
]

private let rawExtractionOrTranslationNameFragments = [
    "parse",
    "extract",
    "decode",
    "normalize",
    "build",
    "assemble",
    "encode",
    "map",
    "project",
    "coerce",
    "convert"
]

private let evaluatorTranslationOperationNameFragments = [
    "parse",
    "extract",
    "decode",
    "normalize",
    "encode",
    "assemble",
    "coerce",
    "convert"
]

private let portAdapterRenderIntentNameFragments = [
    "render",
    "format",
    "interpret",
    "output",
    "escape",
    "join",
    "template"
]

private let portAdapterRenderOutputTypeNames: Set<String> = [
    "String",
    "Data"
]

private let inlineNormalizationPreparationNameFragments = [
    "normalize",
    "normaliz",
    "prepare",
    "canonical",
    "sanitize",
    "standard",
    "default",
    "fallback",
    "coerce",
    "expand",
    "trim",
    "clean"
]

private let inlineNormalizationPreparationOperationNames: Set<String> = [
    "trimmingCharacters",
    "lowercased",
    "uppercased",
    "replacingOccurrences",
    "appendingPathComponent",
    "expandingTildeInPath",
    "resolvingSymlinksInPath",
    "standardized",
    "mapValues",
    "filter",
    "compactMap",
    "flatMap"
]

private let inlineNormalizationPreparationOperationFragments = [
    "normalize",
    "canonical",
    "sanitize",
    "standard",
    "default",
    "fallback",
    "coerce",
    "expand",
    "trim",
    "clean"
]

private let inlineNormalizationPreparationBoundaryContextFragments = [
    "config",
    "configuration",
    "path",
    "request",
    "input",
    "payload",
    "param",
    "query",
    "header",
    "body",
    "command",
    "message",
    "session",
    "turn",
    "launch",
    "startup",
    "context",
    "workspace",
    "file",
    "url",
    "env",
    "option",
    "policy"
]

private let inlineNormalizationPreparationOutputTypeNameFragments = [
    "model",
    "payload",
    "record",
    "request",
    "response",
    "envelope",
    "body",
    "params",
    "input",
    "context",
    "config",
    "configuration",
    "path",
    "header",
    "command",
    "message",
    "session",
    "turn",
    "launch",
    "startup",
    "url",
    "dto"
]

private let inlineNormalizationPreparationDecisionOutputFragments = [
    "decision",
    "selection",
    "selector",
    "classification",
    "classifier",
    "compatibility",
    "allowance",
    "resolver",
    "route",
    "dispatch"
]

private let inlineNormalizationPreparationParserFragments = [
    "parse",
    "parser",
    "token",
    "tokenize",
    "lexer",
    "lex",
    "decode"
]

private let inlineNormalizationPreparationExecutionFragments = [
    "send",
    "read",
    "write",
    "wait",
    "stream",
    "load",
    "save",
    "retry",
    "emit",
    "fetch",
    "execute",
    "perform",
    "run",
    "start",
    "continue",
    "cancel",
    "dispatch",
    "connect",
    "open",
    "close",
    "terminate",
    "poll",
    "monitor",
    "watch",
    "respond"
]

private let inlineNormalizationPreparationGatewayControlFragments = [
    "responseid",
    "responseidentifier",
    "responsecorrelation",
    "timeout",
    "deadline",
    "loop",
    "exit",
    "cursor",
    "pagination",
    "paginated",
    "lifecycle"
]

private let executionLikeOperationNameFragments = [
    "send",
    "read",
    "write",
    "wait",
    "stream",
    "load",
    "save",
    "retry",
    "emit",
    "fetch",
    "execute",
    "perform",
    "run",
    "start",
    "continue",
    "cancel",
    "dispatch"
]

private let excludedGatewayDecisionControlNameFragments = [
    "responseid",
    "responseidentifier",
    "timeout",
    "deadline",
    "exit",
    "loop",
    "continu",
    "cancel",
    "stream",
    "wait",
    "emit"
]

private let allowedDecisionSupportOperationNames: Set<String> = [
    "contains",
    "subscript",
    "first",
    "last",
    "allSatisfy"
]

private let compatibilityEvaluationOperationNames: Set<String> = [
    "contains",
    "allSatisfy"
]

private let disallowedGatewayCompatibilityOperationNames: Set<String> = [
    "send",
    "read",
    "write",
    "wait",
    "stream",
    "load",
    "save",
    "retry",
    "fetch",
    "execute",
    "perform",
    "run",
    "continue",
    "cancel",
    "dispatch"
]

private let gatewayCompatibilityControlFragments = [
    "responseid",
    "responseidentifier",
    "timeout",
    "deadline",
    "exit",
    "loop"
]

private let branchBoundaryWorkOperationNameFragments = [
    "respond"
]

private let gatewayInteractionDispatchControlNameFragments = [
    "responseid",
    "responseidentifier",
    "timeout",
    "deadline",
    "exit",
    "loop",
    "cursor",
    "pagination",
    "paginated"
]
