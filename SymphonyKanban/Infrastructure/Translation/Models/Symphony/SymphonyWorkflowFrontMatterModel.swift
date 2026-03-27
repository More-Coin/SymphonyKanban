import Foundation

struct SymphonyWorkflowFrontMatterContext: Equatable {
    let config: [String: SymphonyConfigValueContract]
    let promptTemplate: String
}

struct SymphonyWorkflowFrontMatterParser {
    func parse(_ source: String) throws -> SymphonyWorkflowFrontMatterContext {
        guard source.hasPrefix("---") else {
            return SymphonyWorkflowFrontMatterContext(
                config: [:],
                promptTemplate: source.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        let lines = source.components(separatedBy: .newlines)
        guard let closingIndex = lines.dropFirst().firstIndex(
            where: { $0.trimmingCharacters(in: .whitespaces) == "---" }
        ) else {
            throw SymphonyWorkflowInfrastructureError.workflowParseError(
                details: "Missing closing front matter delimiter."
            )
        }

        let frontMatter = lines[1..<closingIndex].joined(separator: "\n")
        let promptTemplate = lines[(closingIndex + 1)...]
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        var parser = Parser(source: frontMatter)
        return SymphonyWorkflowFrontMatterContext(
            config: try parser.parseRootObject(),
            promptTemplate: promptTemplate
        )
    }
}

private extension SymphonyWorkflowFrontMatterParser {
    struct Parser {
        private let lines: [RawLine]
        private var index: Int = 0

        init(source: String) {
            self.lines = source.components(separatedBy: .newlines).enumerated().map {
                RawLine(number: $0.offset + 1, text: $0.element)
            }
        }

        mutating func parseRootObject() throws -> [String: SymphonyConfigValueContract] {
            skipIgnorableLines()
            guard let line = peekMeaningfulLine() else {
                return [:]
            }

            let value = try parseBlock(expectedIndent: try indentation(of: line))
            skipIgnorableLines()

            guard index == lines.count else {
                throw parseError("Unexpected trailing front matter content.")
            }

            guard case .object(let object) = value else {
                throw SymphonyWorkflowInfrastructureError.workflowFrontMatterNotAMap
            }

            return object
        }

        private mutating func parseBlock(
            expectedIndent: Int
        ) throws -> SymphonyConfigValueContract {
            skipIgnorableLines()

            guard let line = peekMeaningfulLine() else {
                throw parseError("Expected front matter content.")
            }

            let lineIndent = try indentation(of: line)
            guard lineIndent == expectedIndent else {
                throw parseError(
                    "Invalid indentation on line \(line.number)."
                )
            }

            if sanitized(line.text).trimmingCharacters(in: .whitespaces).hasPrefix("-") {
                return try parseArray(expectedIndent: expectedIndent)
            }

            return try parseObject(expectedIndent: expectedIndent)
        }

        private mutating func parseObject(
            expectedIndent: Int
        ) throws -> SymphonyConfigValueContract {
            var object: [String: SymphonyConfigValueContract] = [:]

            while true {
                skipIgnorableLines()
                guard let line = peekMeaningfulLine() else {
                    break
                }

                let lineIndent = try indentation(of: line)
                if lineIndent < expectedIndent {
                    break
                }

                guard lineIndent == expectedIndent else {
                    throw parseError("Unexpected indentation on line \(line.number).")
                }

                let content = sanitized(line.text).trimmingCharacters(in: .whitespaces)
                guard !content.hasPrefix("-") else {
                    throw parseError("Mixed map and list syntax on line \(line.number).")
                }

                guard let separatorIndex = firstUnquotedColon(in: content) else {
                    throw parseError("Expected `key: value` on line \(line.number).")
                }

                let key = content[..<separatorIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                guard !key.isEmpty else {
                    throw parseError("Missing key on line \(line.number).")
                }

                let remainder = content[content.index(after: separatorIndex)...]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                index += 1

                object[String(key)] = try parseValue(
                    remainder,
                    parentIndent: expectedIndent,
                    lineNumber: line.number
                )
            }

            return .object(object)
        }

        private mutating func parseArray(
            expectedIndent: Int
        ) throws -> SymphonyConfigValueContract {
            var values: [SymphonyConfigValueContract] = []

            while true {
                skipIgnorableLines()
                guard let line = peekMeaningfulLine() else {
                    break
                }

                let lineIndent = try indentation(of: line)
                if lineIndent < expectedIndent {
                    break
                }

                guard lineIndent == expectedIndent else {
                    throw parseError("Unexpected indentation on line \(line.number).")
                }

                let content = sanitized(line.text).trimmingCharacters(in: .whitespaces)
                guard content == "-" || content.hasPrefix("- ") else {
                    break
                }

                let remainder = String(content.dropFirst())
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                index += 1

                if remainder.isEmpty {
                    skipIgnorableLines()
                    if let nextLine = peekMeaningfulLine(),
                       try indentation(of: nextLine) > expectedIndent {
                        values.append(
                            try parseBlock(expectedIndent: try indentation(of: nextLine))
                        )
                    } else {
                        values.append(.null)
                    }
                    continue
                }

                values.append(
                    try parseInlineValue(
                        remainder,
                        lineNumber: line.number
                    )
                )
            }

            return .array(values)
        }

        private mutating func parseValue(
            _ remainder: String,
            parentIndent: Int,
            lineNumber: Int
        ) throws -> SymphonyConfigValueContract {
            if remainder.isEmpty {
                skipIgnorableLines()
                if let nextLine = peekMeaningfulLine(),
                   try indentation(of: nextLine) > parentIndent {
                    return try parseBlock(expectedIndent: try indentation(of: nextLine))
                }
                return .null
            }

            if let blockScalarStyle = BlockScalarStyle(indicator: remainder) {
                return .string(
                    try parseBlockScalar(
                        style: blockScalarStyle,
                        parentIndent: parentIndent,
                        lineNumber: lineNumber
                    )
                )
            }

            return try parseInlineValue(remainder, lineNumber: lineNumber)
        }

        private mutating func parseBlockScalar(
            style: BlockScalarStyle,
            parentIndent: Int,
            lineNumber: Int
        ) throws -> String {
            var contentLines: [String] = []
            var contentIndent: Int?

            while index < lines.count {
                let rawLine = lines[index]
                if rawLine.isBlank {
                    if contentIndent != nil {
                        contentLines.append("")
                    }
                    index += 1
                    continue
                }

                let lineIndent = try indentation(of: rawLine)
                if lineIndent <= parentIndent {
                    break
                }

                let resolvedIndent = contentIndent ?? lineIndent
                guard lineIndent >= resolvedIndent else {
                    throw parseError(
                        "Invalid block scalar indentation on line \(rawLine.number)."
                    )
                }

                contentIndent = resolvedIndent
                contentLines.append(String(rawLine.text.dropFirst(resolvedIndent)))
                index += 1
            }

            guard contentIndent != nil else {
                throw parseError(
                    "Expected block scalar content after line \(lineNumber)."
                )
            }

            switch style {
            case .literal:
                return contentLines.joined(separator: "\n")
            case .folded:
                return fold(lines: contentLines)
            }
        }

        private func fold(lines: [String]) -> String {
            var result = ""
            var previousWasBlank = false

            for line in lines {
                if line.isEmpty {
                    result.append("\n")
                    previousWasBlank = true
                    continue
                }

                if result.isEmpty || previousWasBlank || result.hasSuffix("\n") {
                    result.append(line)
                } else {
                    result.append(" ")
                    result.append(line)
                }

                previousWasBlank = false
            }

            return result
        }

        private func parseInlineValue(
            _ source: String,
            lineNumber: Int
        ) throws -> SymphonyConfigValueContract {
            let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("[") || trimmed.hasPrefix("{") {
                var parser = FlowValueParser(source: trimmed)
                let value = try parser.parseValue()
                guard parser.isAtEnd else {
                    throw parseError("Unexpected trailing inline YAML on line \(lineNumber).")
                }
                return value
            }

            return try parseScalar(trimmed, lineNumber: lineNumber)
        }

        private func parseScalar(
            _ source: String,
            lineNumber: Int
        ) throws -> SymphonyConfigValueContract {
            let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
            let lowercased = trimmed.lowercased()

            if lowercased == "null" || trimmed == "~" {
                return .null
            }

            if lowercased == "true" {
                return .bool(true)
            }

            if lowercased == "false" {
                return .bool(false)
            }

            if let intValue = Int(trimmed),
               !trimmed.contains(".") {
                return .integer(intValue)
            }

            if let doubleValue = Double(trimmed) {
                return .double(doubleValue)
            }

            if let quote = trimmed.first,
               (quote == "\"" || quote == "'") {
                return .string(try parseQuotedString(trimmed, lineNumber: lineNumber))
            }

            return .string(trimmed)
        }

        private func parseQuotedString(
            _ source: String,
            lineNumber: Int
        ) throws -> String {
            guard let quote = source.first,
                  source.last == quote else {
                throw parseError("Unterminated quoted string on line \(lineNumber).")
            }

            let content = source.dropFirst().dropLast()
            if quote == "'" {
                return content.replacingOccurrences(of: "''", with: "'")
            }

            var result = ""
            var isEscaping = false
            for character in content {
                if isEscaping {
                    switch character {
                    case "\"":
                        result.append("\"")
                    case "\\":
                        result.append("\\")
                    case "n":
                        result.append("\n")
                    case "r":
                        result.append("\r")
                    case "t":
                        result.append("\t")
                    default:
                        result.append(character)
                    }
                    isEscaping = false
                    continue
                }

                if character == "\\" {
                    isEscaping = true
                } else {
                    result.append(character)
                }
            }

            if isEscaping {
                throw parseError("Invalid escape sequence on line \(lineNumber).")
            }

            return result
        }

        private func sanitized(_ line: String) -> String {
            var result = ""
            var insideSingleQuotes = false
            var insideDoubleQuotes = false
            var previousCharacter: Character?

            for character in line {
                if character == "'" && !insideDoubleQuotes {
                    insideSingleQuotes.toggle()
                } else if character == "\"" && !insideSingleQuotes {
                    insideDoubleQuotes.toggle()
                } else if character == "#",
                          !insideSingleQuotes,
                          !insideDoubleQuotes,
                          previousCharacter?.isWhitespace ?? true {
                    break
                }

                result.append(character)
                previousCharacter = character
            }

            return result
        }

        private func firstUnquotedColon(
            in source: String
        ) -> String.Index? {
            var insideSingleQuotes = false
            var insideDoubleQuotes = false

            for index in source.indices {
                let character = source[index]
                if character == "'" && !insideDoubleQuotes {
                    insideSingleQuotes.toggle()
                    continue
                }

                if character == "\"" && !insideSingleQuotes {
                    insideDoubleQuotes.toggle()
                    continue
                }

                if character == ":" && !insideSingleQuotes && !insideDoubleQuotes {
                    return index
                }
            }

            return nil
        }

        private mutating func skipIgnorableLines() {
            while index < lines.count,
                  lines[index].isBlank || lines[index].isCommentOnly {
                index += 1
            }
        }

        private func peekMeaningfulLine() -> RawLine? {
            var peekIndex = index
            while peekIndex < lines.count {
                let line = lines[peekIndex]
                if line.isBlank || line.isCommentOnly {
                    peekIndex += 1
                    continue
                }
                return line
            }
            return nil
        }

        private func indentation(of line: RawLine) throws -> Int {
            var count = 0
            for character in line.text {
                if character == " " {
                    count += 1
                    continue
                }

                if character == "\t" {
                    throw parseError("Tabs are not supported for indentation on line \(line.number).")
                }

                break
            }
            return count
        }

        private func parseError(_ details: String) -> SymphonyWorkflowInfrastructureError {
            .workflowParseError(details: details)
        }
    }

    struct RawLine {
        let number: Int
        let text: String

        var isBlank: Bool {
            text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        var isCommentOnly: Bool {
            text.trimmingCharacters(in: .whitespaces).hasPrefix("#")
        }
    }

    enum BlockScalarStyle {
        case literal
        case folded

        init?(indicator: String) {
            let trimmed = indicator.trimmingCharacters(in: .whitespacesAndNewlines)
            switch trimmed {
            case "|", "|-", "|+":
                self = .literal
            case ">", ">-", ">+":
                self = .folded
            default:
                return nil
            }
        }
    }

    struct FlowValueParser {
        private let source: String
        private var index: String.Index

        init(source: String) {
            self.source = source
            self.index = source.startIndex
        }

        var isAtEnd: Bool {
            skipWhitespaceIndex(from: index) == source.endIndex
        }

        mutating func parseValue() throws -> SymphonyConfigValueContract {
            skipWhitespace()
            guard index < source.endIndex else {
                throw SymphonyWorkflowInfrastructureError.workflowParseError(
                    details: "Expected inline YAML value."
                )
            }

            if source[index] == "[" {
                return try parseArray()
            }

            if source[index] == "{" {
                return try parseObject()
            }

            return try parseScalar()
        }

        private mutating func parseArray() throws -> SymphonyConfigValueContract {
            advance()
            skipWhitespace()

            var values: [SymphonyConfigValueContract] = []
            if consumeIfCurrentCharacter(is: "]") {
                return .array(values)
            }

            while true {
                values.append(try parseValue())
                skipWhitespace()

                if consumeIfCurrentCharacter(is: "]") {
                    break
                }

                try consume(",")
            }

            return .array(values)
        }

        private mutating func parseObject() throws -> SymphonyConfigValueContract {
            advance()
            skipWhitespace()

            var object: [String: SymphonyConfigValueContract] = [:]
            if consumeIfCurrentCharacter(is: "}") {
                return .object(object)
            }

            while true {
                let key = try parseKey()
                skipWhitespace()
                try consume(":")
                let value = try parseValue()
                object[key] = value
                skipWhitespace()

                if consumeIfCurrentCharacter(is: "}") {
                    break
                }

                try consume(",")
            }

            return .object(object)
        }

        private mutating func parseKey() throws -> String {
            skipWhitespace()
            guard index < source.endIndex else {
                throw SymphonyWorkflowInfrastructureError.workflowParseError(
                    details: "Expected inline object key."
                )
            }

            if source[index] == "\"" || source[index] == "'" {
                return try parseQuotedString()
            }

            let start = index
            while index < source.endIndex,
                  source[index] != ":",
                  source[index] != "}" {
                advance()
            }

            let key = source[start..<index].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else {
                throw SymphonyWorkflowInfrastructureError.workflowParseError(
                    details: "Expected inline object key."
                )
            }
            return key
        }

        private mutating func parseScalar() throws -> SymphonyConfigValueContract {
            if source[index] == "\"" || source[index] == "'" {
                return .string(try parseQuotedString())
            }

            let start = index
            while index < source.endIndex,
                  ![",", "]", "}"].contains(source[index]) {
                advance()
            }

            let token = source[start..<index].trimmingCharacters(in: .whitespacesAndNewlines)
            let lowercased = token.lowercased()
            if lowercased == "null" || token == "~" {
                return .null
            }
            if lowercased == "true" {
                return .bool(true)
            }
            if lowercased == "false" {
                return .bool(false)
            }
            if let intValue = Int(token),
               !token.contains(".") {
                return .integer(intValue)
            }
            if let doubleValue = Double(token) {
                return .double(doubleValue)
            }
            return .string(token)
        }

        private mutating func parseQuotedString() throws -> String {
            let quote = source[index]
            advance()
            var result = ""
            var isEscaping = false

            while index < source.endIndex {
                let character = source[index]
                advance()

                if quote == "\"" && isEscaping {
                    switch character {
                    case "\"":
                        result.append("\"")
                    case "\\":
                        result.append("\\")
                    case "n":
                        result.append("\n")
                    case "r":
                        result.append("\r")
                    case "t":
                        result.append("\t")
                    default:
                        result.append(character)
                    }
                    isEscaping = false
                    continue
                }

                if quote == "\"" && character == "\\" {
                    isEscaping = true
                    continue
                }

                if quote == "'" && character == "'" && index < source.endIndex && source[index] == "'" {
                    result.append("'")
                    advance()
                    continue
                }

                if character == quote {
                    return result
                }

                result.append(character)
            }

            throw SymphonyWorkflowInfrastructureError.workflowParseError(
                details: "Unterminated quoted inline string."
            )
        }

        private mutating func consume(_ token: Character) throws {
            skipWhitespace()
            guard consumeIfCurrentCharacter(is: token) else {
                throw SymphonyWorkflowInfrastructureError.workflowParseError(
                    details: "Expected `\(token)` in inline YAML."
                )
            }
        }

        private mutating func consume(_ token: String) throws {
            guard token.count == 1, let character = token.first else {
                return
            }
            try consume(character)
        }

        private mutating func skipWhitespace() {
            index = skipWhitespaceIndex(from: index)
        }

        private func skipWhitespaceIndex(from start: String.Index) -> String.Index {
            var current = start
            while current < source.endIndex,
                  source[current].isWhitespace {
                current = source.index(after: current)
            }
            return current
        }

        private mutating func advance() {
            index = source.index(after: index)
        }

        private mutating func consumeIfCurrentCharacter(is character: Character) -> Bool {
            skipWhitespace()
            guard index < source.endIndex,
                  source[index] == character else {
                return false
            }
            advance()
            return true
        }
    }
}
