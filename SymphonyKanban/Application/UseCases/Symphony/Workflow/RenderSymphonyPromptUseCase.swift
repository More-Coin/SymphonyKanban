import Foundation

public struct RenderSymphonyPromptUseCase {
    private static let defaultPrompt = "You are working on an issue from Linear."

    private let promptRendererPort: any SymphonyPromptRendererPortProtocol

    public init(promptRendererPort: any SymphonyPromptRendererPortProtocol) {
        self.promptRendererPort = promptRendererPort
    }

    public func renderPrompt(
        using request: SymphonyPromptRenderRequestContract
    ) throws -> SymphonyPromptRenderResultContract {
        let promptTemplate = request.workflowDefinition.promptTemplate
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !promptTemplate.isEmpty else {
            return SymphonyPromptRenderResultContract(prompt: Self.defaultPrompt)
        }

        return SymphonyPromptRenderResultContract(
            prompt: try promptRendererPort.renderPromptTemplate(
                promptTemplate,
                issue: request.issue,
                attempt: request.attempt
            )
        )
    }
}
