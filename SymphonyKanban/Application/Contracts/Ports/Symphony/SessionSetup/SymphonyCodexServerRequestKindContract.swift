public enum SymphonyCodexServerRequestKindContract: String, Equatable, Sendable {
    case commandExecutionApproval = "command_execution_approval"
    case fileChangeApproval = "file_change_approval"
    case toolRequestUserInput = "tool_request_user_input"
    case dynamicToolCall = "dynamic_tool_call"
}
