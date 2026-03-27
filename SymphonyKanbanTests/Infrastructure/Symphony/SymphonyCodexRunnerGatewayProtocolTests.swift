import Foundation
import Testing
@testable import SymphonyKanban

@Suite(.serialized)
struct SymphonyCodexRunnerGatewayProtocolTests {
    @Test
    func startSessionSendsHandshakeInOrderAndAppliesAcceptedPosture() async throws {
        let transport = CodexRunnerFakeTransport(outputs: [
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":1,"result":{}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":2,"result":{"requirements":null}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":3,"result":{"thread":{"id":"thread-123"}}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":4,"result":{"turn":{"id":"turn-456"}}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"method":"turn/started","params":{"turn":{"id":"turn-456"}}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"method":"thread/tokenUsage/updated","params":{"usage":{"inputTokens":12,"outputTokens":8,"totalTokens":20},"rateLimits":{"remaining":5}}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"method":"turn/completed","params":{"status":"completed"}}"#)
        ])
        let gateway = SymphonyCodexRunnerGatewayTestSupport.makeGateway(using: transport)
        let startup = SymphonyCodexRunnerGatewayTestSupport.makeStartupContract()
        let events = CodexRunnerEventRecorder()

        let result = try await gateway.startSession(
            using: startup,
            onEvent: { events.record($0) }
        )

        let payloads = try transport.sentPayloads()
        #expect(payloads.map { $0.method ?? "" } == [
            "initialize",
            "initialized",
            "configRequirements/read",
            "thread/start",
            "turn/start"
        ])
        #expect(payloads[3].params?["approvalPolicy"] as? String == "never")
        #expect(payloads[3].params?["sandbox"] as? String == "workspaceWrite")
        #expect(payloads[3].params?["serviceName"] as? String == "symphony")
        #expect(payloads[4].params?["approvalPolicy"] as? String == "unlessTrusted")
        let sandboxPolicy = try #require(payloads[4].params?["sandboxPolicy"] as? [String: Any])
        #expect(sandboxPolicy["type"] as? String == "workspaceWrite")
        #expect(sandboxPolicy["networkAccess"] as? Bool == false)
        #expect(sandboxPolicy["writableRoots"] as? [String] == ["/tmp/symphony_workspaces/ABC-123"])
        #expect(result.session.threadID == "thread-123")
        #expect(result.session.turnID == "turn-456")
        #expect(result.session.sessionID == "thread-123-turn-456")
        #expect(result.outcome == .completed)
        #expect(result.usage == SymphonyCodexUsageSnapshotContract(
            inputTokens: 12,
            outputTokens: 8,
            totalTokens: 20
        ))
        #expect(result.rateLimits == SymphonyCodexRateLimitSnapshotContract(
            payload: .object([
                "remaining": .integer(5)
            ])
        ))
        #expect(events.values().contains { $0.kind == .sessionStarted })
    }

    @Test
    func startSessionBuffersPartialStdoutLinesAndIgnoresStderrForProtocolParsing() async throws {
        let transport = CodexRunnerFakeTransport(outputs: [
            .stdout(Data(#"{"id":1,"res"#.utf8)),
            .stderr(Data("codex diagnostic\n".utf8)),
            .stdout(Data((#"ult":{}}"# + "\n").utf8)),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":2,"result":{"requirements":null}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":3,"result":{"thread":{"id":"thread-123"}}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":4,"result":{"turn":{"id":"turn-456"}}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"method":"turn/completed","params":{"status":"completed"}}"#)
        ])
        let gateway = SymphonyCodexRunnerGatewayTestSupport.makeGateway(using: transport)
        let events = CodexRunnerEventRecorder()

        let result = try await gateway.startSession(
            using: SymphonyCodexRunnerGatewayTestSupport.makeStartupContract(),
            onEvent: { events.record($0) }
        )

        #expect(result.outcome == .completed)
        #expect(events.values().contains {
            $0.kind == .otherMessage && $0.message == "codex diagnostic"
        })
    }

    @Test
    func startSessionAutoApprovesDistinctApprovalRequestsAndRejectsUnsupportedTools() async throws {
        let transport = CodexRunnerFakeTransport(outputs: [
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":1,"result":{}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":2,"result":{"requirements":null}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":3,"result":{"thread":{"id":"thread-123"}}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":4,"result":{"turn":{"id":"turn-456"}}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":"cmd-1","method":"item/commandExecution/requestApproval","params":{"allowedDecisions":["accept","acceptForSession"]}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":"file-1","method":"item/fileChange/requestApproval","params":{"allowedDecisions":["accept"]}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":"tool-1","method":"item/tool/call","params":{"toolName":"unknown_tool"}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"method":"turn/completed","params":{"status":"completed"}}"#)
        ])
        let gateway = SymphonyCodexRunnerGatewayTestSupport.makeGateway(using: transport)
        let events = CodexRunnerEventRecorder()

        let result = try await gateway.startSession(
            using: SymphonyCodexRunnerGatewayTestSupport.makeStartupContract(),
            onEvent: { events.record($0) }
        )

        let payloads = try transport.sentPayloads()
        let commandApproval = try #require(payloads.first(where: { $0.idString == "cmd-1" }))
        let fileApproval = try #require(payloads.first(where: { $0.idString == "file-1" }))
        let toolFailure = try #require(payloads.first(where: { $0.idString == "tool-1" }))

        #expect(commandApproval.result?["decision"] as? String == "acceptForSession")
        #expect(fileApproval.result?["decision"] as? String == "accept")
        #expect(toolFailure.result?["success"] as? Bool == false)
        #expect(toolFailure.result?["error"] as? String == "unsupported_tool_call")
        #expect(result.outcome == .completed)
        #expect(events.values().contains { $0.kind == .approvalAutoApproved && $0.requestKind == .commandExecutionApproval })
        #expect(events.values().contains { $0.kind == .approvalAutoApproved && $0.requestKind == .fileChangeApproval })
        #expect(events.values().contains { $0.kind == .unsupportedToolCall })
    }

    @Test
    func startSessionTreatsUserInputRequestAsHardFailureAndClearsPendingRequest() async throws {
        let transport = CodexRunnerFakeTransport(outputs: [
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":1,"result":{}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":2,"result":{"requirements":null}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":3,"result":{"thread":{"id":"thread-123"}}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":4,"result":{"turn":{"id":"turn-456"}}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":"input-1","method":"tool/requestUserInput","params":{"prompt":"Need approval"}}"#)
        ])
        let gateway = SymphonyCodexRunnerGatewayTestSupport.makeGateway(using: transport)
        let events = CodexRunnerEventRecorder()

        do {
            _ = try await gateway.startSession(
                using: SymphonyCodexRunnerGatewayTestSupport.makeStartupContract(),
                onEvent: { events.record($0) }
            )
            Issue.record("Expected input-required runtime error.")
        } catch let error as SymphonyAgentRuntimeApplicationError {
            #expect(error.code == "symphony.agent_runtime.input_required")
        }

        let payloads = try transport.sentPayloads()
        let clearedRequest = try #require(payloads.first(where: { $0.idString == "input-1" }))
        let errorPayload = try #require(clearedRequest.error)

        #expect(errorPayload["code"] as? String == "turn_input_required")
        #expect(events.values().contains { $0.kind == .turnInputRequired })
    }

    @Test
    func startSessionFailsExplicitlyWhenRequirementsDisallowDocumentedPosture() async throws {
        let transport = CodexRunnerFakeTransport(outputs: [
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":1,"result":{}}"#),
            SymphonyCodexRunnerGatewayTestSupport.stdoutLine(#"{"id":2,"result":{"requirements":{"allowedApprovalPolicies":["on-request"],"allowedSandboxModes":["workspaceWrite"]}}}"#)
        ])
        let gateway = SymphonyCodexRunnerGatewayTestSupport.makeGateway(using: transport)
        let events = CodexRunnerEventRecorder()

        do {
            _ = try await gateway.startSession(
                using: SymphonyCodexRunnerGatewayTestSupport.makeStartupContract(),
                onEvent: { events.record($0) }
            )
            Issue.record("Expected requirements-mismatch runtime error.")
        } catch let error as SymphonyAgentRuntimeApplicationError {
            #expect(error.code == "symphony.agent_runtime.requirements_mismatch")
        }

        #expect(events.values().contains { $0.kind == .startupFailed && $0.message == "symphony.codex_runner.policy_incompatible" })
    }
}
