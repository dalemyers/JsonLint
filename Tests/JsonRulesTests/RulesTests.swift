import Testing
import Foundation
@testable import JsonRules
@testable import JsonLexer
@testable import JsonParser

@Suite("Rules Tests")
struct RulesTests {
    @Test("RulePackage for JSON dialect")
    func rulePackageForJSON() {
        let package = RulePackage.for(dialect: .json)
        #expect(package.name == "JSON")
        #expect(!package.rules.isEmpty)
    }

    @Test("RulePackage for JSON5 dialect")
    func rulePackageForJSON5() {
        let package = RulePackage.for(dialect: .json5)
        #expect(package.name == "JSON5")
        #expect(!package.rules.isEmpty)
    }

    @Test("RulePackage for JSONC dialect")
    func rulePackageForJSONC() {
        let package = RulePackage.for(dialect: .jsonc)
        #expect(package.name == "JSONC")
        #expect(!package.rules.isEmpty)
    }

    @Test("RulePackage allRules method")
    func rulePackageAllRules() {
        let package = RulePackage.for(dialect: .json)
        let allRules = package.allRules()
        #expect(!allRules.isEmpty)
        #expect(allRules.count == package.rules.count)
    }

    @Test("RuleRegistry allRules")
    func ruleRegistryAllRules() {
        let registry = RuleRegistry.standard
        let rules = registry.allRules()
        #expect(!rules.isEmpty)
    }

    @Test("RuleRegistry rule by identifier")
    func ruleRegistryRuleByIdentifier() {
        let registry = RuleRegistry.standard
        let rule = registry.rule(for: "structural.duplicate-keys")
        #expect(rule != nil)
    }

    @Test("RuleRegistry rules for package")
    func ruleRegistryRulesForPackage() {
        let registry = RuleRegistry.standard
        let package = RulePackage.for(dialect: .json)
        let rules = registry.rules(for: package.allRules())
        #expect(!rules.isEmpty)
    }

    @Test("RuleRegistry returns nil for unknown identifier")
    func ruleRegistryUnknownIdentifier() {
        let registry = RuleRegistry.standard
        let rule = registry.rule(for: "unknown.rule")
        #expect(rule == nil)
    }

    @Test("StandardRules by category")
    func standardRulesByCategory() {
        let byCategory = StandardRules.byCategory
        #expect(!byCategory.isEmpty)
        #expect(byCategory[.structural] != nil)
        #expect(byCategory[.style] != nil)
    }

    @Test("QuoteStyleRule validates double quotes")
    func quoteStyleRuleDoubleQuotes() throws {
        let source = #"{"key": "value"}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = QuoteStyleRule()
        let config = RuleConfiguration(quoteStyle: .double)
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        let violations = rule.validate(ast, context: context)
        #expect(violations.isEmpty)
    }

    @Test("QuoteStyleRule detects single quotes when double expected")
    func quoteStyleRuleSingleQuotesViolation() throws {
        let source = "{'key': 'value'}"
        let lexer = Lexer(source: source, dialect: .json5)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = QuoteStyleRule()
        let config = RuleConfiguration(dialect: .json5, quoteStyle: .double)
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        // Walk the tree and collect violations
        var violations: [Violation] = []
        ast.walk { node in
            violations.append(contentsOf: rule.validate(node, context: context))
        }
        #expect(!violations.isEmpty)
    }

    @Test("QuoteStyleRule fix converts quotes")
    func quoteStyleRuleFix() throws {
        let source = "{'key': 'value'}"
        let lexer = Lexer(source: source, dialect: .json5)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = QuoteStyleRule()
        let config = RuleConfiguration(dialect: .json5, quoteStyle: .double)
        let context = ValidationContext(ast: ast, config: config, sourceText: source)
        let fixContext = FixContext(ast: ast, config: config, sourceText: source)

        let violations = rule.validate(ast, context: context)
        if let violation = violations.first {
            let fix = rule.fix(violation, context: fixContext)
            #expect(fix != nil)
        }
    }

    @Test("TrailingCommaRule detects trailing commas in objects")
    func trailingCommaRuleObject() throws {
        let source = #"{"key": "value",}"#
        let lexer = Lexer(source: source, dialect: .json5)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = TrailingCommaRule()
        let config = RuleConfiguration(dialect: .json)  // JSON doesn't allow trailing commas
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        // Extract the JSONObject from the enum and validate it
        if case .object(let obj) = ast {
            #expect(obj.hasTrailingComma)
            let violations = rule.validate(obj, context: context)
            #expect(!violations.isEmpty)
        } else {
            Issue.record("Expected object")
        }
    }

    @Test("TrailingCommaRule detects trailing commas in arrays")
    func trailingCommaRuleArray() throws {
        let source = "[1, 2, 3,]"
        let lexer = Lexer(source: source, dialect: .json5)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = TrailingCommaRule()
        let config = RuleConfiguration(dialect: .json)  // JSON doesn't allow trailing commas
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        // Extract the JSONArray from the enum and validate it
        if case .array(let arr) = ast {
            #expect(arr.hasTrailingComma)
            let violations = rule.validate(arr, context: context)
            #expect(!violations.isEmpty)
        } else {
            Issue.record("Expected array")
        }
    }

    @Test("TrailingCommaRule no violation for no trailing comma")
    func trailingCommaRuleNoViolation() throws {
        let source = #"{"key": "value"}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = TrailingCommaRule()
        let config = RuleConfiguration(dialect: .json)
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        let violations = rule.validate(ast, context: context)
        #expect(violations.isEmpty)
    }

    @Test("TrailingCommaRule does not provide auto-fix")
    func trailingCommaRuleNoFix() throws {
        let source = #"{"key": "value",}"#
        let lexer = Lexer(source: source, dialect: .json5)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = TrailingCommaRule()
        let config = RuleConfiguration(dialect: .json)
        let context = ValidationContext(ast: ast, config: config, sourceText: source)
        let fixContext = FixContext(ast: ast, config: config, sourceText: source)

        // Extract the JSONObject and validate it
        if case .object(let obj) = ast {
            let violations = rule.validate(obj, context: context)
            if let violation = violations.first {
                let fix = rule.fix(violation, context: fixContext)
                #expect(fix == nil)
            }
        }
    }

    @Test("CommentsRule detects comments in JSON")
    func commentsRuleDetectsComments() throws {
        let source = #"{"key": "value"} // comment"#
        let lexer = Lexer(source: source, dialect: .json5)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = CommentsRule()
        let config = RuleConfiguration(dialect: .json)
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        // Walk the tree to check all nodes
        var violations: [Violation] = []
        ast.walk { node in
            violations.append(contentsOf: rule.validate(node, context: context))
        }
        #expect(!violations.isEmpty)
    }

    @Test("CommentsRule no violation for allowed comments")
    func commentsRuleAllowedComments() throws {
        let source = #"{"key": "value"} // comment"#
        let lexer = Lexer(source: source, dialect: .json5)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = CommentsRule()
        let config = RuleConfiguration(dialect: .json5)
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        let violations = rule.validate(ast, context: context)
        #expect(violations.isEmpty)
    }

    @Test("CommentsRule does not provide auto-fix")
    func commentsRuleNoFix() throws {
        let source = #"{"key": "value"} // comment"#
        let lexer = Lexer(source: source, dialect: .json5)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = CommentsRule()
        let config = RuleConfiguration(dialect: .json)
        let context = ValidationContext(ast: ast, config: config, sourceText: source)
        let fixContext = FixContext(ast: ast, config: config, sourceText: source)

        // Walk the tree to find violations
        var violations: [Violation] = []
        ast.walk { node in
            violations.append(contentsOf: rule.validate(node, context: context))
        }

        // CommentsRule doesn't implement auto-fix
        if let violation = violations.first {
            let fix = rule.fix(violation, context: fixContext)
            #expect(fix == nil)
        }
    }

    @Test("MaxDepthRule detects excessive nesting")
    func maxDepthRuleDetectsExcessiveNesting() throws {
        let source = #"{"a":{"b":{"c":{"d":{"e":"value"}}}}}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = MaxDepthRule()
        let options = RuleOptions(values: ["max": .int(3)])
        let config = RuleConfiguration(ruleOptions: ["structural.max-depth": options])
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        let violations = rule.validate(ast, context: context)
        #expect(!violations.isEmpty)
    }

    @Test("MaxDepthRule no violation for shallow nesting")
    func maxDepthRuleShallowNesting() throws {
        let source = #"{"a":{"b":"value"}}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = MaxDepthRule()
        let options = RuleOptions(values: ["max": .int(10)])
        let config = RuleConfiguration(ruleOptions: ["structural.max-depth": options])
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        let violations = rule.validate(ast, context: context)
        #expect(violations.isEmpty)
    }

    @Test("MaxDepthRule validates arrays")
    func maxDepthRuleArrays() throws {
        let source = "[[[[1]]]]"
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = MaxDepthRule()
        let options = RuleOptions(values: ["max": .int(3)])
        let config = RuleConfiguration(ruleOptions: ["structural.max-depth": options])
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        let violations = rule.validate(ast, context: context)
        #expect(!violations.isEmpty)
    }

    @Test("MaxDepthRule uses default max depth")
    func maxDepthRuleDefaultMaxDepth() throws {
        let source = #"{"a":"value"}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = MaxDepthRule()
        let config = RuleConfiguration()
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        let violations = rule.validate(ast, context: context)
        #expect(violations.isEmpty)
    }

    @Test("MaxDepthRule does not provide auto-fix")
    func maxDepthRuleNoFix() throws {
        let source = #"{"a":{"b":{"c":{"d":"value"}}}}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = MaxDepthRule()
        let options = RuleOptions(values: ["max": .int(2)])
        let config = RuleConfiguration(ruleOptions: ["structural.max-depth": options])
        let context = ValidationContext(ast: ast, config: config, sourceText: source)
        let fixContext = FixContext(ast: ast, config: config, sourceText: source)

        let violations = rule.validate(ast, context: context)
        if let violation = violations.first {
            let fix = rule.fix(violation, context: fixContext)
            #expect(fix == nil)
        }
    }

    @Test("QuoteStyleRule does not provide auto-fix")
    func quoteStyleRuleNoFix() throws {
        let source = "{'key': 'value'}"
        let lexer = Lexer(source: source, dialect: .json5)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = QuoteStyleRule()
        let config = RuleConfiguration(dialect: .json5, quoteStyle: .double)
        let context = ValidationContext(ast: ast, config: config, sourceText: source)
        let fixContext = FixContext(ast: ast, config: config, sourceText: source)

        var violations: [Violation] = []
        ast.walk { node in
            violations.append(contentsOf: rule.validate(node, context: context))
        }

        if let violation = violations.first {
            let fix = rule.fix(violation, context: fixContext)
            #expect(fix == nil)
        }
    }

    @Test("DuplicateKeyRule does not provide auto-fix")
    func duplicateKeyRuleNoFix() {
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 3)
        let range = SourceRange(location: loc)
        let violation = Violation(
            rule: "structural.duplicate-keys",
            severity: .error,
            message: "Test",
            location: range
        )

        let rule = DuplicateKeyRule()
        let config = RuleConfiguration()
        let lexer = Lexer(source: #"{"key": "value"}"#, dialect: .json)
        let tokens = try! lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try! parser.parse()
        let fixContext = FixContext(ast: ast, config: config, sourceText: #"{"key": "value"}"#)

        let fix = rule.fix(violation, context: fixContext)
        #expect(fix == nil)
    }

    @Test("Severity comparison")
    func severityComparison() {
        #expect(Severity.info < Severity.warning)
        #expect(Severity.warning < Severity.error)
        #expect(!(Severity.error < Severity.info))
    }

    @Test("RuleConfiguration severity override")
    func ruleConfigurationSeverityOverride() {
        let config = RuleConfiguration(severityOverrides: ["test.rule": .error])
        #expect(config.severity(for: "test.rule", default: .warning) == .error)
        #expect(config.severity(for: "other.rule", default: .info) == .info)
    }

    @Test("ConfigValue decoding from string")
    func configValueDecodingString() throws {
        let json = "\"test\""
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(ConfigValue.self, from: data)

        if case .string(let str) = value {
            #expect(str == "test")
        } else {
            Issue.record("Expected string ConfigValue")
        }
    }

    @Test("ConfigValue decoding from int")
    func configValueDecodingInt() throws {
        let json = "42"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(ConfigValue.self, from: data)

        if case .int(let num) = value {
            #expect(num == 42)
        } else {
            Issue.record("Expected int ConfigValue")
        }
    }

    @Test("ConfigValue decoding from bool")
    func configValueDecodingBool() throws {
        let json = "true"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(ConfigValue.self, from: data)

        if case .bool(let b) = value {
            #expect(b == true)
        } else {
            Issue.record("Expected bool ConfigValue")
        }
    }

    @Test("ConfigValue decoding from array")
    func configValueDecodingArray() throws {
        let json = "[1, 2, 3]"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(ConfigValue.self, from: data)

        if case .array(let arr) = value {
            #expect(arr.count == 3)
        } else {
            Issue.record("Expected array ConfigValue")
        }
    }

    @Test("ConfigValue decoding error for invalid type")
    func configValueDecodingError() throws {
        let json = "{\"invalid\": \"object\"}"
        let data = json.data(using: .utf8)!

        #expect(throws: Error.self) {
            try JSONDecoder().decode(ConfigValue.self, from: data)
        }
    }

    @Test("ConfigValue encoding string")
    func configValueEncodingString() throws {
        let value = ConfigValue.string("test")
        let data = try JSONEncoder().encode(value)
        let json = String(data: data, encoding: .utf8)
        #expect(json?.contains("test") == true)
    }

    @Test("ConfigValue encoding int")
    func configValueEncodingInt() throws {
        let value = ConfigValue.int(42)
        let data = try JSONEncoder().encode(value)
        let json = String(data: data, encoding: .utf8)
        #expect(json == "42")
    }

    @Test("ConfigValue encoding bool")
    func configValueEncodingBool() throws {
        let value = ConfigValue.bool(true)
        let data = try JSONEncoder().encode(value)
        let json = String(data: data, encoding: .utf8)
        #expect(json == "true")
    }

    @Test("ConfigValue encoding array")
    func configValueEncodingArray() throws {
        let value = ConfigValue.array([.int(1), .int(2), .int(3)])
        let data = try JSONEncoder().encode(value)
        let json = String(data: data, encoding: .utf8)
        #expect(json?.contains("1") == true)
    }

    @Test("RuleConfiguration with enabled rules")
    func ruleConfigurationEnabledRules() {
        let config = RuleConfiguration(enabledRules: ["test.rule"])
        #expect(config.isEnabled("test.rule"))
        #expect(!config.isEnabled("other.rule"))
    }
}
