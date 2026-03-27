import Foundation

enum SymphonyPromptTemplateNode: Equatable {
    case text(String)
    case variable(SymphonyPromptTemplateExpression)
    case loop(
        itemName: String,
        collection: SymphonyPromptTemplateExpression,
        body: [SymphonyPromptTemplateNode]
    )
}

struct SymphonyPromptTemplateExpression: Equatable {
    let path: [String]
    let filters: [String]
}

enum SymphonyPromptTemplateValue: Equatable {
    case null
    case string(String)
    case integer(Int)
    case bool(Bool)
    case array([SymphonyPromptTemplateValue])
    case object([String: SymphonyPromptTemplateValue])
}

struct SymphonyPromptTemplateContext {
    let scopes: [[String: SymphonyPromptTemplateValue]]
}

struct SymphonyPromptTemplateContextBuilder {
    private let dateFormatter: ISO8601DateFormatter

    init(dateFormatter: ISO8601DateFormatter = ISO8601DateFormatter()) {
        self.dateFormatter = dateFormatter
    }

    func makeContext(
        issue: SymphonyIssue,
        attempt: Int?
    ) -> SymphonyPromptTemplateContext {
        SymphonyPromptTemplateContext(
            scopes: [[
                "issue": makeIssueContext(issue),
                "attempt": attempt.map(SymphonyPromptTemplateValue.integer) ?? .null
            ]]
        )
    }

    private func makeIssueContext(_ issue: SymphonyIssue) -> SymphonyPromptTemplateValue {
        .object([
            "id": .string(issue.id),
            "identifier": .string(issue.identifier),
            "title": .string(issue.title),
            "description": issue.description.map(SymphonyPromptTemplateValue.string) ?? .null,
            "priority": issue.priority.map(SymphonyPromptTemplateValue.integer) ?? .null,
            "state": .string(issue.state),
            "branchName": issue.branchName.map(SymphonyPromptTemplateValue.string) ?? .null,
            "url": issue.url.map(SymphonyPromptTemplateValue.string) ?? .null,
            "labels": .array(issue.labels.map(SymphonyPromptTemplateValue.string)),
            "blockedBy": .array(issue.blockedBy.map(makeBlockerContext)),
            "createdAt": issue.createdAt.map(formattedDateValue) ?? .null,
            "updatedAt": issue.updatedAt.map(formattedDateValue) ?? .null
        ])
    }

    private func makeBlockerContext(
        _ blocker: SymphonyIssueBlockerReference
    ) -> SymphonyPromptTemplateValue {
        .object([
            "id": blocker.id.map(SymphonyPromptTemplateValue.string) ?? .null,
            "identifier": blocker.identifier.map(SymphonyPromptTemplateValue.string) ?? .null,
            "state": blocker.state.map(SymphonyPromptTemplateValue.string) ?? .null
        ])
    }

    private func formattedDateValue(_ date: Date) -> SymphonyPromptTemplateValue {
        .string(dateFormatter.string(from: date))
    }
}

struct SymphonyPromptTemplateParser {
    func parse(_ source: String) throws -> [SymphonyPromptTemplateNode] {
        var parser = Parser(source: source)
        return try parser.parse()
    }
}

private extension SymphonyPromptTemplateParser {
    struct Parser {
        private let source: String
        private var index: String.Index

        init(source: String) {
            self.source = source
            self.index = source.startIndex
        }

        mutating func parse() throws -> [SymphonyPromptTemplateNode] {
            try parseNodes(terminatingOnEndFor: false)
        }

        private mutating func parseNodes(
            terminatingOnEndFor: Bool
        ) throws -> [SymphonyPromptTemplateNode] {
            var nodes: [SymphonyPromptTemplateNode] = []

            while index < source.endIndex {
                if starts(with: "{{") {
                    nodes.append(.variable(try parseVariable()))
                    continue
                }

                if starts(with: "{%") {
                    let tagContent = try parseDelimitedContent(
                        openingDelimiter: "{%",
                        closingDelimiter: "%}"
                    )
                    let normalizedTag = tagContent.trimmingCharacters(in: .whitespacesAndNewlines)

                    if normalizedTag == "endfor" {
                        guard terminatingOnEndFor else {
                            throw SymphonyPromptInfrastructureError.templateParseError(
                                details: "Unexpected `endfor` tag."
                            )
                        }
                        return nodes
                    }

                    guard normalizedTag.hasPrefix("for ") else {
                        throw SymphonyPromptInfrastructureError.templateParseError(
                            details: "Unsupported control tag `\(normalizedTag)`."
                        )
                    }

                    let loop = try parseLoop(tag: normalizedTag)
                    let body = try parseNodes(terminatingOnEndFor: true)
                    nodes.append(
                        .loop(
                            itemName: loop.itemName,
                            collection: loop.collection,
                            body: body
                        )
                    )
                    continue
                }

                nodes.append(.text(parseText()))
            }

            if terminatingOnEndFor {
                throw SymphonyPromptInfrastructureError.templateParseError(
                    details: "Missing `endfor` tag."
                )
            }

            return nodes
        }

        private mutating func parseVariable() throws -> SymphonyPromptTemplateExpression {
            try parseExpression(
                parseDelimitedContent(
                    openingDelimiter: "{{",
                    closingDelimiter: "}}"
                )
            )
        }

        private mutating func parseLoop(
            tag: String
        ) throws -> (
            itemName: String,
            collection: SymphonyPromptTemplateExpression
        ) {
            let components = tag.split(
                separator: " ",
                omittingEmptySubsequences: true
            )

            guard components.count >= 4,
                  components[0] == "for",
                  components[2] == "in" else {
                throw SymphonyPromptInfrastructureError.templateParseError(
                    details: "Malformed `for` tag `\(tag)`."
                )
            }

            let itemName = String(components[1])
            let collectionExpression = components[3...].joined(separator: " ")
            return (
                itemName: itemName,
                collection: try parseExpression(collectionExpression)
            )
        }

        private mutating func parseDelimitedContent(
            openingDelimiter: String,
            closingDelimiter: String
        ) throws -> String {
            advance(by: openingDelimiter.count)

            guard let closingRange = source[index...].range(of: closingDelimiter) else {
                throw SymphonyPromptInfrastructureError.templateParseError(
                    details: "Unterminated template tag."
                )
            }

            let content = String(source[index..<closingRange.lowerBound])
            index = closingRange.upperBound
            return content
        }

        private func parseExpression(
            _ rawExpression: String
        ) throws -> SymphonyPromptTemplateExpression {
            let parts = rawExpression
                .split(separator: "|", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

            guard let variablePart = parts.first,
                  !variablePart.isEmpty else {
                throw SymphonyPromptInfrastructureError.templateParseError(
                    details: "Template expression is empty."
                )
            }

            let path = variablePart
                .split(separator: ".", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

            guard path.allSatisfy({ !$0.isEmpty }) else {
                throw SymphonyPromptInfrastructureError.templateParseError(
                    details: "Malformed variable path `\(variablePart)`."
                )
            }

            return SymphonyPromptTemplateExpression(
                path: path,
                filters: Array(parts.dropFirst())
            )
        }

        private mutating func parseText() -> String {
            let startIndex = index

            while index < source.endIndex,
                  !starts(with: "{{"),
                  !starts(with: "{%") {
                index = source.index(after: index)
            }

            return String(source[startIndex..<index])
        }

        private func starts(with token: String) -> Bool {
            source[index...].hasPrefix(token)
        }

        private mutating func advance(by count: Int) {
            index = source.index(index, offsetBy: count)
        }
    }
}
