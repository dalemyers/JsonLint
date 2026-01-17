import Testing
@testable import JsonValidator
@testable import JsonRules
@testable import JsonLexer
@testable import JsonParser

@Suite("Validator Integration Tests")
struct ValidatorIntegrationTests {
    @Test("Parser catches duplicate keys")
    func parserCatchesDuplicateKeys() throws {
        let source = #"{"key": 1, "key": 2}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)

        // Parser throws error for duplicates
        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("Validates clean JSON")
    func validatesCleanJSON() throws {
        let source = #"{"name": "test", "value": 123}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration()
        let validator = Validator(config: config)
        let result = validator.validate(ast, sourceText: source)

        #expect(result.isValid)
        #expect(result.errorCount == 0)
        #expect(result.violations.isEmpty)
    }

    @Test("Validates nested structures")
    func validatesNestedStructures() throws {
        let source = #"{"outer": {"inner": [1, 2, 3]}}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration()
        let validator = Validator(config: config)
        let result = validator.validate(ast, sourceText: source)

        #expect(result.isValid)
    }

    @Test("Validates JSON5 with comments")
    func validatesJSON5WithComments() throws {
        let source = """
        {
          // This is a comment
          "key": "value"
        }
        """
        let lexer = Lexer(source: source, dialect: .json5)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration(dialect: .json5)
        let validator = Validator(config: config)
        let result = validator.validate(ast, sourceText: source)

        #expect(result.isValid)
    }

    @Test("Lexer rejects comments in JSON dialect")
    func lexerRejectsCommentsInJSON() throws {
        let source = """
        {
          // This comment is not allowed
          "key": "value"
        }
        """
        let lexer = Lexer(source: source, dialect: .json)

        // Lexer throws error for comments in JSON dialect
        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }
}
