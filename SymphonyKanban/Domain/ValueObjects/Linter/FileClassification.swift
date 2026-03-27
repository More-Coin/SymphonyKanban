import Foundation

public struct FileClassification: Sendable, Equatable {
    public let repoRelativePath: String
    public let layer: ArchitectureLayer
    public let roleFolder: RoleFolder
    public let pathComponents: [String]
    public let fileName: String
    public let fileStem: String

    public var isDomain: Bool { layer == .domain }
    public var isApplication: Bool { layer == .application }
    public var isInfrastructure: Bool { layer == .infrastructure }
    public var isPresentation: Bool { layer == .presentation }
    public var isTestFile: Bool { layer == .tests }
    public var testRootComponent: String? { pathComponents.first }
    public var isLegacyTestFile: Bool { testRootComponent == "Tests" }
    public var isCanonicalRepoTestFile: Bool { testRootComponent == "SymphonyKanbanTests" }
    public var isUITestFile: Bool {
        if let root = testRootComponent {
            return root.hasSuffix("UITests")
        }
        return false
    }
    public var isPolicyFile: Bool {
        isDomain && (roleFolder == .domainPolicies || fileStem.hasSuffix("Policy"))
    }
    public var isControllerFile: Bool { roleFolder == .presentationControllers }
    public var isPresentationDTOFile: Bool { roleFolder == .presentationDTOs }
    public var isPresentationPresenterFile: Bool { roleFolder == .presentationPresenters }
    public var isPresentationRendererFile: Bool { roleFolder == .presentationRenderers }
    public var isPresentationMiddlewareFile: Bool { roleFolder == .presentationMiddleware }
    public var isPresentationErrorFile: Bool { roleFolder == .presentationErrors }
    public var isPresentationViewModelFile: Bool { roleFolder == .presentationViewModels }
    public var isPresentationViewFile: Bool { roleFolder == .presentationViews }
    public var isPresentationStyleFile: Bool { roleFolder == .presentationStyles }
    public var isAppEntrypointFile: Bool { roleFolder == .appEntrypoint }
    public var isAppBootstrapFile: Bool { roleFolder == .appBootstrap }
    public var isAppConfigurationFile: Bool { roleFolder == .appConfiguration }
    public var isAppRuntimeFile: Bool { roleFolder == .appRuntime }
    public var isAppDependencyInjectionFile: Bool { roleFolder == .appDependencyInjection }
    public var isServiceFile: Bool {
        isApplication && (roleFolder == .applicationServices || fileStem.hasSuffix("Service"))
    }
    public var isRepositoryProtocolFile: Bool {
        isDomain && roleFolder == .domainProtocols && fileStem.hasSuffix("RepositoryProtocol")
    }
    public var isDomainErrorFile: Bool { roleFolder == .domainErrors }
    public var isDomainProtocolFile: Bool {
        isDomain && roleFolder == .domainProtocols
    }
    public var isPortProtocolFile: Bool {
        isApplication && roleFolder == .applicationPortsProtocols
    }
    public var isApplicationErrorFile: Bool { roleFolder == .applicationErrors }
    public var isApplicationPortProtocolFile: Bool { roleFolder == .applicationPortsProtocols }
    public var isApplicationCommandContractFile: Bool { roleFolder == .applicationContractsCommands }
    public var isApplicationContractPortFile: Bool { roleFolder == .applicationContractsPorts }
    public var isApplicationWorkflowContractFile: Bool { roleFolder == .applicationContractsWorkflow }
    public var isApplicationContractFile: Bool {
        isApplicationCommandContractFile || isApplicationContractPortFile || isApplicationWorkflowContractFile
    }
    public var isApplicationServiceFile: Bool { roleFolder == .applicationServices }
    public var isApplicationStateTransitionFile: Bool { roleFolder == .applicationStateTransitions }
    public var isApplicationUseCaseFile: Bool { roleFolder == .applicationUseCases }
    public var isApplicationServicesRole: Bool { roleFolder == .applicationServices }
    public var isInfrastructureRepositoryFile: Bool { roleFolder == .infrastructureRepositories }
    public var isInfrastructureGatewayFile: Bool { roleFolder == .infrastructureGateways }
    public var isInfrastructurePortAdapterFile: Bool { roleFolder == .infrastructurePortAdapters }
    public var isInfrastructureEvaluatorFile: Bool { roleFolder == .infrastructureEvaluators }
    public var isInfrastructureTranslationModelFile: Bool { roleFolder == .infrastructureTranslationModels }
    public var isInfrastructureTranslationDTOFile: Bool { roleFolder == .infrastructureTranslationDTOs }
    public var isInfrastructureTranslationFile: Bool {
        isInfrastructureTranslationModelFile || isInfrastructureTranslationDTOFile
    }
    public var isInfrastructureErrorFile: Bool { roleFolder == .infrastructureErrors }
    public var isInfrastructureAdapterRole: Bool {
        isInfrastructureRepositoryFile || isInfrastructureGatewayFile || isInfrastructurePortAdapterFile
    }

    public init(
        repoRelativePath: String,
        layer: ArchitectureLayer,
        roleFolder: RoleFolder,
        pathComponents: [String],
        fileName: String,
        fileStem: String
    ) {
        self.repoRelativePath = repoRelativePath
        self.layer = layer
        self.roleFolder = roleFolder
        self.pathComponents = pathComponents
        self.fileName = fileName
        self.fileStem = fileStem
    }
}
