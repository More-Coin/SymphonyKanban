import Foundation
import Testing
@testable import SymphonyKanban

struct SymphonyWorkspaceTrackerBindingRepositoryTests {
    @Test
    func saveAndResolveBindingRoundTripsNormalizedWorkspacePath() throws {
        let (repository, storageURL) = makeRepository()
        let basePath = storageURL.deletingLastPathComponent().path
        let binding = SymphonyWorkspaceTrackerBindingContract(
            workspacePath: "\(basePath)/subdir/../ProjectA",
            explicitWorkflowPath: "\(basePath)/subdir/../ProjectA/WORKFLOW.md",
            trackerKind: " linear ",
            scopeKind: " team ",
            scopeIdentifier: " team-a ",
            scopeName: " Nara IOS "
        )

        try repository.saveBinding(binding)

        let result = try repository.resolveBinding(
            for: SymphonyWorkspaceLocatorContract(
                currentWorkingDirectoryPath: "\(basePath)/ProjectA",
                explicitWorkflowPath: nil
            )
        )

        #expect(
            result == SymphonyWorkspaceTrackerBindingContract(
                workspacePath: "\(basePath)/ProjectA",
                explicitWorkflowPath: "\(basePath)/ProjectA/WORKFLOW.md",
                trackerKind: "linear",
                scopeKind: "team",
                scopeIdentifier: "team-a",
                scopeName: "Nara IOS"
            )
        )
    }

    @Test
    func saveBindingReplacesExistingBindingForSameWorkspace() throws {
        let (repository, storageURL) = makeRepository()
        let workspacePath = "\(storageURL.deletingLastPathComponent().path)/ProjectA"

        try repository.saveBinding(
            SymphonyWorkspaceTrackerBindingContract(
                workspacePath: workspacePath,
                explicitWorkflowPath: nil,
                trackerKind: "linear",
                scopeKind: "team",
                scopeIdentifier: "team-a",
                scopeName: "Nara IOS"
            )
        )

        try repository.saveBinding(
            SymphonyWorkspaceTrackerBindingContract(
                workspacePath: workspacePath,
                explicitWorkflowPath: "\(workspacePath)/WORKFLOW.md",
                trackerKind: "linear",
                scopeKind: "team",
                scopeIdentifier: "team-b",
                scopeName: "Nara IOS Beta"
            )
        )

        let bindings = try repository.listBindings()

        #expect(bindings.count == 1)
        #expect(bindings.first?.scopeIdentifier == "team-b")
        #expect(bindings.first?.explicitWorkflowPath == "\(workspacePath)/WORKFLOW.md")
    }

    @Test
    func listBindingsReturnsBindingsSortedByWorkspacePath() throws {
        let (repository, storageURL) = makeRepository()
        let basePath = storageURL.deletingLastPathComponent().path

        try repository.saveBinding(
            SymphonyWorkspaceTrackerBindingContract(
                workspacePath: "\(basePath)/b-project",
                explicitWorkflowPath: nil,
                trackerKind: "linear",
                scopeKind: "team",
                scopeIdentifier: "team-b",
                scopeName: "B Team"
            )
        )
        try repository.saveBinding(
            SymphonyWorkspaceTrackerBindingContract(
                workspacePath: "\(basePath)/a-project",
                explicitWorkflowPath: nil,
                trackerKind: "linear",
                scopeKind: "team",
                scopeIdentifier: "team-a",
                scopeName: "A Team"
            )
        )

        let bindings = try repository.listBindings()

        #expect(bindings.map(\.workspacePath) == ["\(basePath)/a-project", "\(basePath)/b-project"])
    }

    @Test
    func removeBindingDeletesStoredBindingAndBackingFileWhenLastRecordIsRemoved() throws {
        let (repository, storageURL) = makeRepository()

        try repository.saveBinding(
            SymphonyWorkspaceTrackerBindingContract(
                workspacePath: "/tmp/project-a",
                explicitWorkflowPath: nil,
                trackerKind: "linear",
                scopeKind: "team",
                scopeIdentifier: "team-a",
                scopeName: "A Team"
            )
        )

        try repository.removeBinding(forWorkspacePath: "/tmp/project-a")

        #expect(try repository.listBindings().isEmpty)
        #expect(FileManager.default.fileExists(atPath: storageURL.path) == false)
    }

    @Test
    func listBindingsReturnsEmptyArrayWhenStorageFileDoesNotExist() throws {
        let (repository, _) = makeRepository()

        let bindings = try repository.listBindings()

        #expect(bindings.isEmpty)
    }
}

private func makeRepository() -> (SymphonyWorkspaceTrackerBindingRepository, URL) {
    let rootURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let storageURL = rootURL
        .appendingPathComponent("workspace-bindings.json", isDirectory: false)

    return (
        SymphonyWorkspaceTrackerBindingRepository(storageURL: storageURL),
        storageURL
    )
}
