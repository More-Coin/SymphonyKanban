import Foundation

public struct SymphonyStartupCommandDTO {
    public let explicitWorkflowPath: String?
    public let currentWorkingDirectoryPath: String

    public init(
        arguments: [String],
        currentWorkingDirectoryPath: String = FileManager.default.currentDirectoryPath
    ) throws {
        let userArguments = Array(arguments.dropFirst())
        guard userArguments.count <= 1 else {
            throw SymphonyStartupPresentationError.invalidArguments
        }

        self.explicitWorkflowPath = userArguments.first
        self.currentWorkingDirectoryPath = currentWorkingDirectoryPath
    }

    public func commandContract() -> SymphonyStartupCommandContract {
        SymphonyStartupCommandContract(
            explicitWorkflowPath: explicitWorkflowPath,
            currentWorkingDirectoryPath: currentWorkingDirectoryPath
        )
    }
}
