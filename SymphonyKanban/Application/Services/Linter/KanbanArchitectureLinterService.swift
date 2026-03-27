import Foundation

public struct KanbanArchitectureLinterService {
    private let lintProjectUseCase: LintProjectUseCase

    init(lintProjectUseCase: LintProjectUseCase) {
        self.lintProjectUseCase = lintProjectUseCase
    }

    public func execute(
        _ workflow: KanbanArchitectureLintWorkflowContract
    ) throws -> KanbanArchitectureLintResultContract {
        try lint(normalizedWorkflow(workflow))
    }

    private func normalizedWorkflow(
        _ workflow: KanbanArchitectureLintWorkflowContract
    ) -> KanbanArchitectureLintWorkflowContract {
        KanbanArchitectureLintWorkflowContract(
            rootURL: workflow.rootURL.standardizedFileURL,
            diagnosticRulePrefix: workflow.diagnosticRulePrefix
        )
    }

    private func lint(
        _ workflow: KanbanArchitectureLintWorkflowContract
    ) throws -> KanbanArchitectureLintResultContract {
        try lintProjectUseCase.execute(workflow)
    }
}
