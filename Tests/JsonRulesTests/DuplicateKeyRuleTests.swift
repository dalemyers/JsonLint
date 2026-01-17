import Testing
@testable import JsonRules
@testable import JsonLexer
@testable import JsonParser

@Suite("Duplicate Key Rule Tests")
struct DuplicateKeyRuleTests {
    @Test("Parser detects duplicate keys")
    func parserDetectsDuplicateKeys() throws {
        let source = #"{"key": 1, "key": 2}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)

        // Parser should throw an error for duplicate keys
        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("No violation for unique keys")
    func noViolationForUniqueKeys() throws {
        let source = #"{"key1": 1, "key2": 2}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = DuplicateKeyRule()
        let config = RuleConfiguration()
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        if case .object(let obj) = ast {
            let violations = rule.validate(obj, context: context)
            #expect(violations.isEmpty)
        } else {
            Issue.record("Expected object")
        }
    }

    @Test("Rule has correct metadata")
    func ruleHasCorrectMetadata() {
        let rule = DuplicateKeyRule()

        #expect(rule.identifier == "structural.duplicate-keys")
        #expect(rule.category == .structural)
        #expect(rule.defaultSeverity == .error)
        #expect(!rule.description.isEmpty)
    }

    @Test("Rule validates nested objects")
    func ruleValidatesNestedObjects() throws {
        let source = #"{"outer": {"inner1": 1, "inner2": 2}}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = DuplicateKeyRule()
        let config = RuleConfiguration()
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        if case .object(let obj) = ast {
            let violations = rule.validate(obj, context: context)
            #expect(violations.isEmpty)
        } else {
            Issue.record("Expected object")
        }
    }
}
