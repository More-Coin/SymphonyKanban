struct LintProjectUseCase {
    private let lintPort: any ArchitectureLintPortProtocol

    init(lintPort: any ArchitectureLintPortProtocol) {
        self.lintPort = lintPort
    }

    func execute(_ workflow: KanbanArchitectureLintWorkflowContract) throws -> KanbanArchitectureLintResultContract {
        let result = try lintPort.lintProject(at: workflow.rootURL)
        guard let diagnosticRulePrefix = workflow.diagnosticRulePrefix else {
            return result
        }

        let filteredDiagnostics = result.diagnostics.filter { diagnostic in
            diagnostic.ruleID.hasPrefix(diagnosticRulePrefix)
        }
        return KanbanArchitectureLintResultContract(diagnostics: filteredDiagnostics)
    }
}
