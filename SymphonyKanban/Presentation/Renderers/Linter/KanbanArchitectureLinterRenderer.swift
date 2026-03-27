import Foundation

struct KanbanArchitectureLinterRenderer {
    func render(_ result: KanbanArchitectureLintResultContract) -> Int32 {
        result.diagnostics.forEach { diagnostic in
            print(renderedDiagnostic(diagnostic))
        }
        return result.diagnostics.isEmpty ? EXIT_SUCCESS : EXIT_FAILURE
    }

    func renderError(_ error: any Error) -> Int32 {
        if let structuredError = error as? any StructuredErrorProtocol {
            fputs("\(structuredError.message)\n", stderr)
            if let details = structuredError.details, !details.isEmpty {
                fputs("\(details)\n", stderr)
            }
            return EXIT_FAILURE
        }

        fputs("\(error.localizedDescription)\n", stderr)
        return EXIT_FAILURE
    }

    private func renderedDiagnostic(_ diagnostic: ArchitectureDiagnostic) -> String {
        "\(diagnostic.path):\(diagnostic.line):\(diagnostic.column): [\(diagnostic.ruleID)] \(diagnostic.message)"
    }
}
