import JsonParser
import JsonLexer

public struct BlankLinesRule: Rule {
    public let identifier = "style.no-blank-lines"
    public let category = RuleCategory.style
    public let description = "Disallows blank lines in JSON"
    public let defaultSeverity = Severity.warning

    public init() {}

    public func validate(_ node: any ASTNode, context: ValidationContext) -> [Violation] {
        // Only validate at the root level to avoid duplicate violations
        // The root node starts at offset 0
        guard let jsonValue = node as? JSONValue,
              jsonValue.location.start.offset == 0 else {
            return []
        }

        var violations: [Violation] = []
        let lines = context.sourceText.split(separator: "\n", omittingEmptySubsequences: false)

        var offset = 0
        for (lineIndex, line) in lines.enumerated() {
            let lineNumber = lineIndex + 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty && lineNumber < lines.count {
                let location = SourceLocation(
                    line: lineNumber,
                    column: 1,
                    offset: offset,
                    length: line.count
                )
                let range = SourceRange(location: location)

                violations.append(Violation(
                    rule: identifier,
                    severity: defaultSeverity,
                    message: "Blank lines are not allowed",
                    location: range,
                    suggestion: "Remove blank line"
                ))
            }

            offset += line.count + 1 // +1 for newline character
        }

        return violations
    }

    public func fix(_ violation: Violation, context: FixContext) -> Fix? {
        // Return a fix that removes the blank line (replace with empty string)
        return Fix(range: violation.location, replacement: "")
    }
}
