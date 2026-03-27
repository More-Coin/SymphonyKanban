import Foundation

public struct ArchitectureFunctionTypeOccurrence: Sendable, Equatable {
    public let coordinate: SourceCoordinate

    public init(coordinate: SourceCoordinate) {
        self.coordinate = coordinate
    }
}
