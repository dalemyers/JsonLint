import JsonParser
import JsonLexer

public struct CommentsRule: Rule {
    public let identifier = "dialect.no-comments"
    public let category = RuleCategory.dialect
    public let description = "Disallows comments in JSON (allowed in JSON5/JSONC)"
    public let defaultSeverity = Severity.error

    public init() {}

    public func validate(_ node: any ASTNode, context: ValidationContext) -> [Violation] {
        if context.config.dialect.allowsComments {
            return []
        }

        var violations: [Violation] = []

        let allTrivia = node.leadingTrivia + node.trailingTrivia

        for token in allTrivia {
            switch token.type {
            case .singleLineComment, .multiLineComment:
                violations.append(Violation(
                    rule: identifier,
                    severity: defaultSeverity,
                    message: "Comments are not allowed in \(context.config.dialect.rawValue.uppercased())",
                    location: SourceRange(location: token.location),
                    suggestion: "Remove the comment or use JSON5/JSONC dialect"
                ))
            default:
                break
            }
        }

        return violations
    }

    public func fix(_ violation: Violation, context: FixContext) -> Fix? {
        nil
    }
}
