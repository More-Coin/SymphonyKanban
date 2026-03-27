import Foundation

public enum RoleFolder: String, Sendable {
    case domainProtocols
    case domainPolicies
    case domainErrors
    case applicationContractsCommands
    case applicationContractsPorts
    case applicationContractsWorkflow
    case applicationErrors
    case applicationPortsProtocols
    case applicationServices
    case applicationStateTransitions
    case applicationUseCases
    case infrastructureRepositories
    case infrastructureGateways
    case infrastructurePortAdapters
    case infrastructureEvaluators
    case infrastructureTranslationModels
    case infrastructureTranslationDTOs
    case infrastructureErrors
    case presentationControllers
    case presentationRoutes
    case presentationDTOs
    case presentationPresenters
    case presentationRenderers
    case presentationMiddleware
    case presentationErrors
    case presentationViewModels
    case presentationViews
    case presentationStyles
    case appEntrypoint
    case appBootstrap
    case appConfiguration
    case appRuntime
    case appDependencyInjection
    case none
}
