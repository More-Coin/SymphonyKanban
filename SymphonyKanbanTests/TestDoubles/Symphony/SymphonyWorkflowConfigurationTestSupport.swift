import Foundation
@testable import SymphonyKanban

enum SymphonyWorkflowConfigurationTestSupport {
    static func makeUseCase(
        environment: [String: String] = [:]
    ) -> ResolveSymphonyWorkflowConfigurationUseCase {
        ResolveSymphonyWorkflowConfigurationUseCase(
            workflowLoaderPort: SymphonyWorkflowLoaderPortAdapter(environment: environment),
            configResolverPort: SymphonyConfigResolverPortAdapter(environment: environment)
        )
    }

    static func makeWorkflowFile(
        named fileName: String,
        contents: String
    ) throws -> URL {
        let directoryURL = temporaryDirectory()
        let fileURL = directoryURL.appendingPathComponent(fileName)
        try contents.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    static func temporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
