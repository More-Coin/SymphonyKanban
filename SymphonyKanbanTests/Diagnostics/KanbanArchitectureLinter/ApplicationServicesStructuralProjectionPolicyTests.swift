import Testing
@testable import SymphonyKanban

struct ApplicationServicesStructuralProjectionPolicyTests {
    @Test
    func serviceProjectionPipelineFailsWhenServiceEmitsProjectionContractsThroughSinkPort() {
        let file = applicationServiceFile(
            storedMembers: [
                ArchitectureStoredMemberDeclaration(
                    enclosingTypeName: "ProjectionService",
                    name: "sink",
                    typeNames: ["TelemetryPortProtocol"],
                    isStatic: false,
                    coordinate: coordinate(2)
                )
            ],
            methodDeclarations: [
                ArchitectureMethodDeclaration(
                    enclosingTypeName: "ProjectionService",
                    name: "handle",
                    isStatic: false,
                    isPublicOrOpen: true,
                    isPrivateOrFileprivate: false,
                    parameterTypeNames: ["ExecutionResultContract"],
                    hasExplicitReturnType: false,
                    returnTypeDescription: nil,
                    returnTypeNames: [],
                    returnsVoidLike: true,
                    coordinate: coordinate(3)
                )
            ],
            operationalUseOccurrences: [
                ArchitectureOperationalUseOccurrence(
                    enclosingTypeName: "ProjectionService",
                    enclosingMethodName: "handle",
                    baseName: "LogEventContract",
                    memberName: "callAsFunction",
                    branchGroupIndex: nil,
                    branchArmIndex: nil,
                    coordinate: coordinate(4)
                ),
                ArchitectureOperationalUseOccurrence(
                    enclosingTypeName: "ProjectionService",
                    enclosingMethodName: "handle",
                    baseName: "sink",
                    memberName: "emit",
                    branchGroupIndex: nil,
                    branchArmIndex: nil,
                    coordinate: coordinate(5)
                )
            ]
        )

        let diagnostics = ApplicationServicesSurfacePolicy().evaluate(
            file: file,
            context: projectionContext()
        )

        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.ruleID == ApplicationServicesSurfacePolicy.ruleID)
    }

    @Test
    func serviceUsingPortProtocolWithoutProjectionPipelinePasses() {
        let file = applicationServiceFile(
            storedMembers: [
                ArchitectureStoredMemberDeclaration(
                    enclosingTypeName: "ProjectionService",
                    name: "sink",
                    typeNames: ["TelemetryPortProtocol"],
                    isStatic: false,
                    coordinate: coordinate(2)
                )
            ],
            methodDeclarations: [
                ArchitectureMethodDeclaration(
                    enclosingTypeName: "ProjectionService",
                    name: "handle",
                    isStatic: false,
                    isPublicOrOpen: true,
                    isPrivateOrFileprivate: false,
                    parameterTypeNames: ["ExecutionResultContract"],
                    hasExplicitReturnType: false,
                    returnTypeDescription: nil,
                    returnTypeNames: [],
                    returnsVoidLike: true,
                    coordinate: coordinate(3)
                )
            ]
        )

        let diagnostics = ApplicationServicesSurfacePolicy().evaluate(
            file: file,
            context: projectionContext()
        )

        #expect(diagnostics.isEmpty)
    }

    @Test
    func nestedProjectionHelperFailsWhenItHandlesSourceAndReturnsProjectionContract() {
        let file = applicationServiceFile(
            storedMembers: [
                ArchitectureStoredMemberDeclaration(
                    enclosingTypeName: "Projector",
                    name: "sink",
                    typeNames: ["TelemetryPortProtocol"],
                    isStatic: false,
                    coordinate: coordinate(21)
                )
            ],
            methodDeclarations: [
                ArchitectureMethodDeclaration(
                    enclosingTypeName: "Projector",
                    name: "project",
                    isStatic: false,
                    isPublicOrOpen: false,
                    isPrivateOrFileprivate: true,
                    parameterTypeNames: ["ExecutionResultContract"],
                    hasExplicitReturnType: true,
                    returnTypeDescription: "LogEventContract",
                    returnTypeNames: ["LogEventContract"],
                    returnsVoidLike: false,
                    coordinate: coordinate(22)
                )
            ],
            nestedDeclarations: [
                ArchitectureNestedNominalDeclaration(
                    enclosingTypeName: "ProjectionService",
                    name: "Projector",
                    kind: .struct,
                    inheritedTypeNames: [],
                    memberNames: ["project"],
                    coordinate: coordinate(20)
                )
            ]
        )

        let diagnostics = ApplicationServicesSurfacePolicy().evaluate(
            file: file,
            context: projectionContext()
        )

        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.line == 20)
    }

    @Test
    func sinkShapedPortProtocolPassesWhenEachMethodAcceptsExactlyOneApplicationContract() {
        let file = applicationPortProtocolFile(
            topLevelName: "TelemetryPortProtocol",
            methodDeclarations: [
                ArchitectureMethodDeclaration(
                    enclosingTypeName: "TelemetryPortProtocol",
                    name: "emit",
                    isStatic: false,
                    isPublicOrOpen: true,
                    isPrivateOrFileprivate: false,
                    parameterTypeNames: ["LogEventContract"],
                    hasExplicitReturnType: false,
                    returnTypeDescription: nil,
                    returnTypeNames: [],
                    returnsVoidLike: true,
                    coordinate: coordinate(2)
                )
            ]
        )

        let diagnostics = ApplicationPortProtocolsShapePolicy().evaluate(
            file: file,
            context: protocolContext(
                methodShapes: [
                    IndexedMethodShape(
                        returnsVoidLike: true,
                        parameterTypeNames: ["LogEventContract"]
                    )
                ]
            )
        )

        #expect(diagnostics.isEmpty)
    }

    @Test
    func sinkShapedPortProtocolFailsWhenMethodMixesContractAndPayloadParameters() {
        let file = applicationPortProtocolFile(
            topLevelName: "TelemetryPortProtocol",
            methodDeclarations: [
                ArchitectureMethodDeclaration(
                    enclosingTypeName: "TelemetryPortProtocol",
                    name: "emit",
                    isStatic: false,
                    isPublicOrOpen: true,
                    isPrivateOrFileprivate: false,
                    parameterTypeNames: ["LogEventContract", "Int"],
                    hasExplicitReturnType: false,
                    returnTypeDescription: nil,
                    returnTypeNames: [],
                    returnsVoidLike: true,
                    coordinate: coordinate(2)
                )
            ]
        )

        let diagnostics = ApplicationPortProtocolsShapePolicy().evaluate(
            file: file,
            context: protocolContext(
                methodShapes: [
                    IndexedMethodShape(
                        returnsVoidLike: true,
                        parameterTypeNames: ["LogEventContract", "Int"]
                    )
                ]
            )
        )

        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.ruleID == ApplicationPortProtocolsShapePolicy.ruleID)
    }

    @Test
    func protocolWithNoMethodsIsNotTreatedAsSink() {
        let file = applicationPortProtocolFile(
            topLevelName: "TelemetryPortProtocol",
            methodDeclarations: []
        )

        let diagnostics = ApplicationPortProtocolsShapePolicy().evaluate(
            file: file,
            context: protocolContext(methodShapes: [])
        )

        #expect(diagnostics.isEmpty)
    }
}

private func projectionContext() -> ProjectContext {
    ProjectContext(
        declarations: [
            IndexedDeclaration(
                name: "ExecutionResultContract",
                kind: .struct,
                inheritedTypeNames: [],
                methodShapes: [],
                repoRelativePath: "SymphonyKanban/Application/Contracts/Workflow/ExecutionResultContract.swift",
                layer: .application,
                roleFolder: .applicationContractsWorkflow
            ),
            IndexedDeclaration(
                name: "LogEventContract",
                kind: .struct,
                inheritedTypeNames: [],
                methodShapes: [],
                repoRelativePath: "SymphonyKanban/Application/Contracts/Workflow/LogEventContract.swift",
                layer: .application,
                roleFolder: .applicationContractsWorkflow
            ),
            IndexedDeclaration(
                name: "TelemetryPortProtocol",
                kind: .protocol,
                inheritedTypeNames: [],
                methodShapes: [
                    IndexedMethodShape(
                        returnsVoidLike: true,
                        parameterTypeNames: ["ExecutionResultContract"]
                    ),
                    IndexedMethodShape(
                        returnsVoidLike: true,
                        parameterTypeNames: ["LogEventContract"]
                    )
                ],
                repoRelativePath: "SymphonyKanban/Application/Ports/Protocols/Telemetry/TelemetryPortProtocol.swift",
                layer: .application,
                roleFolder: .applicationPortsProtocols
            )
        ]
    )
}

private func protocolContext(methodShapes: [IndexedMethodShape]) -> ProjectContext {
    ProjectContext(
        declarations: [
            IndexedDeclaration(
                name: "LogEventContract",
                kind: .struct,
                inheritedTypeNames: [],
                methodShapes: [],
                repoRelativePath: "SymphonyKanban/Application/Contracts/Workflow/LogEventContract.swift",
                layer: .application,
                roleFolder: .applicationContractsWorkflow
            ),
            IndexedDeclaration(
                name: "TelemetryPortProtocol",
                kind: .protocol,
                inheritedTypeNames: [],
                methodShapes: methodShapes,
                repoRelativePath: "SymphonyKanban/Application/Ports/Protocols/Telemetry/TelemetryPortProtocol.swift",
                layer: .application,
                roleFolder: .applicationPortsProtocols
            )
        ]
    )
}

private func applicationServiceFile(
    storedMembers: [ArchitectureStoredMemberDeclaration] = [],
    methodDeclarations: [ArchitectureMethodDeclaration] = [],
    operationalUseOccurrences: [ArchitectureOperationalUseOccurrence] = [],
    nestedDeclarations: [ArchitectureNestedNominalDeclaration] = []
) -> ArchitectureFile {
    ArchitectureFile(
        repoRelativePath: "SymphonyKanban/Application/Services/ProjectionService.swift",
        classification: FileClassification(
            repoRelativePath: "SymphonyKanban/Application/Services/ProjectionService.swift",
            layer: .application,
            roleFolder: .applicationServices,
            pathComponents: ["SymphonyKanban", "Application", "Services", "ProjectionService.swift"],
            fileName: "ProjectionService.swift",
            fileStem: "ProjectionService"
        ),
        imports: [],
        functionTypeOccurrences: [],
        identifierOccurrences: [],
        stringLiteralOccurrences: [],
        typedMemberOccurrences: [],
        memberCallOccurrences: [],
        methodDeclarations: methodDeclarations,
        initializerDeclarations: [],
        computedPropertyDeclarations: [],
        storedMemberDeclarations: storedMembers,
        operationalUseOccurrences: operationalUseOccurrences,
        typeReferences: [],
        topLevelDeclarations: [
            ArchitectureTopLevelDeclaration(
                name: "ProjectionService",
                kind: .class,
                inheritedTypeNames: [],
                memberNames: ["handle"],
                coordinate: coordinate(1)
            )
        ],
        nestedNominalDeclarations: nestedDeclarations
    )
}

private func applicationPortProtocolFile(
    topLevelName: String,
    methodDeclarations: [ArchitectureMethodDeclaration]
) -> ArchitectureFile {
    ArchitectureFile(
        repoRelativePath: "SymphonyKanban/Application/Ports/Protocols/Telemetry/\(topLevelName).swift",
        classification: FileClassification(
            repoRelativePath: "SymphonyKanban/Application/Ports/Protocols/Telemetry/\(topLevelName).swift",
            layer: .application,
            roleFolder: .applicationPortsProtocols,
            pathComponents: ["SymphonyKanban", "Application", "Ports", "Protocols", "Telemetry", "\(topLevelName).swift"],
            fileName: "\(topLevelName).swift",
            fileStem: topLevelName
        ),
        imports: [],
        functionTypeOccurrences: [],
        identifierOccurrences: [],
        stringLiteralOccurrences: [],
        typedMemberOccurrences: [],
        memberCallOccurrences: [],
        methodDeclarations: methodDeclarations,
        initializerDeclarations: [],
        computedPropertyDeclarations: [],
        storedMemberDeclarations: [],
        operationalUseOccurrences: [],
        typeReferences: [],
        topLevelDeclarations: [
            ArchitectureTopLevelDeclaration(
                name: topLevelName,
                kind: .protocol,
                inheritedTypeNames: [],
                memberNames: methodDeclarations.map(\.name),
                coordinate: coordinate(1)
            )
        ],
        nestedNominalDeclarations: []
    )
}

private func coordinate(_ line: Int) -> SourceCoordinate {
    SourceCoordinate(line: line, column: 1)
}
