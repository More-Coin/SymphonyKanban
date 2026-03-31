import Foundation

public struct TestsSwiftPMTargetRootPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "tests.swiftpm_test_targets_must_point_to_repo_test_root"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.repoRelativePath == "Package.swift" else {
            return []
        }

        return file.stringLiteralOccurrences.compactMap { occurrence in
            guard occurrence.value.hasPrefix("Tests/") else {
                return nil
            }

            return file.diagnostic(
                ruleID: Self.ruleID,
                message: testArchitectureMessage(
                    summary: "SwiftPM test target path '\(occurrence.value)' still points at the legacy test root.",
                    categories: [
                        "legacy SwiftPM test target path",
                        "partial migration where canonical repo test folders exist but Package.swift still points at Tests/",
                        "diagnostics or runtime target path rooted outside the canonical <ProjectName>Tests/ tree"
                    ],
                    signs: [
                        "Package.swift contains a test-target path string literal beginning with Tests/",
                        "runtime suites are still discovered from Tests/... instead of a canonical test root whose folder name ends in Tests",
                        "diagnostics suites are not rooted under \(diagnosticsCanonicalPrefix())."
                    ],
                    architecturalNote: "SwiftPM remains the active source of truth for test discovery in this repository, but all active test targets must converge on one canonical repo test root whose folder name ends in Tests so lint, CI, and agent-driven remediation all describe the same filesystem layout.",
                    destination: "rewrite Package.swift testTarget paths to \(runtimeBucketDestinationSummary()) for runtime coverage and \(diagnosticsCanonicalPrefix()) for architecture-linter coverage.",
                    decomposition: "first move runtime suites into the canonical layer buckets under the repo test root ending in Tests, then move diagnostics suites under \(diagnosticsCanonicalPrefix()), and finally repoint every SwiftPM testTarget path away from Tests/."
                ),
                coordinate: occurrence.coordinate
            )
        }
    }
}

public struct TestsLegacyRootPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "tests.no_active_tests_under_legacy_tests_root"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isLegacyTestFile else {
            return []
        }
        guard let declaration = primaryTestSuite(in: file) else {
            return []
        }

        return [
            file.diagnostic(
                ruleID: Self.ruleID,
                message: testArchitectureMessage(
                    summary: "Active test suite '\(declaration.name)' still lives under the legacy Tests/ root.",
                    categories: [
                        "legacy runtime or diagnostics suite path",
                        "half-migrated test tree where active suites remain under Tests/",
                        "SwiftPM target still bound to the old filesystem layout"
                    ],
                    signs: [
                        "repo-relative path begins with Tests/",
                        "the file still declares a primary test suite or test-bearing type",
                        "the canonical repo test root ending in Tests is not yet the only active location."
                    ],
                    architecturalNote: "The repo should have exactly one active filesystem root for tests. Leaving active suites under Tests/ creates split ownership, weakens lint guidance, and makes migration harder for both humans and agents.",
                    destination: legacyDestinationGuidance(for: file),
                    decomposition: "move the suite into its canonical layered bucket under the repo test root ending in Tests, move reusable spies, builders, and temp-workspace support into \(testDoublesCanonicalPrefix(for: file)) when needed, then repoint Package.swift so the legacy Tests/ root becomes empty."
                ),
                coordinate: declaration.coordinate
            )
        ]
    }
}

public struct TestsRuntimeLayeredLocationPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "tests.runtime_suite_must_follow_layered_location"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard isRuntimeTestFile(file) else {
            return []
        }

        let inferredBuckets = inferredRuntimeBuckets(for: file)
        guard inferredBuckets.count == 1, let bucket = inferredBuckets.first else {
            return []
        }

        let expectedPrefix = bucket.canonicalPrefix(testRootName: canonicalTestRootName(for: file))
        guard !file.repoRelativePath.hasPrefix(expectedPrefix) else {
            return []
        }

        let declaration = primaryTestSuite(in: file)
        return [
            file.diagnostic(
                ruleID: Self.ruleID,
                message: testArchitectureMessage(
                    summary: "Runtime suite '\(declaration?.name ?? file.classification.fileStem)' is not placed in the canonical \(bucket.rawValue) test bucket.",
                    categories: [
                        "\(bucket.rawValue) runtime suite",
                        "legacy runtime suite path",
                        "layer-aligned test ownership mismatch"
                    ],
                    signs: [
                        "the suite imports runtime modules such as SymphonyRuntime or SymphonyCLI",
                        "the suite name and member names point at \(bucket.signDescription)",
                        "the repo-relative path does not begin with \(expectedPrefix)."
                    ],
                    architecturalNote: "Runtime tests should mirror the production architecture buckets so ownership stays obvious: Application tests with application responsibilities, Infrastructure tests with boundary behaviors, Domain tests with policies, Presentation tests with presentation seams, and App tests with bootstrap or wiring responsibilities.",
                    destination: "place this suite under \(expectedPrefix).",
                    decomposition: bucket.decompositionGuidance
                ),
                coordinate: declaration?.coordinate
            )
        ]
    }
}

public struct TestsDiagnosticsLocationPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "tests.linter_suite_must_live_under_diagnostics"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard isDiagnosticsTestFile(file) else {
            return []
        }

        let expectedPrefix = diagnosticsCanonicalPrefix(for: file)
        guard !file.repoRelativePath.hasPrefix(expectedPrefix) else {
            return []
        }

        let declaration = primaryTestSuite(in: file)
        return [
            file.diagnostic(
                ruleID: Self.ruleID,
                message: testArchitectureMessage(
                    summary: "Architecture-linter suite '\(declaration?.name ?? file.classification.fileStem)' is not rooted under Diagnostics.",
                    categories: [
                        "diagnostics suite rooted outside the canonical Diagnostics test tree",
                        "legacy architecture-linter suite path",
                        "test ownership mismatch between runtime coverage and diagnostics coverage"
                    ],
                    signs: [
                        "the file imports KanbanArchitectureLinterCLI, SwiftParser, SwiftSyntax, or KanbanArchitectureLinterDomain",
                        "the file behaves like diagnostics coverage rather than runtime feature coverage",
                        "the repo-relative path does not begin with \(expectedPrefix)."
                    ],
                    architecturalNote: "Architecture-linter tests are diagnostics coverage, not runtime feature tests. They should live under a dedicated Diagnostics root so agents can distinguish structural lint coverage from Symphony runtime coverage.",
                    destination: "move diagnostics suites under \(expectedPrefix).",
                    decomposition: "split diagnostics coverage by rule family under \(expectedPrefix), keep reusable harness code in a Support subtree under that diagnostics root, and keep runtime suites out of Diagnostics entirely."
                ),
                coordinate: declaration?.coordinate
            )
        ]
    }
}

public struct TestsSharedSupportPlacementPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "tests.shared_support_must_live_in_test_doubles"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard isRuntimeTestFile(file) else {
            return []
        }
        guard !isTestDoublesFile(file) else {
            return []
        }

        let supportDeclarations = supportNominalDeclarations(in: file)
        let supportHelpers = supportHelperMethods(in: file)
        guard !supportDeclarations.isEmpty || supportHelpers.count >= 3 else {
            return []
        }

        let firstCoordinate = supportDeclarations.first?.coordinate ?? supportHelpers.first?.coordinate
        let supportNames = supportDeclarations.map(\.name) + supportHelpers.map(\.name)
        let renderedNames = supportNames.prefix(6).joined(separator: ", ")

        return [
            file.diagnostic(
                ruleID: Self.ruleID,
                message: testArchitectureMessage(
                    summary: "Runtime suite '\(file.classification.fileStem)' still embeds reusable test support (\(renderedNames)).",
                    categories: [
                        "embedded spies or fakes in an active runtime suite",
                        "embedded builders, fixtures, or temp-workspace helpers in a runtime suite",
                        "runtime support ownership that should live in TestDoubles"
                    ],
                    signs: [
                        "the file declares support-shaped types such as Spy, Fake, Builder, Recorder, Environment, or Transport, or it carries multiple private helper builders",
                        "the suite mixes scenario assertions with reusable support infrastructure",
                        "the support does not live under \(testDoublesCanonicalPrefix(for: file))."
                    ],
                    architecturalNote: "Large runtime suites become hard to decompose when support infrastructure stays embedded. Shared or reusable test support should live in the dedicated TestDoubles tree so scenario suites can stay focused on one responsibility family.",
                    destination: "move reusable support to \(testDoublesCanonicalPrefix(for: file)) and keep only scenario-specific assertions in the active suite file.",
                    decomposition: "extract spies, fakes, builders, fake transports, fixture builders, and temp-workspace helpers to TestDoubles first; then trim the suite down to the specific scenarios that still need to stay together."
                ),
                coordinate: firstCoordinate
            )
        ]
    }
}

public struct TestsMegaArchitectureLinterSuitePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "tests.no_mega_architecture_linter_suite"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard isDiagnosticsTestFile(file) else {
            return []
        }

        guard file.classification.fileStem == "ArchitectureLinterTests"
            || file.topLevelDeclarations.contains(where: { $0.name == "ArchitectureLinterTests" }) else {
            return []
        }

        let declaration = primaryTestSuite(in: file)
        return [
            file.diagnostic(
                ruleID: Self.ruleID,
                message: testArchitectureMessage(
                    summary: "Diagnostics coverage still relies on a single mega-suite named ArchitectureLinterTests.",
                    categories: [
                        "single diagnostics mega-suite",
                        "mixed rule-family coverage in one diagnostics file",
                        "extracted harness and support still hidden inside the main architecture-linter suite"
                    ],
                    signs: [
                        "the file name or primary suite name is ArchitectureLinterTests",
                        "the suite acts as the catch-all entry point for multiple architecture policy families",
                        "support collectors or harness helpers are still colocated with the main diagnostics scenarios."
                    ],
                    architecturalNote: "Diagnostics suites should be split by rule family so failures point directly at the owning architectural area and so agents can remediate one family at a time.",
                    destination: "split diagnostics coverage under \(diagnosticsCanonicalPrefix(for: file)) into Domain, ApplicationContracts, ApplicationServicesUseCases, Infrastructure, PresentationApp, and Support or Harness files.",
                    decomposition: "first extract reusable lint harness and syntax collectors to a Support subtree, then split rule-family scenarios into separate diagnostics files, and finally remove the single ArchitectureLinterTests mega-suite entry point."
                ),
                coordinate: declaration?.coordinate
            )
        ]
    }
}

public struct TestsMixedResponsibilityRuntimeSuitePolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "tests.no_mixed_responsibility_runtime_suites"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard isRuntimeTestFile(file) else {
            return []
        }

        let families = runtimeResponsibilityFamilies(in: file)
        guard families.count > 1 else {
            return []
        }

        let declaration = primaryTestSuite(in: file)
        let renderedFamilies = families.map(\.displayName).joined(separator: ", ")
        let testRootName = canonicalTestRootName(for: file)
        let destinations = families.map { $0.canonicalPrefix(testRootName: testRootName) }.joined(separator: ", ")

        return [
            file.diagnostic(
                ruleID: Self.ruleID,
                message: testArchitectureMessage(
                    summary: "Runtime suite '\(declaration?.name ?? file.classification.fileStem)' mixes multiple responsibility families (\(renderedFamilies)).",
                    categories: [
                        "application plus presentation responsibilities in one file",
                        "application plus app-bootstrap responsibilities in one file",
                        "cross-layer runtime coverage hidden behind one suite name"
                    ],
                    signs: [
                        "member names or imports indicate more than one ownership family across Application, Infrastructure, Domain, Presentation, or App",
                        "the suite cannot move cleanly into one canonical layer bucket without splitting",
                        "multiple remediation destinations are implied: \(destinations)."
                    ],
                    architecturalNote: "A runtime suite should tell one ownership story. When one file mixes DTO parsing, controller rendering, service validation, runtime wiring, or gateway behavior, the resulting failures stop pointing to a single architectural owner.",
                    destination: "split the suite into separate files under the canonical family buckets: \(destinations).",
                    decomposition: "slice the file by responsibility family first, then move each slice into its matching canonical directory, and finally extract any shared support to TestDoubles instead of leaving it in one umbrella suite."
                ),
                coordinate: declaration?.coordinate
            )
        ]
    }
}

public struct TestsTestDoublesOnlySupportPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "tests.only_test_support_in_test_doubles"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard isTestDoublesFile(file) else {
            return []
        }

        let suiteDeclaration = primaryTestSuite(in: file)
        guard let suiteDeclaration else {
            return []
        }

        return [
            file.diagnostic(
                ruleID: Self.ruleID,
                message: testArchitectureMessage(
                    summary: "Test-doubles file '\(file.classification.fileStem)' still declares active suite '\(suiteDeclaration.name)'.",
                    categories: [
                        "real test suite placed in TestDoubles",
                        "support folder owning active scenarios instead of reusable helpers",
                        "test-support boundary violation"
                    ],
                    signs: [
                        "the file lives under \(canonicalTestRootName(for: file))/TestDoubles/...",
                        "it still exposes a top-level declaration ending in Tests",
                        "the file is carrying active scenarios instead of pure reusable support."
                    ],
                    architecturalNote: "TestDoubles is the ownership home for reusable support only. Scenario suites should stay in their layer-aligned directories, while TestDoubles stays reserved for spies, fakes, builders, fixtures, and temp-workspace helpers.",
                    destination: "move the active suite out of TestDoubles and leave only support types in \(canonicalTestRootName(for: file))/TestDoubles/...",
                    decomposition: "extract any reusable support from the suite, keep that support in TestDoubles, then move the scenario file into its layer-aligned Application, Infrastructure, Domain, Presentation, App, or Diagnostics location."
                ),
                coordinate: suiteDeclaration.coordinate
            )
        ]
    }
}

public struct TestsImportOwnershipPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "tests.test_files_should_import_only_needed_runtime_targets"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard file.classification.isTestFile else {
            return []
        }
        guard !isUITestFile(file) else {
            return []
        }

        let modules = Set(file.imports.map(\.moduleName))
        var diagnostics: [ArchitectureDiagnostic] = []

        if isDiagnosticsTestFile(file),
           let occurrence = file.imports.first(where: { ["SymphonyRuntime", "SymphonyCLI"].contains($0.moduleName) }) {
            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: testArchitectureMessage(
                        summary: "Diagnostics test file '\(file.classification.fileStem)' imports runtime module '\(occurrence.moduleName)'.",
                        categories: [
                            "diagnostics suite with runtime dependency bleed",
                            "misclassified runtime scenarios under diagnostics",
                            "test-module ownership mismatch"
                        ],
                        signs: [
                            "the file already behaves like an architecture-linter suite",
                            "a runtime module import appears alongside diagnostics imports",
                            "the suite is not isolated to KanbanArchitectureLinter diagnostics ownership."
                        ],
                        architecturalNote: "Diagnostics suites should stay focused on linter behavior and should not accrete runtime module dependencies unless the suite has been misclassified and should move out of Diagnostics.",
                        destination: "keep diagnostics suites limited to KanbanArchitectureLinter-related imports and move runtime scenarios to \(runtimeBucketDestinationSummary(for: file)) instead.",
                        decomposition: "separate runtime scenarios from diagnostics assertions first, move the runtime scenarios to their layer-aligned buckets, and leave only diagnostics-focused imports in the Diagnostics tree."
                    ),
                    coordinate: occurrence.coordinate
                )
            )
        }

        if isRuntimeTestFile(file),
           let occurrence = file.imports.first(where: { ["KanbanArchitectureLinterCLI", "SwiftParser", "SwiftSyntax"].contains($0.moduleName) }) {
            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: testArchitectureMessage(
                        summary: "Runtime test file '\(file.classification.fileStem)' imports diagnostics-only module '\(occurrence.moduleName)'.",
                        categories: [
                            "runtime suite carrying diagnostics dependencies",
                            "misclassified architecture-linter coverage in a runtime suite",
                            "test-module ownership mismatch"
                        ],
                        signs: [
                            "the file otherwise behaves like Symphony runtime coverage",
                            "a KanbanArchitectureLinter or parser module import appears in the runtime suite",
                            "the suite likely belongs in Diagnostics or needs to be split."
                        ],
                        architecturalNote: "Runtime suites should depend on runtime modules only. Diagnostics dependencies inside a runtime suite are a signal that diagnostics coverage has leaked out of the dedicated Diagnostics tree.",
                        destination: "move diagnostics-focused assertions to \(diagnosticsCanonicalPrefix(for: file)) and keep runtime suites limited to their needed Symphony modules.",
                        decomposition: "extract diagnostics-specific assertions into dedicated Diagnostics files, remove parser or linter imports from the runtime suite, and keep only the runtime-target imports the scenario actually exercises."
                    ),
                    coordinate: occurrence.coordinate
                )
            )
        }

        if isRuntimeTestFile(file),
           !file.repoRelativePath.hasPrefix(appBucketPrefix(for: file)),
           modules.contains("SymphonyRuntime"),
           modules.contains("SymphonyCLI"),
           let occurrence = file.imports.first(where: { $0.moduleName == "SymphonyCLI" }) {
            diagnostics.append(
                file.diagnostic(
                    ruleID: Self.ruleID,
                    message: testArchitectureMessage(
                        summary: "Runtime suite '\(file.classification.fileStem)' imports both SymphonyRuntime and SymphonyCLI outside the App test bucket.",
                        categories: [
                            "application plus app-bootstrap responsibilities in one runtime suite",
                            "suite that still mixes runtime wiring with lower-level scenarios",
                            "cross-layer import ownership mismatch"
                        ],
                        signs: [
                            "SymphonyRuntime and SymphonyCLI are both imported in the same non-App suite",
                            "the suite likely covers runtime behavior plus bootstrap or command-surface behavior together",
                            "the file cannot stay in one non-App canonical bucket without splitting."
                        ],
                        architecturalNote: "Non-App runtime suites should generally test one layer-facing surface. Pulling in SymphonyCLI alongside SymphonyRuntime usually means the suite mixes bootstrap or command-surface behavior with lower-level runtime responsibilities.",
                        destination: "move bootstrap or command-surface scenarios to \(appBucketPrefix(for: file)) and leave lower-level runtime scenarios in their Application, Infrastructure, Domain, or Presentation bucket.",
                        decomposition: "separate App-facing CLI or bootstrap scenarios first, move them to the App test bucket, then leave the remaining runtime scenarios with only the lower-level SymphonyRuntime dependency."
                    ),
                    coordinate: occurrence.coordinate
                )
            )
        }

        return diagnostics
    }
}

public struct TestsLinterHarnessExtractionPolicy: ArchitecturePolicyProtocol {
    public static let ruleID = "tests.linter_harness_support_must_be_extracted"

    public init() {}

    public func evaluate(file: ArchitectureFile, context: ProjectContext) -> [ArchitectureDiagnostic] {
        guard isDiagnosticsTestFile(file) else {
            return []
        }
        guard !file.repoRelativePath.contains("/Diagnostics/KanbanArchitectureLinter/Support/") else {
            return []
        }

        let harnessDeclarations = harnessSupportDeclarations(in: file)
        let harnessMethods = harnessSupportMethods(in: file)
        guard !harnessDeclarations.isEmpty || !harnessMethods.isEmpty else {
            return []
        }

        let coordinate = harnessDeclarations.first?.coordinate ?? harnessMethods.first?.coordinate
        let names = (harnessDeclarations.map(\.name) + harnessMethods.map(\.name)).prefix(8).joined(separator: ", ")

        return [
            file.diagnostic(
                ruleID: Self.ruleID,
                message: testArchitectureMessage(
                    summary: "Diagnostics suite '\(file.classification.fileStem)' still embeds reusable lint harness support (\(names)).",
                    categories: [
                        "embedded lint harness helpers in the main diagnostics suite",
                        "embedded syntax collectors or repo-fixture builders in the main diagnostics suite",
                        "diagnostics support ownership that should be extracted"
                    ],
                    signs: [
                        "the file declares collector, harness, repo-fixture, or lint-helper types and methods",
                        "support code sits beside diagnostics scenarios instead of a dedicated Support location",
                        "the suite cannot be cleanly split by rule family while support stays embedded."
                    ],
                    architecturalNote: "Diagnostics suites should not own their shared harness. Extracted harness support makes rule-family files smaller and keeps diagnostics failures focused on architecture behavior instead of parser plumbing.",
                    destination: "move reusable lint harness code to \(diagnosticsSupportPrefix(for: file)) and keep rule-family scenarios in separate diagnostics files.",
                    decomposition: "extract repo-fixture builders and lint helpers first, extract syntax collectors and reusable analyzer support next, then split the remaining diagnostics scenarios by rule family."
                ),
                coordinate: coordinate
            )
        ]
    }
}

private enum RuntimeTestBucket: String, CaseIterable {
    case application = "Application"
    case infrastructure = "Infrastructure"
    case domain = "Domain"
    case presentation = "Presentation"
    case app = "App"

    func canonicalPrefix(testRootName: String) -> String {
        "\(testRootName)/\(rawValue)/Symphony/"
    }

    var signDescription: String {
        switch self {
        case .application:
            return "application services, use cases, contracts, state, or workflow behavior"
        case .infrastructure:
            return "gateways, port adapters, workspace, reload-monitor, transport, or provider boundary behavior"
        case .domain:
            return "domain policies or pure domain invariants"
        case .presentation:
            return "controllers, DTOs, renderers, presenters, or other presentation seams"
        case .app:
            return "bootstrap, runtime wiring, dependency-injection, or CLI-surface behavior"
        }
    }

    var decompositionGuidance: String {
        switch self {
        case .application:
            return "keep one responsibility family per file inside Application/Symphony/, then move shared support to TestDoubles so services, use cases, contracts, and state suites do not stay bundled together."
        case .infrastructure:
            return "separate gateway, port-adapter, workspace, transport, and provider-specific scenarios by file, then move reusable boundary fakes or spies to TestDoubles."
        case .domain:
            return "keep pure policy or invariant coverage in Domain/Symphony/Policies/, and move any collaborator-driven behavior out toward Application or Infrastructure before migrating the suite."
        case .presentation:
            return "split DTO, controller, renderer, presenter, and other presentation seams into their own files under Presentation/Symphony/ so each file points at one presentation owner."
        case .app:
            return "keep bootstrap or CLI-surface scenarios in App/Symphony/, and split out any lower-level Application, Infrastructure, or Presentation behavior that leaked into the same file."
        }
    }

    static func from(pathComponent: String?) -> RuntimeTestBucket? {
        guard let pathComponent else {
            return nil
        }

        return allCases.first(where: { $0.rawValue == pathComponent })
    }
}

private enum RuntimeResponsibilityFamily: CaseIterable {
    case application
    case infrastructure
    case domain
    case presentation
    case app

    var displayName: String {
        switch self {
        case .application:
            return "Application"
        case .infrastructure:
            return "Infrastructure"
        case .domain:
            return "Domain"
        case .presentation:
            return "Presentation"
        case .app:
            return "App"
        }
    }

    func canonicalPrefix(testRootName: String) -> String {
        switch self {
        case .application:
            return RuntimeTestBucket.application.canonicalPrefix(testRootName: testRootName)
        case .infrastructure:
            return RuntimeTestBucket.infrastructure.canonicalPrefix(testRootName: testRootName)
        case .domain:
            return RuntimeTestBucket.domain.canonicalPrefix(testRootName: testRootName)
        case .presentation:
            return RuntimeTestBucket.presentation.canonicalPrefix(testRootName: testRootName)
        case .app:
            return RuntimeTestBucket.app.canonicalPrefix(testRootName: testRootName)
        }
    }
}

private func testArchitectureMessage(
    summary: String,
    categories: [String],
    signs: [String],
    architecturalNote: String,
    destination: String,
    decomposition: String
) -> String {
    "\(summary) Likely categories: \(categories.joined(separator: "; ")); signs: \(signs.joined(separator: "; ")); architectural note: \(architecturalNote); destination: \(destination); explicit decomposition guidance: \(decomposition)"
}

private func primaryTestSuite(in file: ArchitectureFile) -> ArchitectureTopLevelDeclaration? {
    file.topLevelDeclarations.first(where: { $0.name.hasSuffix("Tests") })
}

private func importedModules(in file: ArchitectureFile) -> Set<String> {
    Set(file.imports.map(\.moduleName))
}

private func isUITestFile(_ file: ArchitectureFile) -> Bool {
    file.classification.isUITestFile
}

private func isDiagnosticsTestFile(_ file: ArchitectureFile) -> Bool {
    guard file.classification.isTestFile else {
        return false
    }

    let modules = importedModules(in: file)
    return modules.contains("KanbanArchitectureLinterCLI")
        || modules.contains("SwiftParser")
        || modules.contains("SwiftSyntax")
        || file.repoRelativePath.contains("/Diagnostics/")
        || file.classification.fileStem.contains("ArchitectureLinter")
}

private func isRuntimeTestFile(_ file: ArchitectureFile) -> Bool {
    guard file.classification.isTestFile else {
        return false
    }
    guard !isUITestFile(file) else {
        return false
    }
    guard !isDiagnosticsTestFile(file) else {
        return false
    }
    guard !isTestDoublesFile(file) else {
        return false
    }

    let modules = importedModules(in: file)
    return modules.contains("SymphonyRuntime")
        || modules.contains("SymphonyCLI")
        || file.classification.fileStem.hasPrefix("Symphony")
        || file.classification.fileStem.contains("FetchSymphony")
}

private func isTestDoublesFile(_ file: ArchitectureFile) -> Bool {
    guard file.classification.isCanonicalRepoTestFile else {
        return false
    }

    return file.classification.pathComponents.dropFirst().first == "TestDoubles"
}

private func legacyDestinationGuidance(for file: ArchitectureFile) -> String {
    if isDiagnosticsTestFile(file) {
        return "move diagnostics suites under \(diagnosticsCanonicalPrefix(for: file))."
    }

    let inferred = inferredRuntimeBuckets(for: file)
    guard inferred.count == 1, let bucket = inferred.first else {
        return "move runtime suites under \(runtimeBucketDestinationSummary(for: file)) based on the owning responsibility family."
    }

    return "move the suite under \(bucket.canonicalPrefix(testRootName: canonicalTestRootName(for: file)))."
}

private let canonicalTestRootPlaceholder = "<ProjectName>Tests"

private func canonicalTestRootName(for file: ArchitectureFile? = nil) -> String {
    guard let root = file?.classification.testRootComponent,
          root != "Tests",
          root.hasSuffix("Tests"),
          !root.hasSuffix("UITests") else {
        return canonicalTestRootPlaceholder
    }

    return root
}

private func diagnosticsCanonicalPrefix(for file: ArchitectureFile? = nil) -> String {
    "\(canonicalTestRootName(for: file))/Diagnostics/KanbanArchitectureLinter/"
}

private func diagnosticsSupportPrefix(for file: ArchitectureFile? = nil) -> String {
    "\(diagnosticsCanonicalPrefix(for: file))Support/"
}

private func testDoublesCanonicalPrefix(for file: ArchitectureFile? = nil) -> String {
    "\(canonicalTestRootName(for: file))/TestDoubles/Symphony/"
}

private func appBucketPrefix(for file: ArchitectureFile? = nil) -> String {
    RuntimeTestBucket.app.canonicalPrefix(testRootName: canonicalTestRootName(for: file))
}

private func runtimeBucketDestinationSummary(for file: ArchitectureFile? = nil) -> String {
    let testRootName = canonicalTestRootName(for: file)
    return "\(testRootName)/Application|Infrastructure|Domain|Presentation|App/Symphony/..."
}

private func inferredRuntimeBuckets(for file: ArchitectureFile) -> [RuntimeTestBucket] {
    let stem = file.classification.fileStem.lowercased()
    let stemTokens = identifierTokens(from: file.classification.fileStem)
    let path = file.repoRelativePath.lowercased()
    let modules = importedModules(in: file)
    var buckets = Set<RuntimeTestBucket>()

    if stem.contains("gateway")
        || stem.contains("portadapter")
        || stem.contains("workspacelifecycle")
        || stem.contains("reloadmonitor")
        || stem.contains("tracker") {
        buckets.insert(.infrastructure)
    }
    if stem.contains("policy") || path.contains("/domain/") {
        buckets.insert(.domain)
    }
    if !stem.contains("portadapter")
        && (stem.contains("controller")
            || stem.contains("renderer")
            || stem.contains("dto")
            || stem.contains("presenter")
            || stem.contains("view")) {
        buckets.insert(.presentation)
    }
    if stem.contains("service")
        || stem.contains("usecase")
        || stem.contains("contract")
        || stem.contains("configuration")
        || stem.contains("carrier")
        || stem.contains("orchestrator")
        || stem.contains("workerattempt")
        || stem.contains("dispatchpreflight") {
        buckets.insert(.application)
    }
    if stem.contains("startupflow")
        || stem.contains("cli")
        || stem.contains("bootstrap")
        || stemTokens.contains("main")
        || path.contains("/app/")
        || modules.contains("SymphonyCLI") {
        buckets.insert(.app)
    }

    if buckets.isEmpty {
        let families = runtimeResponsibilityFamilies(in: file)
        for family in families {
            switch family {
            case .application:
                buckets.insert(.application)
            case .infrastructure:
                buckets.insert(.infrastructure)
            case .domain:
                buckets.insert(.domain)
            case .presentation:
                buckets.insert(.presentation)
            case .app:
                buckets.insert(.app)
            }
        }
    }

    return RuntimeTestBucket.allCases.filter { buckets.contains($0) }
}

private func runtimeResponsibilityFamilies(in file: ArchitectureFile) -> [RuntimeResponsibilityFamily] {
    let stem = file.classification.fileStem.lowercased()
    let stemTokens = identifierTokens(from: file.classification.fileStem)
    let methodTokens = testMethodTokens(in: file)
    let path = file.repoRelativePath.lowercased()
    let modules = importedModules(in: file)

    var families = Set<RuntimeResponsibilityFamily>()

    if stem.contains("gateway")
        || stem.contains("portadapter")
        || stem.contains("workspacelifecycle")
        || stem.contains("reloadmonitor")
        || stem.contains("tracker")
        || methodTokens.contains("gateway")
        || methodTokens.contains("portadapter")
        || path.contains("/infrastructure/")
        || path.contains("/testdoubles/") && stem.contains("gateway")
    {
        families.insert(.infrastructure)
    }

    if stem.contains("policy") || path.contains("/domain/") {
        families.insert(.domain)
    }

    if !stem.contains("portadapter")
        && (stem.contains("controller")
            || stem.contains("renderer")
            || stem.contains("dto")
            || stem.contains("presenter")
            || stem.contains("view")
            || methodTokens.contains("controller")
            || methodTokens.contains("renderer")
            || methodTokens.contains("dto")
            || methodTokens.contains("presenter")
            || methodTokens.contains("view")
            || path.contains("/presentation/")) {
        families.insert(.presentation)
    }

    if stem.contains("service")
        || stem.contains("usecase")
        || stem.contains("dispatchpreflight")
        || stem.contains("contract")
        || stem.contains("configuration")
        || stem.contains("carrier")
        || stem.contains("orchestrator")
        || stem.contains("workerattempt")
        || methodTokens.contains("service")
        || methodTokens.contains("usecase")
        || methodTokens.contains("contract")
        || methodTokens.contains("configuration")
        || methodTokens.contains("carrier")
        || methodTokens.contains("orchestrator")
        || path.contains("/application/") {
        families.insert(.application)
    }

    if stem.contains("startupflow")
        || stem.contains("cliruntime")
        || stem.contains("bootstrap")
        || stemTokens.contains("main")
        || path.contains("/app/")
        || modules.contains("SymphonyCLI") {
        families.insert(.app)
    }

    return RuntimeResponsibilityFamily.allCases.filter { families.contains($0) }
}

private func identifierTokens(from value: String) -> Set<String> {
    var tokens: [String] = []
    var current = ""

    for character in value {
        if character.isLetter || character.isNumber {
            if character.isUppercase && !current.isEmpty {
                tokens.append(current.lowercased())
                current = String(character)
            } else {
                current.append(character)
            }
        } else if !current.isEmpty {
            tokens.append(current.lowercased())
            current = ""
        }
    }

    if !current.isEmpty {
        tokens.append(current.lowercased())
    }

    return Set(tokens.filter { !$0.isEmpty })
}

private func testMethodTokens(in file: ArchitectureFile) -> Set<String> {
    Set(
        file.methodDeclarations
            .flatMap { identifierTokens(from: $0.name) }
    )
}

private func supportNominalDeclarations(in file: ArchitectureFile) -> [ArchitectureNestedNominalDeclaration] {
    file.nestedNominalDeclarations.filter { declaration in
        isSupportTypeName(declaration.name)
    }
}

private func supportHelperMethods(in file: ArchitectureFile) -> [ArchitectureMethodDeclaration] {
    file.methodDeclarations.filter { declaration in
        declaration.isPrivateOrFileprivate && isSupportHelperName(declaration.name)
    }
}

private func harnessSupportDeclarations(in file: ArchitectureFile) -> [ArchitectureNestedNominalDeclaration] {
    file.nestedNominalDeclarations.filter { declaration in
        let lowercasedName = declaration.name.lowercased()
        return lowercasedName.contains("collector")
            || lowercasedName.contains("record")
            || lowercasedName.contains("fixture")
            || lowercasedName.contains("repo")
    }
}

private func harnessSupportMethods(in file: ArchitectureFile) -> [ArchitectureMethodDeclaration] {
    file.methodDeclarations.filter { declaration in
        declaration.isPrivateOrFileprivate && isHarnessHelperName(declaration.name)
    }
}

private func isSupportTypeName(_ name: String) -> Bool {
    let lowercasedName = name.lowercased()
    return lowercasedName.hasSuffix("spy")
        || lowercasedName.hasSuffix("fake")
        || lowercasedName.hasSuffix("builder")
        || lowercasedName.hasSuffix("fixture")
        || lowercasedName.hasSuffix("support")
        || lowercasedName.hasSuffix("transport")
        || lowercasedName.hasSuffix("environment")
        || lowercasedName.hasSuffix("recorder")
}

private func isSupportHelperName(_ name: String) -> Bool {
    let lowercasedName = name.lowercased()
    return lowercasedName.hasPrefix("make")
        || lowercasedName.hasPrefix("temporary")
        || lowercasedName.hasPrefix("capture")
        || lowercasedName.hasPrefix("withtemporary")
        || lowercasedName.hasPrefix("waitfor")
        || lowercasedName.hasPrefix("replace")
}

private func isHarnessHelperName(_ name: String) -> Bool {
    let lowercasedName = name.lowercased()
    return lowercasedName == "lint"
        || lowercasedName == "maketemporaryrepo"
        || lowercasedName == "buildprojectcontext"
        || lowercasedName == "loadsourcefile"
        || lowercasedName == "makereporelativepath"
        || lowercasedName.hasPrefix("collect")
        || lowercasedName == "hasmodifier"
        || lowercasedName == "extractedtypenames"
        || lowercasedName == "isvoidlike"
        || lowercasedName == "rootbasename"
}
