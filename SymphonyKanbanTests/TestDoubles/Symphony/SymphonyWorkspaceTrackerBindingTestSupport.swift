import Foundation
@testable import SymphonyKanban

final class WorkspaceTrackerBindingPortSpy: SymphonyWorkspaceTrackerBindingPortProtocol, @unchecked Sendable {
    private let resolvedBindingValue: SymphonyWorkspaceTrackerBindingContract?
    private let listedBindingsValue: [SymphonyWorkspaceTrackerBindingContract]

    private(set) var resolveCallCount = 0
    private(set) var listCallCount = 0
    private(set) var savedBindings: [SymphonyWorkspaceTrackerBindingContract] = []
    private(set) var removedWorkspacePaths: [String] = []

    init(
        resolvedBinding: SymphonyWorkspaceTrackerBindingContract? = nil,
        listedBindings: [SymphonyWorkspaceTrackerBindingContract] = []
    ) {
        self.resolvedBindingValue = resolvedBinding
        self.listedBindingsValue = listedBindings
    }

    func resolveBinding(
        for _: SymphonyWorkspaceLocatorContract
    ) throws -> SymphonyWorkspaceTrackerBindingContract? {
        resolveCallCount += 1
        return resolvedBindingValue
    }

    func listBindings() throws -> [SymphonyWorkspaceTrackerBindingContract] {
        listCallCount += 1
        return listedBindingsValue
    }

    func saveBinding(
        _ binding: SymphonyWorkspaceTrackerBindingContract
    ) throws {
        savedBindings.append(binding)
    }

    func removeBinding(
        forWorkspacePath workspacePath: String
    ) throws {
        removedWorkspacePaths.append(workspacePath)
    }
}
