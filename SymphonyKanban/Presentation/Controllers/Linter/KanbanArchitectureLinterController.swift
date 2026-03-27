import Foundation

struct KanbanArchitectureLinterController {
    private let linterService: KanbanArchitectureLinterService
    private let renderer: KanbanArchitectureLinterRenderer

    init(
        linterService: KanbanArchitectureLinterService,
        renderer: KanbanArchitectureLinterRenderer
    ) {
        self.linterService = linterService
        self.renderer = renderer
    }

    func run(arguments: [String]) -> Int32 {
        do {
            let command = try KanbanArchitectureLinterCommandDTO(arguments: arguments)
            let result = try linterService.execute(command.workflowContract())
            return renderer.render(result)
        } catch {
            return renderer.renderError(error)
        }
    }
}
