import JsonParser
import JsonLexer

public struct DuplicateKeyRule: Rule {
    public let identifier = "structural.duplicate-keys"
    public let category = RuleCategory.structural
    public let description = "Disallows duplicate keys in objects"
    public let defaultSeverity = Severity.error

    public init() {}

    public func validate(_ node: any ASTNode, context: ValidationContext) -> [Violation] {
        guard let obj = node as? JSONObject else { return [] }

        var seen: [String: SourceRange] = [:]
        var violations: [Violation] = []

        for member in obj.members {
            if let firstLocation = seen[member.key.value] {
                violations.append(Violation(
                    rule: identifier,
                    severity: defaultSeverity,
                    message: "Duplicate key '\(member.key.value)' (first occurrence at \(firstLocation.start.line):\(firstLocation.start.column))",
                    location: member.key.location,
                    suggestion: "Remove or rename this key"
                ))
            } else {
                seen[member.key.value] = member.key.location
            }
        }

        return violations
    }

    public func fix(_ violation: Violation, context: FixContext) -> Fix? {
        nil
    }
}
