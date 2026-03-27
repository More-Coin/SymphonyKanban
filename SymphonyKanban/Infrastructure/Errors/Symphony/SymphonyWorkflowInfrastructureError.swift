import Foundation

public enum SymphonyWorkflowInfrastructureError: StructuredErrorProtocol, LocalizedError {
    case missingWorkflowFile(path: String)
    case workflowParseError(details: String)
    case workflowFrontMatterNotAMap

    public var code: String {
        switch self {
        case .missingWorkflowFile:
            return "symphony.workflow.missing_workflow_file"
        case .workflowParseError:
            return "symphony.workflow.workflow_parse_error"
        case .workflowFrontMatterNotAMap:
            return "symphony.workflow.workflow_front_matter_not_a_map"
        }
    }

    public var message: String {
        switch self {
        case .missingWorkflowFile:
            return "The workflow file could not be found or read."
        case .workflowParseError:
            return "The workflow file front matter could not be parsed."
        case .workflowFrontMatterNotAMap:
            return "The workflow front matter must decode to a root map."
        }
    }

    public var retryable: Bool {
        false
    }

    public var details: String? {
        switch self {
        case .missingWorkflowFile(let path):
            return "Path: \(path)"
        case .workflowParseError(let details):
            return details
        case .workflowFrontMatterNotAMap:
            return nil
        }
    }

    public var errorDescription: String? {
        message
    }
}
