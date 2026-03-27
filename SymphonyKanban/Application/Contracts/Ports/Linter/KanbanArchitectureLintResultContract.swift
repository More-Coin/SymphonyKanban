
public struct KanbanArchitectureLintResultContract {
    public let diagnostics: [ArchitectureDiagnostic]

    public init(diagnostics: [ArchitectureDiagnostic]) {
        self.diagnostics = diagnostics
    }
}
