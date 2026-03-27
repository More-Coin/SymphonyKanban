import Foundation

struct KanbanArchitectureLinterCommandDTO {
    let rootURL: URL
    let diagnosticRulePrefix: String?

    init(arguments: [String]) throws {
        let userArguments = Array(arguments.dropFirst())
        if userArguments.contains("--help") || userArguments.contains("-h") {
            throw KanbanArchitectureLinterPresentationError.invalidArguments
        }

        var rootPath = FileManager.default.currentDirectoryPath
        var diagnosticRulePrefix: String?
        var index = 0

        while index < userArguments.count {
            let argument = userArguments[index]
            switch argument {
            case "--scope":
                let valueIndex = index + 1
                guard userArguments.indices.contains(valueIndex) else {
                    throw KanbanArchitectureLinterPresentationError.invalidArguments
                }
                switch userArguments[valueIndex] {
                case "tests":
                    diagnosticRulePrefix = "tests."
                default:
                    throw KanbanArchitectureLinterPresentationError.invalidArguments
                }
                index += 2

            default:
                guard !argument.hasPrefix("--"), rootPath == FileManager.default.currentDirectoryPath else {
                    throw KanbanArchitectureLinterPresentationError.invalidArguments
                }
                rootPath = argument
                index += 1
            }
        }

        self.rootURL = URL(fileURLWithPath: rootPath, isDirectory: true)
        self.diagnosticRulePrefix = diagnosticRulePrefix
    }

    func workflowContract() -> KanbanArchitectureLintWorkflowContract {
        KanbanArchitectureLintWorkflowContract(
            rootURL: rootURL,
            diagnosticRulePrefix: diagnosticRulePrefix
        )
    }
}
