import Foundation

public struct SymphonyWorkspaceBindingSetupService: Sendable {
    private let saveWorkspaceTrackerBindingUseCase: SaveSymphonyWorkspaceTrackerBindingUseCase

    public init(
        saveWorkspaceTrackerBindingUseCase: SaveSymphonyWorkspaceTrackerBindingUseCase
    ) {
        self.saveWorkspaceTrackerBindingUseCase = saveWorkspaceTrackerBindingUseCase
    }

    public func saveBinding(
        _ binding: SymphonyWorkspaceTrackerBindingContract
    ) throws -> SymphonyWorkspaceTrackerBindingContract {
        guard binding.workspacePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw SymphonyWorkspaceBindingSetupApplicationError.missingWorkspaceSelection
        }

        guard binding.scopeKind.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
              binding.scopeIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
              binding.scopeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw SymphonyWorkspaceBindingSetupApplicationError.missingScopeSelection
        }

        return try saveWorkspaceTrackerBindingUseCase.save(binding)
    }
}
