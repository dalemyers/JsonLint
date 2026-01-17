import JsonParser
import JsonRules
import JsonLexer

public final class Validator: Sendable {
    private let rules: [any Rule]
    private let config: RuleConfiguration

    public init(rules: [any Rule], config: RuleConfiguration) {
        self.rules = rules
        self.config = config
    }

    public convenience init(config: RuleConfiguration) {
        let package = RulePackage.for(dialect: config.dialect)
        let ruleIdentifiers = package.allRules()
        let rules = RuleRegistry.standard.rules(for: ruleIdentifiers)
        self.init(rules: rules, config: config)
    }

    public func validate(_ ast: JSONValue, sourceText: String) -> ValidationResult {
        let context = ValidationContext(
            ast: ast,
            config: config,
            sourceText: sourceText
        )

        var allViolations: [Violation] = []

        ast.walk { node in
            for rule in rules where config.isEnabled(rule.identifier) {
                let violations = rule.validate(node, context: context)
                allViolations.append(contentsOf: violations)
            }
        }

        allViolations.sort { $0.location.start < $1.location.start }

        return ValidationResult(
            violations: allViolations,
            isValid: allViolations.allSatisfy { $0.severity != .error }
        )
    }
}
