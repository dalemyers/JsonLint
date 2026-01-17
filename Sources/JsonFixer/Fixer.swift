import JsonParser
import JsonRules
import JsonLexer
import Foundation

public final class Fixer: Sendable {
    private let rules: [any Rule]
    private let config: RuleConfiguration

    public init(rules: [any Rule], config: RuleConfiguration) {
        self.rules = rules
        self.config = config
    }

    public func fix(_ ast: JSONValue, sourceText: String, violations: [Violation]) -> FixResult {
        let context = FixContext(
            ast: ast,
            config: config,
            sourceText: sourceText
        )

        var fixes: [Fix] = []
        var unfixableViolations: [Violation] = []

        for violation in violations {
            guard let rule = rules.first(where: { $0.identifier == violation.rule }) else {
                unfixableViolations.append(violation)
                continue
            }

            if let fix = rule.fix(violation, context: context) {
                fixes.append(fix)
            } else {
                unfixableViolations.append(violation)
            }
        }

        let sortedFixes = fixes.sorted { $0.range.start.offset > $1.range.start.offset }
        let fixedSource = applyFixes(sortedFixes, to: sourceText)

        return FixResult(
            fixedSource: fixedSource,
            appliedFixes: fixes.count,
            remainingViolations: unfixableViolations
        )
    }

    private func applyFixes(_ fixes: [Fix], to source: String) -> String {
        var result = source
        let sourceArray = Array(source)

        for fix in fixes {
            let startOffset = fix.range.start.offset
            let endOffset = fix.range.end.offset

            let prefix = String(sourceArray[..<startOffset])
            let suffix = String(sourceArray[endOffset...])

            result = prefix + fix.replacement + suffix
        }

        return result
    }
}

public struct FixResult: Sendable {
    public let fixedSource: String
    public let appliedFixes: Int
    public let remainingViolations: [Violation]

    public init(fixedSource: String, appliedFixes: Int, remainingViolations: [Violation]) {
        self.fixedSource = fixedSource
        self.appliedFixes = appliedFixes
        self.remainingViolations = remainingViolations
    }

    public var isFullyFixed: Bool {
        remainingViolations.isEmpty
    }
}
