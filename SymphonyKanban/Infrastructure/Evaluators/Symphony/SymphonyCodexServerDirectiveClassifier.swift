struct SymphonyCodexServerDirectiveClassifier {
    enum Selection: Equatable, Sendable {
        case approval(SymphonyCodexServerRequestKindContract)
        case unsupportedToolCall
        case userInputRequested
        case unhandled
    }

    func classify(_ message: SymphonyCodexProtocolMessageDTO) -> Selection {
        guard message.id != nil else {
            return .unhandled
        }

        switch message.method {
        case "item/commandExecution/requestApproval":
            return .approval(.commandExecutionApproval)
        case "item/fileChange/requestApproval":
            return .approval(.fileChangeApproval)
        case "item/tool/call":
            return .unsupportedToolCall
        case "tool/requestUserInput":
            return .userInputRequested
        default:
            return .unhandled
        }
    }
}
