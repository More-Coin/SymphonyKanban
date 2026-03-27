import Foundation

public struct KanbanArchitectureLintWorkflowContract {
    public let rootURL: URL
    public let diagnosticRulePrefix: String?

    public init(rootURL: URL, diagnosticRulePrefix: String? = nil) {
        self.rootURL = rootURL
        self.diagnosticRulePrefix = diagnosticRulePrefix
    }
}
