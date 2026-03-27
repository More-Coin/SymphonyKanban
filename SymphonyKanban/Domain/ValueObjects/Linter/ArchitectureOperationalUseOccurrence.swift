import Foundation

public struct ArchitectureOperationalUseOccurrence: Sendable, Equatable {
    public let enclosingTypeName: String
    public let enclosingMethodName: String
    public let baseName: String
    public let memberName: String
    public let branchGroupIndex: Int?
    public let branchArmIndex: Int?
    public let coordinate: SourceCoordinate

    public init(
        enclosingTypeName: String,
        enclosingMethodName: String,
        baseName: String,
        memberName: String,
        branchGroupIndex: Int?,
        branchArmIndex: Int?,
        coordinate: SourceCoordinate
    ) {
        self.enclosingTypeName = enclosingTypeName
        self.enclosingMethodName = enclosingMethodName
        self.baseName = baseName
        self.memberName = memberName
        self.branchGroupIndex = branchGroupIndex
        self.branchArmIndex = branchArmIndex
        self.coordinate = coordinate
    }
}
