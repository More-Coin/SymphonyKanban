import Foundation

public struct ArchitectureTypedMemberOccurrence: Sendable, Equatable {
    public let name: String
    public let typeNames: [String]
    public let coordinate: SourceCoordinate

    public init(name: String, typeNames: [String], coordinate: SourceCoordinate) {
        self.name = name
        self.typeNames = typeNames
        self.coordinate = coordinate
    }
}
