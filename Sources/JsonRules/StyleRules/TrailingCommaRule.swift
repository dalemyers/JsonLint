import JsonParser
import JsonLexer

public struct TrailingCommaRule: Rule {
    public let identifier = "style.trailing-comma"
    public let category = RuleCategory.style
    public let description = "Enforces trailing comma rules based on dialect"
    public let defaultSeverity = Severity.warning

    public init() {}

    public func validate(_ node: any ASTNode, context: ValidationContext) -> [Violation] {
        var violations: [Violation] = []

        if let obj = node as? JSONObject {
            if obj.hasTrailingComma && !context.config.dialect.allowsTrailingCommas {
                violations.append(Violation(
                    rule: identifier,
                    severity: defaultSeverity,
                    message: "Trailing comma not allowed in \(context.config.dialect.rawValue.uppercased())",
                    location: obj.location,
                    suggestion: "Remove the trailing comma"
                ))
            }
        } else if let arr = node as? JSONArray {
            if arr.hasTrailingComma && !context.config.dialect.allowsTrailingCommas {
                violations.append(Violation(
                    rule: identifier,
                    severity: defaultSeverity,
                    message: "Trailing comma not allowed in \(context.config.dialect.rawValue.uppercased())",
                    location: arr.location,
                    suggestion: "Remove the trailing comma"
                ))
            }
        }

        return violations
    }

    public func fix(_ violation: Violation, context: FixContext) -> Fix? {
        nil
    }
}
