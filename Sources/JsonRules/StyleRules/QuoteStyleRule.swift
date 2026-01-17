import JsonParser
import JsonLexer

public struct QuoteStyleRule: Rule {
    public let identifier = "style.quote-style"
    public let category = RuleCategory.style
    public let description = "Enforces consistent quote style"
    public let defaultSeverity = Severity.warning

    public init() {}

    public func validate(_ node: any ASTNode, context: ValidationContext) -> [Violation] {
        guard let stringNode = node as? JSONString else { return [] }

        let preferredQuote = context.config.quoteStyle

        if case .string(let quote) = stringNode.token.type {
            if quote != preferredQuote {
                let quoteName = preferredQuote == .double ? "double" : "single"
                return [Violation(
                    rule: identifier,
                    severity: defaultSeverity,
                    message: "Expected \(quoteName) quotes",
                    location: stringNode.location,
                    suggestion: "Use \(quoteName) quotes instead"
                )]
            }
        }

        return []
    }

    public func fix(_ violation: Violation, context: FixContext) -> Fix? {
        nil
    }
}
