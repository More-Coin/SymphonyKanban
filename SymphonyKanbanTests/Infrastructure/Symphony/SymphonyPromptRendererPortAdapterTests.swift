import Foundation
import Testing
@testable import SymphonyKanban

struct SymphonyPromptRendererPortAdapterTests {
    @Test
    func renderPromptInterpolatesIssueFieldsAndIteratesCollections() throws {
        let workflowDefinition = SymphonyWorkflowDefinitionContract(
            resolvedPath: "/tmp/WORKFLOW.md",
            config: [:],
            promptTemplate: """
            Issue {{ issue.identifier }}: {{ issue.title }}
            Labels:{% for label in issue.labels %}[{{ label }}]{% endfor %}
            Blockers:{% for blocker in issue.blockedBy %}[{{ blocker.identifier }}:{{ blocker.state }}]{% endfor %}
            Attempt={{ attempt }}
            """
        )
        let useCase = RenderSymphonyPromptUseCase(
            promptRendererPort: SymphonyPromptRendererPortAdapter()
        )

        let result = try useCase.renderPrompt(
            using: SymphonyPromptRenderRequestContract(
                workflowDefinition: workflowDefinition,
                issue: issue(),
                attempt: 3
            )
        )

        #expect(result.prompt.contains("Issue ABC-123: Fix prompt renderer"))
        #expect(result.prompt.contains("Labels:[bug][needs-review]"))
        #expect(result.prompt.contains("Blockers:[ABC-1:Done][ABC-2:]"))
        #expect(result.prompt.contains("Attempt=3"))
    }

    @Test
    func renderPromptTreatsFirstAttemptAsNullSafe() throws {
        let workflowDefinition = SymphonyWorkflowDefinitionContract(
            resolvedPath: "/tmp/WORKFLOW.md",
            config: [:],
            promptTemplate: "Attempt={{ attempt }}"
        )
        let useCase = RenderSymphonyPromptUseCase(
            promptRendererPort: SymphonyPromptRendererPortAdapter()
        )

        let result = try useCase.renderPrompt(
            using: SymphonyPromptRenderRequestContract(
                workflowDefinition: workflowDefinition,
                issue: issue(),
                attempt: nil
            )
        )

        #expect(result.prompt == "Attempt=")
    }

    @Test
    func renderPromptFailsUnknownVariableAsRenderError() throws {
        let adapter = SymphonyPromptRendererPortAdapter()

        do {
            _ = try adapter.renderPromptTemplate(
                "Hello {{ issue.missingField }}",
                issue: issue(),
                attempt: nil
            )
            Issue.record("Expected a render error for an unknown variable.")
        } catch let error as SymphonyPromptInfrastructureError {
            guard case .templateRenderError(let details) = error else {
                Issue.record("Expected templateRenderError, received \(error).")
                return
            }

            #expect(details.contains("Unknown variable"))
        }
    }

    @Test
    func renderPromptFailsUnknownFilterAsRenderError() throws {
        let adapter = SymphonyPromptRendererPortAdapter()

        do {
            _ = try adapter.renderPromptTemplate(
                "Hello {{ issue.identifier | upcase }}",
                issue: issue(),
                attempt: nil
            )
            Issue.record("Expected a render error for an unknown filter.")
        } catch let error as SymphonyPromptInfrastructureError {
            guard case .templateRenderError(let details) = error else {
                Issue.record("Expected templateRenderError, received \(error).")
                return
            }

            #expect(details.contains("Unknown filter"))
        }
    }

    @Test
    func renderPromptClassifiesMalformedTemplateAsParseError() throws {
        let adapter = SymphonyPromptRendererPortAdapter()

        do {
            _ = try adapter.renderPromptTemplate(
                "{% for label in issue.labels %}{{ label }}",
                issue: issue(),
                attempt: nil
            )
            Issue.record("Expected a parse error for an unterminated loop.")
        } catch let error as SymphonyPromptInfrastructureError {
            guard case .templateParseError(let details) = error else {
                Issue.record("Expected templateParseError, received \(error).")
                return
            }

            #expect(details.contains("Missing `endfor`"))
        }
    }

    @Test
    func renderPromptFallsBackToDefaultPromptWhenWorkflowBodyIsEmpty() throws {
        let workflowDefinition = SymphonyWorkflowDefinitionContract(
            resolvedPath: "/tmp/WORKFLOW.md",
            config: [:],
            promptTemplate: "   \n  "
        )
        let useCase = RenderSymphonyPromptUseCase(
            promptRendererPort: SymphonyPromptRendererPortAdapter()
        )

        let result = try useCase.renderPrompt(
            using: SymphonyPromptRenderRequestContract(
                workflowDefinition: workflowDefinition,
                issue: issue(),
                attempt: nil
            )
        )

        #expect(result.prompt == "You are working on an issue from Linear.")
    }

    private func issue() -> SymphonyIssue {
        SymphonyIssue(
            id: "issue-123",
            identifier: "ABC-123",
            title: "Fix prompt renderer",
            description: "Prompt body",
            priority: 2,
            state: "Todo",
            branchName: "feature/abc-123",
            url: "https://linear.app/ABC-123",
            labels: ["Bug", "Needs-Review"],
            blockedBy: [
                SymphonyIssueBlockerReference(id: "blocker-1", identifier: "ABC-1", state: "Done"),
                SymphonyIssueBlockerReference(id: "blocker-2", identifier: "ABC-2", state: nil)
            ],
            createdAt: Date(timeIntervalSince1970: 1_710_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_710_003_600)
        )
    }
}
