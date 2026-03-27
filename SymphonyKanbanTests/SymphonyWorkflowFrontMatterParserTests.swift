import Foundation
import Testing
@testable import SymphonyKanban

struct SymphonyWorkflowFrontMatterParserTests {
    @Test func parsesNestedConfigAndPromptBody() throws {
        let source = """
        ---
        tracker:
          kind: linear
          endpoint: https://api.linear.app/graphql
          active_states:
            - Todo
            - In Progress
        agent:
          max_concurrent_agents: 12
          max_concurrent_agents_by_state:
            todo: 2
            in progress: 4
        codex:
          turn_sandbox_policy:
            writableRoots: ["/tmp/work", "~/repo"]
            readOnlyAccess: true
        ---
        # Prompt

        Work the issue carefully.
        """

        let result = try SymphonyWorkflowFrontMatterParser().parse(source)

        #expect(result.promptTemplate == "# Prompt\n\nWork the issue carefully.")
        #expect(result.config["tracker"]?.dictionaryValue?["kind"]?.stringValue == "linear")
        #expect(
            result.config["tracker"]?.dictionaryValue?["active_states"]?.arrayValue?.count == 2
        )
        #expect(result.config["agent"]?.dictionaryValue?["max_concurrent_agents"]?.integerValue == 12)
        #expect(
            result.config["codex"]?.dictionaryValue?["turn_sandbox_policy"]?.dictionaryValue?["readOnlyAccess"] == .bool(true)
        )
        #expect(
            result.config["codex"]?.dictionaryValue?["turn_sandbox_policy"]?.dictionaryValue?["writableRoots"]?.arrayValue?.count == 2
        )
    }

    @Test func parsesLiteralBlockScalarHooks() throws {
        let source = """
        ---
        hooks:
          before_run: |
            echo first
            echo second
        ---
        Prompt body
        """

        let result = try SymphonyWorkflowFrontMatterParser().parse(source)

        #expect(
            result.config["hooks"]?.dictionaryValue?["before_run"]?.stringValue
                == "echo first\necho second"
        )
    }

    @Test func rejectsMissingFrontMatterDelimiter() throws {
        let source = """
        ---
        tracker:
          kind: linear
        """

        do {
            _ = try SymphonyWorkflowFrontMatterParser().parse(source)
            Issue.record("Expected workflow parsing to fail.")
        } catch let error as SymphonyWorkflowInfrastructureError {
            switch error {
            case .workflowParseError(let details):
                #expect(details.contains("Missing closing front matter delimiter"))
            default:
                Issue.record("Unexpected error: \(error)")
            }
        }
    }
}
