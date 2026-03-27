public protocol ArchitecturePolicyProtocol: Sendable {
    func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic]
}
