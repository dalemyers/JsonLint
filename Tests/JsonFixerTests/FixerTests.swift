import Testing
@testable import JsonFixer
@testable import JsonRules
@testable import JsonLexer
@testable import JsonParser

@Suite("Fixer Tests")
struct FixerTests {
    // Test rule that can fix violations
    struct TestFixableRule: Rule {
        var identifier: String { "test.fixable" }
        var category: RuleCategory { .style }
        var description: String { "Test fixable rule" }
        var defaultSeverity: Severity { .warning }

        func validate(_ node: any ASTNode, context: ValidationContext) -> [Violation] {
            return []
        }

        func fix(_ violation: Violation, context: FixContext) -> Fix? {
            // Replace the violating text with "FIXED"
            return Fix(
                range: violation.location,
                replacement: "FIXED"
            )
        }
    }

    // Test rule that cannot fix violations
    struct TestUnfixableRule: Rule {
        var identifier: String { "test.unfixable" }
        var category: RuleCategory { .style }
        var description: String { "Test unfixable rule" }
        var defaultSeverity: Severity { .warning }

        func validate(_ node: any ASTNode, context: ValidationContext) -> [Violation] {
            return []
        }

        func fix(_ violation: Violation, context: FixContext) -> Fix? {
            return nil
        }
    }

    @Test("Fixer applies fixes from matching rules")
    func fixerAppliesFixesFromMatchingRules() throws {
        let source = #"{"key": "value"}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration()
        let rule = TestFixableRule()
        let fixer = Fixer(rules: [rule], config: config)

        let loc = SourceLocation(line: 1, column: 2, offset: 1, length: 3)
        let range = SourceRange(location: loc)
        let violation = Violation(
            rule: "test.fixable",
            severity: .warning,
            message: "Test violation",
            location: range
        )

        let result = fixer.fix(ast, sourceText: source, violations: [violation])

        #expect(result.appliedFixes == 1)
        #expect(result.remainingViolations.isEmpty)
        #expect(result.isFullyFixed)
        #expect(result.fixedSource.contains("FIXED"))
    }

    @Test("Fixer handles unfixable violations")
    func fixerHandlesUnfixableViolations() throws {
        let source = #"{"key": "value"}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration()
        let rule = TestUnfixableRule()
        let fixer = Fixer(rules: [rule], config: config)

        let loc = SourceLocation(line: 1, column: 2, offset: 1, length: 3)
        let range = SourceRange(location: loc)
        let violation = Violation(
            rule: "test.unfixable",
            severity: .warning,
            message: "Test violation",
            location: range
        )

        let result = fixer.fix(ast, sourceText: source, violations: [violation])

        #expect(result.appliedFixes == 0)
        #expect(result.remainingViolations.count == 1)
        #expect(!result.isFullyFixed)
        #expect(result.fixedSource == source)
    }

    @Test("Fixer handles violations with no matching rule")
    func fixerHandlesViolationsWithNoMatchingRule() throws {
        let source = #"{"key": "value"}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration()
        let fixer = Fixer(rules: [], config: config)

        let loc = SourceLocation(line: 1, column: 2, offset: 1, length: 3)
        let range = SourceRange(location: loc)
        let violation = Violation(
            rule: "test.missing",
            severity: .warning,
            message: "Test violation",
            location: range
        )

        let result = fixer.fix(ast, sourceText: source, violations: [violation])

        #expect(result.appliedFixes == 0)
        #expect(result.remainingViolations.count == 1)
        #expect(!result.isFullyFixed)
    }

    @Test("Fixer applies multiple fixes in reverse order")
    func fixerAppliesMultipleFixesInReverseOrder() throws {
        let source = "abcdefgh"
        let lexer = Lexer(source: #"{"key": "value"}"#, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration()
        let rule = TestFixableRule()
        let fixer = Fixer(rules: [rule], config: config)

        // Create violations at different offsets
        let loc1 = SourceLocation(line: 1, column: 1, offset: 0, length: 2)
        let range1 = SourceRange(location: loc1)
        let violation1 = Violation(
            rule: "test.fixable",
            severity: .warning,
            message: "First violation",
            location: range1
        )

        let loc2 = SourceLocation(line: 1, column: 5, offset: 4, length: 2)
        let range2 = SourceRange(location: loc2)
        let violation2 = Violation(
            rule: "test.fixable",
            severity: .warning,
            message: "Second violation",
            location: range2
        )

        let result = fixer.fix(ast, sourceText: source, violations: [violation1, violation2])

        #expect(result.appliedFixes == 2)
        #expect(result.remainingViolations.isEmpty)
        #expect(result.isFullyFixed)
    }

    @Test("Fixer handles mixed fixable and unfixable violations")
    func fixerHandlesMixedViolations() throws {
        let source = #"{"key": "value"}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration()
        let fixableRule = TestFixableRule()
        let unfixableRule = TestUnfixableRule()
        let fixer = Fixer(rules: [fixableRule, unfixableRule], config: config)

        let loc1 = SourceLocation(line: 1, column: 2, offset: 1, length: 3)
        let range1 = SourceRange(location: loc1)
        let violation1 = Violation(
            rule: "test.fixable",
            severity: .warning,
            message: "Fixable violation",
            location: range1
        )

        let loc2 = SourceLocation(line: 1, column: 9, offset: 8, length: 5)
        let range2 = SourceRange(location: loc2)
        let violation2 = Violation(
            rule: "test.unfixable",
            severity: .warning,
            message: "Unfixable violation",
            location: range2
        )

        let result = fixer.fix(ast, sourceText: source, violations: [violation1, violation2])

        #expect(result.appliedFixes == 1)
        #expect(result.remainingViolations.count == 1)
        #expect(!result.isFullyFixed)
    }

    @Test("FixResult properties")
    func fixResultProperties() {
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 1)
        let range = SourceRange(location: loc)
        let violation = Violation(
            rule: "test.rule",
            severity: .warning,
            message: "Test",
            location: range
        )

        let result = FixResult(
            fixedSource: "fixed",
            appliedFixes: 5,
            remainingViolations: [violation]
        )

        #expect(result.fixedSource == "fixed")
        #expect(result.appliedFixes == 5)
        #expect(result.remainingViolations.count == 1)
        #expect(!result.isFullyFixed)
    }

    @Test("FixResult isFullyFixed when no remaining violations")
    func fixResultFullyFixed() {
        let result = FixResult(
            fixedSource: "fixed",
            appliedFixes: 5,
            remainingViolations: []
        )

        #expect(result.isFullyFixed)
    }
}
