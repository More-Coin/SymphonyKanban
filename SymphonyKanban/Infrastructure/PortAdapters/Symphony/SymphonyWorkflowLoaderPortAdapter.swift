import Foundation

public struct SymphonyWorkflowLoaderPortAdapter: SymphonyWorkflowLoaderPortProtocol {
    private let fileManager: FileManager
    private let workflowPathModel: SymphonyWorkflowPathModel
    private let workflowFrontMatterParser: SymphonyWorkflowFrontMatterParser

    public init(
        fileManager: FileManager = .default,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.fileManager = fileManager
        self.workflowPathModel = SymphonyWorkflowPathModel(environment: environment)
        self.workflowFrontMatterParser = SymphonyWorkflowFrontMatterParser()
    }

    public func loadWorkflow(
        using request: SymphonyWorkflowConfigurationRequestContract
    ) throws -> SymphonyWorkflowDefinitionContract {
        let resolvedPath = workflowPathModel.fromContract(request)
        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: resolvedPath, isDirectory: &isDirectory),
              !isDirectory.boolValue,
              fileManager.isReadableFile(atPath: resolvedPath) else {
            throw SymphonyWorkflowInfrastructureError.missingWorkflowFile(path: resolvedPath)
        }

        let source: String
        do {
            source = try String(contentsOfFile: resolvedPath, encoding: .utf8)
        } catch {
            throw SymphonyWorkflowInfrastructureError.missingWorkflowFile(path: resolvedPath)
        }

        let (config, promptTemplate) = try parseWorkflow(source: source)
        return SymphonyWorkflowDefinitionContract(
            resolvedPath: resolvedPath,
            config: config,
            promptTemplate: promptTemplate
        )
    }

    private func parseWorkflow(
        source: String
    ) throws -> ([String: SymphonyConfigValueContract], String) {
        let parsed = try workflowFrontMatterParser.parse(source)
        return (parsed.config, parsed.promptTemplate)
    }
}
