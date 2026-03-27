import Foundation

protocol ArchitectureLintPortProtocol {
    func lintProject(at rootURL: URL) throws -> KanbanArchitectureLintResultContract
}
