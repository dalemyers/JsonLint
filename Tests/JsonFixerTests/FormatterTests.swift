import Testing
@testable import JsonFixer
@testable import JsonRules
@testable import JsonLexer
@testable import JsonParser

@Suite("Formatter Tests")
struct FormatterTests {
    @Test("Formats compact JSON")
    func formatsCompactJSON() throws {
        let source = #"{"name":"test","value":123}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration(indentSize: 2)
        let formatter = Formatter(config: config)
        let formatted = formatter.format(ast)

        #expect(formatted.contains("{\n"))
        #expect(formatted.contains("  \"name\""))
        #expect(formatted.contains("  \"value\""))
    }

    @Test("Respects indent size")
    func respectsIndentSize() throws {
        let source = #"{"key":"value"}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration(indentSize: 4)
        let formatter = Formatter(config: config)
        let formatted = formatter.format(ast)

        #expect(formatted.contains("    \"key\""))
    }

    @Test("Formats arrays")
    func formatsArrays() throws {
        let source = "[1,2,3]"
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration(indentSize: 2)
        let formatter = Formatter(config: config)
        let formatted = formatter.format(ast)

        #expect(formatted.contains("[\n"))
        #expect(formatted.contains("  1"))
        #expect(formatted.contains("  2"))
        #expect(formatted.contains("  3"))
    }

    @Test("Formats nested structures")
    func formatsNestedStructures() throws {
        let source = #"{"outer":{"inner":[1,2,3]}}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration(indentSize: 2)
        let formatter = Formatter(config: config)
        let formatted = formatter.format(ast)

        #expect(formatted.contains("  \"outer\""))
        #expect(formatted.contains("    \"inner\""))
        #expect(formatted.contains("      1"))
    }

    @Test("Uses tabs when configured")
    func usesTabsWhenConfigured() throws {
        let source = #"{"key":"value"}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration(indentStyle: .tabs, indentSize: 1)
        let formatter = Formatter(config: config)
        let formatted = formatter.format(ast)

        #expect(formatted.contains("\t\"key\""))
    }

    @Test("Handles empty objects")
    func handlesEmptyObjects() throws {
        let source = "{}"
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration()
        let formatter = Formatter(config: config)
        let formatted = formatter.format(ast)

        #expect(formatted == "{}")
    }

    @Test("Handles empty arrays")
    func handlesEmptyArrays() throws {
        let source = "[]"
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration()
        let formatter = Formatter(config: config)
        let formatted = formatter.format(ast)

        #expect(formatted == "[]")
    }

    @Test("Formats unquoted keys in JSON5")
    func formatsUnquotedKeysJSON5() throws {
        let source = "{myKey: \"value\"}"
        let lexer = Lexer(source: source, dialect: .json5)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration(dialect: .json5, indentSize: 2)
        let formatter = Formatter(config: config)
        let formatted = formatter.format(ast)

        #expect(formatted.contains("myKey"))
        #expect(!formatted.contains("\"myKey\""))
    }

    @Test("Escapes quotes in strings")
    func escapesQuotesInStrings() throws {
        let source = #"{"key":"value with \"quotes\""}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration()
        let formatter = Formatter(config: config)
        let formatted = formatter.format(ast)

        #expect(formatted.contains("\\\""))
    }

    @Test("Escapes single quotes in JSON5")
    func escapesSingleQuotesJSON5() throws {
        let source = "{'key': 'value with \\'quotes\\''}"
        let lexer = Lexer(source: source, dialect: .json5)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration(dialect: .json5, quoteStyle: .single)
        let formatter = Formatter(config: config)
        let formatted = formatter.format(ast)

        #expect(formatted.contains("\\'"))
    }

    @Test("Escapes backslashes in strings")
    func escapesBackslashes() throws {
        let source = #"{"path":"C:\\Users\\test"}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration()
        let formatter = Formatter(config: config)
        let formatted = formatter.format(ast)

        #expect(formatted.contains("\\\\"))
    }

    @Test("Escapes newlines in strings")
    func escapesNewlines() throws {
        let source = #"{"text":"line1\nline2"}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration()
        let formatter = Formatter(config: config)
        let formatted = formatter.format(ast)

        #expect(formatted.contains("\\n"))
    }

    @Test("Escapes carriage returns in strings")
    func escapesCarriageReturns() throws {
        let source = #"{"text":"line1\rline2"}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration()
        let formatter = Formatter(config: config)
        let formatted = formatter.format(ast)

        #expect(formatted.contains("\\r"))
    }

    @Test("Escapes tabs in strings")
    func escapesTabs() throws {
        let source = #"{"text":"column1\tcolumn2"}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let config = RuleConfiguration()
        let formatter = Formatter(config: config)
        let formatted = formatter.format(ast)

        #expect(formatted.contains("\\t"))
    }
}
