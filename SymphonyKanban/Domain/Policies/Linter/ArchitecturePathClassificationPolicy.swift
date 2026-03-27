import Foundation

public struct ArchitecturePathClassificationPolicy {
    public init() {}

    public func classify(repoRelativePath: String) -> FileClassification {
        let path = repoRelativePath.replacingOccurrences(of: "\\", with: "/")
        let components = path.split(separator: "/").map(String.init)
        let fileName = components.last ?? path
        let fileStem = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent

        let (layer, layerIndex) = detectLayer(in: components)
        let roleFolder = detectRoleFolder(layer: layer, layerIndex: layerIndex, components: components, fileStem: fileStem)

        return FileClassification(
            repoRelativePath: path,
            layer: layer,
            roleFolder: roleFolder,
            pathComponents: components,
            fileName: fileName,
            fileStem: fileStem
        )
    }

    private func detectLayer(in components: [String]) -> (ArchitectureLayer, Int?) {
        if components.contains(where: { $0 == "Tests" || $0.hasSuffix("Tests") || $0.hasSuffix("UITests") }) {
            return (.tests, nil)
        }
        if let index = components.firstIndex(of: "Domain") {
            return (.domain, index)
        }
        if let index = components.firstIndex(of: "Application") {
            return (.application, index)
        }
        if let index = components.firstIndex(of: "Infrastructure") {
            return (.infrastructure, index)
        }
        if let index = components.firstIndex(of: "Presentation") {
            return (.presentation, index)
        }
        if let index = components.firstIndex(of: "App") {
            return (.app, index)
        }
        return (.other, nil)
    }

    private func detectRoleFolder(
        layer: ArchitectureLayer,
        layerIndex: Int?,
        components: [String],
        fileStem: String
    ) -> RoleFolder {
        guard let layerIndex else {
            return .none
        }

        let next = component(after: layerIndex, in: components)
        let afterNext = component(after: layerIndex + 1, in: components)

        switch layer {
        case .domain:
            switch next {
            case "Protocols":
                return .domainProtocols
            case "Policies":
                return .domainPolicies
            case "Errors":
                return .domainErrors
            default:
                return .none
            }

        case .application:
            switch next {
            case "Contracts":
                switch afterNext {
                case "Commands":
                    return .applicationContractsCommands
                case "Ports":
                    return .applicationContractsPorts
                case "Workflow":
                    return .applicationContractsWorkflow
                default:
                    return .none
                }
            case "Errors":
                return .applicationErrors
            case "Ports":
                if afterNext == "Protocols" {
                    return .applicationPortsProtocols
                }
                return .none
            case "StateTransitions":
                return .applicationStateTransitions
            case "UseCases":
                return .applicationUseCases
            case "Services":
                return .applicationServices
            default:
                return .none
            }

        case .infrastructure:
            switch next {
            case "Repositories":
                return .infrastructureRepositories
            case "Gateways":
                return .infrastructureGateways
            case "PortAdapters":
                return .infrastructurePortAdapters
            case "Evaluators":
                return .infrastructureEvaluators
            case "Translation":
                switch afterNext {
                case "Models":
                    return .infrastructureTranslationModels
                case "DTOs":
                    return .infrastructureTranslationDTOs
                default:
                    return .none
                }
            case "Errors":
                return .infrastructureErrors
            default:
                return .none
            }

        case .presentation:
            switch next {
            case "Controllers":
                return .presentationControllers
            case "Routes":
                return .presentationRoutes
            case "DTOs":
                return .presentationDTOs
            case "Presenters":
                return .presentationPresenters
            case "Renderers":
                return .presentationRenderers
            case "Middleware":
                return .presentationMiddleware
            case "Errors":
                return .presentationErrors
            case "ViewModels":
                return .presentationViewModels
            case "Views":
                return .presentationViews
            case "Styles":
                return .presentationStyles
            default:
                return .none
            }

        case .ui:
            return .none

        case .app:
            switch next {
            case "Configuration":
                return .appConfiguration
            case "Runtime":
                return .appRuntime
            case "DependencyInjection":
                return .appDependencyInjection
            default:
                switch fileStem.lowercased() {
                case "main":
                    return .appEntrypoint
                case "bootstrap", "configure":
                    return .appBootstrap
                default:
                    return .none
                }
            }

        case .tests, .other:
            return .none
        }
    }

    private func component(after index: Int, in components: [String]) -> String? {
        let nextIndex = index + 1
        guard components.indices.contains(nextIndex) else {
            return nil
        }
        return components[nextIndex]
    }
}
