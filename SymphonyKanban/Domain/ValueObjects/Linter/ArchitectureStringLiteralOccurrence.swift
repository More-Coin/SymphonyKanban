import Foundation

public struct ArchitectureStringLiteralOccurrence: Sendable, Equatable {
    public let value: String
    public let coordinate: SourceCoordinate

    public init(value: String, coordinate: SourceCoordinate) {
        self.value = value
        self.coordinate = coordinate
    }
}
