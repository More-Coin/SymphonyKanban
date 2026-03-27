public struct SymphonyPromptRenderResultContract: Equatable, Sendable {
    public let prompt: String

    public init(prompt: String) {
        self.prompt = prompt
    }
}
