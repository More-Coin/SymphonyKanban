import Foundation

public enum KanbanArchitectureLinterCLIEntrypoint {
    public static func run(arguments: [String]) -> Int32 {
        KanbanArchitectureLinterCLIDI
            .makeController()
            .run(arguments: arguments)
    }
}
