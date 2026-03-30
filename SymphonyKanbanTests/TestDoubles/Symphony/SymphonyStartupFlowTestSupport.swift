import Foundation
@testable import SymphonyKanban

enum SymphonyStartupFlowTestSupport {
    private static let processMutationLock = NSRecursiveLock()

    static func makeController(
        environment: [String: String] = [:],
        trackerAuthPort: any SymphonyTrackerAuthPortProtocol = TrackerAuthPortSpy(),
        workspaceTrackerBindingPort: any SymphonyWorkspaceTrackerBindingPortProtocol = WorkspaceTrackerBindingPortSpy()
    ) -> SymphonyStartupController {
        SymphonyStartupController(
            startupService: makeStartupService(
                environment: environment,
                trackerAuthPort: trackerAuthPort,
                workspaceTrackerBindingPort: workspaceTrackerBindingPort
            ),
            renderer: SymphonyStartupRenderer()
        )
    }

    static func makeStartupService(
        environment: [String: String] = [:],
        trackerAuthPort: any SymphonyTrackerAuthPortProtocol = TrackerAuthPortSpy(),
        workspaceTrackerBindingPort: any SymphonyWorkspaceTrackerBindingPortProtocol = WorkspaceTrackerBindingPortSpy()
    ) -> SymphonyStartupService {
        let resolveWorkflowConfigurationUseCase = ResolveSymphonyWorkflowConfigurationUseCase(
            workflowLoaderPort: SymphonyWorkflowLoaderPortAdapter(environment: environment),
            configResolverPort: SymphonyConfigResolverPortAdapter(environment: environment)
        )
        let validateStartupConfigurationUseCase = ValidateSymphonyStartupConfigurationUseCase(
            startupConfigurationValidatorPort: ValidateSymphonyStartupConfigurationPortAdapter()
        )
        return SymphonyStartupService(
            workspaceBindingResolutionService: SymphonyWorkspaceBindingResolutionService(
                queryWorkspaceTrackerBindingsUseCase: QuerySymphonyWorkspaceTrackerBindingsUseCase(
                    workspaceTrackerBindingPort: workspaceTrackerBindingPort
                )
            ),
            resolveWorkflowConfigurationUseCase: resolveWorkflowConfigurationUseCase,
            validateStartupConfigurationUseCase: validateStartupConfigurationUseCase,
            validateTrackerConnectionUseCase: ValidateSymphonyTrackerConnectionReadinessUseCase(
                trackerAuthPort: trackerAuthPort
            ),
            startupStateTransition: SymphonyStartupStateTransition()
        )
    }

    static func makeDispatchPreflightValidationService(
        environment: [String: String] = [:],
        trackerAuthPort: any SymphonyTrackerAuthPortProtocol = TrackerAuthPortSpy()
    ) -> SymphonyDispatchPreflightValidationService {
        let resolveWorkflowConfigurationUseCase = ResolveSymphonyWorkflowConfigurationUseCase(
            workflowLoaderPort: SymphonyWorkflowLoaderPortAdapter(environment: environment),
            configResolverPort: SymphonyConfigResolverPortAdapter(environment: environment)
        )

        let validateStartupConfigurationUseCase = ValidateSymphonyStartupConfigurationUseCase(
            startupConfigurationValidatorPort: ValidateSymphonyStartupConfigurationPortAdapter()
        )

        return SymphonyDispatchPreflightValidationService(
            resolveWorkflowConfigurationUseCase: resolveWorkflowConfigurationUseCase,
            validateStartupConfigurationUseCase: validateStartupConfigurationUseCase,
            validateTrackerConnectionUseCase: ValidateSymphonyTrackerConnectionReadinessUseCase(
                trackerAuthPort: trackerAuthPort
            )
        )
    }

    static func makeHostRuntime(
        environment: [String: String] = [:],
        trackerAuthPort: any SymphonyTrackerAuthPortProtocol = TrackerAuthPortSpy(),
        workspaceTrackerBindingPort: any SymphonyWorkspaceTrackerBindingPortProtocol = WorkspaceTrackerBindingPortSpy(),
        startRuntime: @escaping SymphonyServiceHostRuntime.StartRuntime,
        keepRunning: @escaping SymphonyServiceHostRuntime.KeepRunning
    ) -> SymphonyServiceHostRuntime {
        return SymphonyServiceHostRuntime(
            startupService: makeStartupService(
                environment: environment,
                trackerAuthPort: trackerAuthPort,
                workspaceTrackerBindingPort: workspaceTrackerBindingPort
            ),
            renderer: SymphonyStartupRenderer(),
            startRuntime: startRuntime,
            keepRunning: keepRunning
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
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        return directoryURL
    }

    static func makeWorkspaceBinding(
        workspacePath: String,
        explicitWorkflowPath: String? = nil,
        trackerKind: String = "linear",
        scopeKind: String = "team",
        scopeIdentifier: String = "team-id",
        scopeName: String = "Team"
    ) -> SymphonyWorkspaceTrackerBindingContract {
        SymphonyWorkspaceTrackerBindingContract(
            workspacePath: workspacePath,
            explicitWorkflowPath: explicitWorkflowPath,
            trackerKind: trackerKind,
            scopeKind: scopeKind,
            scopeIdentifier: scopeIdentifier,
            scopeName: scopeName
        )
    }

    static func withTemporaryCurrentDirectory<T>(
        _ path: String,
        execute: () -> T
    ) -> T {
        processMutationLock.lock()
        defer {
            processMutationLock.unlock()
        }

        let fileManager = FileManager.default
        let originalPath = fileManager.currentDirectoryPath
        precondition(fileManager.changeCurrentDirectoryPath(path))

        defer {
            precondition(fileManager.changeCurrentDirectoryPath(originalPath))
        }

        return execute()
    }

    static func captureStandardOutput(
        execute: () -> Int32
    ) -> (output: String, exitCode: Int32) {
        captureStream(fileDescriptor: STDOUT_FILENO, execute: execute)
    }

    static func captureStandardError(
        execute: () -> Int32
    ) -> (output: String, exitCode: Int32) {
        captureStream(fileDescriptor: STDERR_FILENO, execute: execute)
    }

    static func captureStream(
        fileDescriptor: Int32,
        execute: () -> Int32
    ) -> (output: String, exitCode: Int32) {
        defer {
            processMutationLock.unlock()
        }
        processMutationLock.lock()

        var pipeFileDescriptors: [Int32] = [0, 0]
        precondition(pipe(&pipeFileDescriptors) == 0)

        let originalFileDescriptor = dup(fileDescriptor)
        precondition(originalFileDescriptor >= 0)

        defer {
            close(originalFileDescriptor)
        }

        precondition(dup2(pipeFileDescriptors[1], fileDescriptor) >= 0)
        close(pipeFileDescriptors[1])

        let exitCode = execute()

        fflush(stdout)
        fflush(stderr)
        precondition(dup2(originalFileDescriptor, fileDescriptor) >= 0)

        let readHandle = FileHandle(fileDescriptor: pipeFileDescriptors[0], closeOnDealloc: true)
        let outputData = readHandle.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)
        return (output, exitCode)
    }
}
