import Foundation

public enum SymphonyCLIEntrypoint {
    public static func run(arguments: [String]) -> Int32 {
        SymphonyCLIDI
            .makeHostRuntime()
            .run(arguments: arguments)
    }
}
