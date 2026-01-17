import JsonParser
import JsonLexer

public struct MaxDepthRule: Rule {
    public let identifier = "structural.max-depth"
    public let category = RuleCategory.structural
    public let description = "Limits maximum nesting depth"
    public let defaultSeverity = Severity.warning

    private let defaultMaxDepth = 10

    public init() {}

    public func validate(_ node: any ASTNode, context: ValidationContext) -> [Violation] {
        let maxDepth: Int
        if let option = context.config.ruleOptions[identifier]?["max"],
           case .int(let value) = option {
            maxDepth = value
        } else {
            maxDepth = defaultMaxDepth
        }

        let depth = calculateDepth(node)

        if depth > maxDepth {
            return [Violation(
                rule: identifier,
                severity: defaultSeverity,
                message: "Nesting depth (\(depth)) exceeds maximum (\(maxDepth))",
                location: node.location,
                suggestion: "Reduce nesting depth"
            )]
        }

        return []
    }

    private func calculateDepth(_ node: any ASTNode) -> Int {
        if let value = node as? JSONValue {
            return calculateValueDepth(value)
        }
        return 0
    }

    private func calculateValueDepth(_ value: JSONValue) -> Int {
        switch value {
        case .object(let obj):
            let maxMemberDepth = obj.members.map { calculateValueDepth($0.value) }.max() ?? 0
            return 1 + maxMemberDepth
        case .array(let arr):
            let maxElementDepth = arr.elements.map { calculateValueDepth($0.value) }.max() ?? 0
            return 1 + maxElementDepth
        case .string, .number, .boolean, .null:
            return 1
        }
    }

    public func fix(_ violation: Violation, context: FixContext) -> Fix? {
        nil
    }
}
