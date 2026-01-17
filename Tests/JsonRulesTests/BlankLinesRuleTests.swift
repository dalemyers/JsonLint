import Testing
@testable import JsonRules
@testable import JsonLexer
@testable import JsonParser

@Suite("Blank Lines Rule Tests")
struct BlankLinesRuleTests {
    @Test("Detects blank lines in JSON")
    func detectsBlankLines() throws {
        let source = """
        {
          "key": "value",

          "another": "value"
        }
        """
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = BlankLinesRule()
        let config = RuleConfiguration()
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        let violations = rule.validate(ast, context: context)
        #expect(violations.count == 1)
        #expect(violations[0].rule == "style.no-blank-lines")
        #expect(violations[0].message == "Blank lines are not allowed")
        #expect(violations[0].location.start.line == 3)
    }

    @Test("No violation when no blank lines")
    func noViolationWhenNoBlankLines() throws {
        let source = """
        {
          "key": "value",
          "another": "value"
        }
        """
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = BlankLinesRule()
        let config = RuleConfiguration()
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        let violations = rule.validate(ast, context: context)
        #expect(violations.isEmpty)
    }

    @Test("Detects multiple blank lines")
    func detectsMultipleBlankLines() throws {
        let source = """
        {
          "a": 1,

          "b": 2,

          "c": 3
        }
        """
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = BlankLinesRule()
        let config = RuleConfiguration()
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        let violations = rule.validate(ast, context: context)
        #expect(violations.count == 2)
        #expect(violations[0].location.start.line == 3)
        #expect(violations[1].location.start.line == 5)
    }

    @Test("Detects blank lines with only whitespace")
    func detectsWhitespaceOnlyLines() throws {
        let source = """
        {
          "key": "value",
          \t  \t
          "another": "value"
        }
        """
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = BlankLinesRule()
        let config = RuleConfiguration()
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        let violations = rule.validate(ast, context: context)
        #expect(violations.count == 1)
        #expect(violations[0].location.start.line == 3)
    }

    @Test("Rule has correct metadata")
    func ruleHasCorrectMetadata() {
        let rule = BlankLinesRule()

        #expect(rule.identifier == "style.no-blank-lines")
        #expect(rule.category == .style)
        #expect(rule.defaultSeverity == .warning)
        #expect(!rule.description.isEmpty)
    }

    @Test("Fix removes blank line")
    func fixRemovesBlankLine() throws {
        let source = """
        {
          "key": "value",

          "another": "value"
        }
        """
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = BlankLinesRule()
        let config = RuleConfiguration()
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        let violations = rule.validate(ast, context: context)
        #expect(violations.count == 1)

        let fixContext = FixContext(ast: ast, config: config, sourceText: source)
        let fix = rule.fix(violations[0], context: fixContext)
        #expect(fix != nil)
        #expect(fix?.replacement == "")
    }

    @Test("Works with arrays")
    func worksWithArrays() throws {
        let source = """
        [
          1,

          2,
          3
        ]
        """
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = BlankLinesRule()
        let config = RuleConfiguration()
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        let violations = rule.validate(ast, context: context)
        #expect(violations.count == 1)
        #expect(violations[0].location.start.line == 3)
    }

    @Test("Ignores blank line at end of file")
    func ignoresBlankLineAtEndOfFile() throws {
        let source = """
        {
          "key": "value"
        }

        """
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let rule = BlankLinesRule()
        let config = RuleConfiguration()
        let context = ValidationContext(ast: ast, config: config, sourceText: source)

        let violations = rule.validate(ast, context: context)
        #expect(violations.isEmpty)
    }
}
