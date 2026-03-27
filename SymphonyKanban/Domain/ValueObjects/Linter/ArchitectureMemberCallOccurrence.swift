import Foundation

public struct ArchitectureMemberCallOccurrence: Sendable, Equatable {
    public let baseName: String
    public let memberName: String
    public let coordinate: SourceCoordinate

    public init(baseName: String, memberName: String, coordinate: SourceCoordinate) {
        self.baseName = baseName
        self.memberName = memberName
        self.coordinate = coordinate
    }
}
