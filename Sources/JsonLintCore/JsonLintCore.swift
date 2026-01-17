import Foundation
import JsonLexer
import JsonParser
import JsonRules
import JsonValidator
import JsonFixer
import JsonConfig

public struct JsonLintCore {
    public init() {}

    public static func lint(
        source: String,
        dialect: Dialect = .json,
        config: Configuration = .default
    ) throws -> LintResult {
        let lexer = Lexer(source: source, dialect: dialect)
        let tokens = try lexer.tokenize()

        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let ruleConfig = config.toRuleConfiguration()
        let validator = Validator(config: ruleConfig)
        let validationResult = validator.validate(ast, sourceText: source)

        return LintResult(
            isValid: validationResult.isValid,
            violations: validationResult.violations,
            errorCount: validationResult.errorCount,
            warningCount: validationResult.warningCount
        )
    }

    public static func format(
        source: String,
        dialect: Dialect = .json,
        config: Configuration = .default
    ) throws -> String {
        let lexer = Lexer(source: source, dialect: dialect)
        let tokens = try lexer.tokenize()

        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let ruleConfig = config.toRuleConfiguration()
        let formatter = Formatter(config: ruleConfig)

        return formatter.format(ast)
    }

    public static func fix(
        source: String,
        dialect: Dialect = .json,
        config: Configuration = .default
    ) throws -> FixResult {
        let lexer = Lexer(source: source, dialect: dialect)
        let tokens = try lexer.tokenize()

        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let ruleConfig = config.toRuleConfiguration()

        let validator = Validator(config: ruleConfig)
        let validationResult = validator.validate(ast, sourceText: source)

        let formatter = Formatter(config: ruleConfig)
        let fixedSource = formatter.format(ast)

        return FixResult(
            fixedSource: fixedSource,
            violations: validationResult.violations,
            appliedFixes: validationResult.violations.count,
            isFullyFixed: true
        )
    }

    public static func parse(
        source: String,
        dialect: Dialect = .json
    ) throws -> JSONValue {
        let lexer = Lexer(source: source, dialect: dialect)
        let tokens = try lexer.tokenize()

        let parser = Parser(tokens: tokens)
        return try parser.parse()
    }
}

public struct LintResult {
    public let isValid: Bool
    public let violations: [Violation]
    public let errorCount: Int
    public let warningCount: Int

    public init(
        isValid: Bool,
        violations: [Violation],
        errorCount: Int,
        warningCount: Int
    ) {
        self.isValid = isValid
        self.violations = violations
        self.errorCount = errorCount
        self.warningCount = warningCount
    }
}

public struct FixResult {
    public let fixedSource: String
    public let violations: [Violation]
    public let appliedFixes: Int
    public let isFullyFixed: Bool

    public init(
        fixedSource: String,
        violations: [Violation],
        appliedFixes: Int,
        isFullyFixed: Bool
    ) {
        self.fixedSource = fixedSource
        self.violations = violations
        self.appliedFixes = appliedFixes
        self.isFullyFixed = isFullyFixed
    }
}

@_exported import JsonLexer
@_exported import JsonParser
@_exported import JsonRules
@_exported import JsonValidator
@_exported import JsonFixer
@_exported import JsonConfig
