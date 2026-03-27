import Foundation

public struct SymphonyPromptRendererPortAdapter: SymphonyPromptRendererPortProtocol {
    public init() {}

    public func renderPromptTemplate(
        _ promptTemplate: String,
        issue: SymphonyIssue,
        attempt: Int?
    ) throws -> String {
        let nodes = try SymphonyPromptTemplateParser().parse(promptTemplate)
        let context = SymphonyPromptTemplateContextBuilder().makeContext(
            issue: issue,
            attempt: attempt
        )

        return try render(
            nodes: nodes,
            scopes: context.scopes
        )
    }

    private func render(
        nodes: [SymphonyPromptTemplateNode],
        scopes: [[String: SymphonyPromptTemplateValue]]
    ) throws -> String {
        var rendered = ""

        for node in nodes {
            switch node {
            case .text(let text):
                rendered += text
            case .variable(let expression):
                rendered += try renderValue(
                    try resolve(expression: expression, scopes: scopes)
                )
            case .loop(let itemName, let collectionExpression, let body):
                let collectionValue = try resolve(
                    expression: collectionExpression,
                    scopes: scopes
                )

                guard case .array(let values) = collectionValue else {
                    throw SymphonyPromptInfrastructureError.templateRenderError(
                        details: "Loop collection `\(collectionExpression.path.joined(separator: "."))` is not iterable."
                    )
                }

                for value in values {
                    var nestedScopes = scopes
                    nestedScopes.append([itemName: value])
                    rendered += try render(
                        nodes: body,
                        scopes: nestedScopes
                    )
                }
            }
        }

        return rendered
    }

    private func resolve(
        expression: SymphonyPromptTemplateExpression,
        scopes: [[String: SymphonyPromptTemplateValue]]
    ) throws -> SymphonyPromptTemplateValue {
        guard expression.filters.isEmpty else {
            throw SymphonyPromptInfrastructureError.templateRenderError(
                details: "Unknown filter `\(expression.filters[0])`."
            )
        }

        guard let firstSegment = expression.path.first else {
            throw SymphonyPromptInfrastructureError.templateRenderError(
                details: "The template expression is empty."
            )
        }

        var resolvedValue: SymphonyPromptTemplateValue?
        for scope in scopes.reversed() where scope[firstSegment] != nil {
            resolvedValue = scope[firstSegment]
            break
        }

        guard var currentValue = resolvedValue else {
            throw SymphonyPromptInfrastructureError.templateRenderError(
                details: "Unknown variable `\(firstSegment)`."
            )
        }

        for segment in expression.path.dropFirst() {
            guard case .object(let object) = currentValue,
                  let nestedValue = object[segment] else {
                throw SymphonyPromptInfrastructureError.templateRenderError(
                    details: "Unknown variable `\(expression.path.joined(separator: "."))`."
                )
            }

            currentValue = nestedValue
        }

        return currentValue
    }

    private func renderValue(_ value: SymphonyPromptTemplateValue) throws -> String {
        switch value {
        case .null:
            return ""
        case .string(let value):
            return value
        case .integer(let value):
            return String(value)
        case .bool(let value):
            return value ? "true" : "false"
        case .array, .object:
            throw SymphonyPromptInfrastructureError.templateRenderError(
                details: "Composite values must be iterated instead of rendered directly."
            )
        }
    }
}
