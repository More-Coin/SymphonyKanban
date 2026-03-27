import Foundation

public struct ArchitectureTypeReference: Sendable, Equatable {
    public let name: String
    public let coordinate: SourceCoordinate

    public init(name: String, coordinate: SourceCoordinate) {
        self.name = name
        self.coordinate = coordinate
    }
}
