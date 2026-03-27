import Foundation

public enum SymphonyPromptInfrastructureError: StructuredErrorProtocol, LocalizedError {
    case templateParseError(details: String)
    case templateRenderError(details: String)

    public var code: String {
        switch self {
        case .templateParseError:
            return "symphony.prompt.template_parse_error"
        case .templateRenderError:
            return "symphony.prompt.template_render_error"
        }
    }

    public var message: String {
        switch self {
        case .templateParseError:
            return "The workflow prompt template could not be parsed."
        case .templateRenderError:
            return "The workflow prompt template could not be rendered."
        }
    }

    public var retryable: Bool {
        false
    }

    public var details: String? {
        switch self {
        case .templateParseError(let details), .templateRenderError(let details):
            return details
        }
    }

    public var errorDescription: String? {
        message
    }
}
