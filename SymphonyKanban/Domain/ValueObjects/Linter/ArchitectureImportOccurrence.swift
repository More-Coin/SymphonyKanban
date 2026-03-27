import Foundation

public struct ArchitectureImportOccurrence: Sendable, Equatable {
    public let moduleName: String
    public let coordinate: SourceCoordinate

    public init(moduleName: String, coordinate: SourceCoordinate) {
        self.moduleName = moduleName
        self.coordinate = coordinate
    }
}
