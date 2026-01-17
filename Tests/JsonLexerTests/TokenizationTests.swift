import Testing
@testable import JsonLexer

@Suite("Lexer Tokenization")
struct TokenizationTests {
    @Test("Empty object")
    func emptyObject() throws {
        let lexer = Lexer(source: "{}", dialect: .json)
        let tokens = try lexer.tokenize()

        #expect(tokens.count == 3)
        #expect(tokens[0].type == .leftBrace)
        #expect(tokens[1].type == .rightBrace)
        #expect(tokens[2].type == .eof)
    }

    @Test("Empty array")
    func emptyArray() throws {
        let lexer = Lexer(source: "[]", dialect: .json)
        let tokens = try lexer.tokenize()

        #expect(tokens.count == 3)
        #expect(tokens[0].type == .leftBracket)
        #expect(tokens[1].type == .rightBracket)
        #expect(tokens[2].type == .eof)
    }

    @Test("Simple string")
    func simpleString() throws {
        let lexer = Lexer(source: #""hello""#, dialect: .json)
        let tokens = try lexer.tokenize()

        #expect(tokens.count == 2)
        #expect(tokens[0].type == .string(quote: .double))
        if case .string(let value) = tokens[0].value {
            #expect(value == "hello")
        } else {
            Issue.record("Expected string value")
        }
    }

    @Test("String with escapes")
    func stringWithEscapes() throws {
        let lexer = Lexer(source: #""hello\nworld""#, dialect: .json)
        let tokens = try lexer.tokenize()

        #expect(tokens.count == 2)
        if case .string(let value) = tokens[0].value {
            #expect(value == "hello\nworld")
        } else {
            Issue.record("Expected string value with newline")
        }
    }

    @Test("Numbers")
    func numbers() throws {
        let testCases: [(String, Double)] = [
            ("42", 42),
            ("3.14", 3.14),
            ("-10", -10),
            ("1e5", 1e5),
            ("1.5e-3", 1.5e-3),
        ]

        for (source, expected) in testCases {
            let lexer = Lexer(source: source, dialect: .json)
            let tokens = try lexer.tokenize()

            #expect(tokens.count == 2)
            #expect(tokens[0].type == .number)
            if case .number(let value) = tokens[0].value {
                #expect(value == expected)
            } else {
                Issue.record("Expected number value for \(source)")
            }
        }
    }

    @Test("Booleans")
    func booleans() throws {
        let lexer1 = Lexer(source: "true", dialect: .json)
        let tokens1 = try lexer1.tokenize()
        #expect(tokens1[0].type == .boolean)
        if case .boolean(let value) = tokens1[0].value {
            #expect(value == true)
        }

        let lexer2 = Lexer(source: "false", dialect: .json)
        let tokens2 = try lexer2.tokenize()
        #expect(tokens2[0].type == .boolean)
        if case .boolean(let value) = tokens2[0].value {
            #expect(value == false)
        }
    }

    @Test("Null")
    func null() throws {
        let lexer = Lexer(source: "null", dialect: .json)
        let tokens = try lexer.tokenize()

        #expect(tokens.count == 2)
        #expect(tokens[0].type == .null)
    }

    @Test("Whitespace preservation")
    func whitespacePreservation() throws {
        let lexer = Lexer(source: "  {  }  ", dialect: .json)
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .whitespace)
        #expect(tokens[1].type == .leftBrace)
        #expect(tokens[2].type == .whitespace)
        #expect(tokens[3].type == .rightBrace)
        #expect(tokens[4].type == .whitespace)
        #expect(tokens[5].type == .eof)
    }

    @Test("Location tracking")
    func locationTracking() throws {
        let source = """
        {
          "key": 123
        }
        """
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()

        let keyToken = tokens.first {
            if case .string = $0.type { return true }
            return false
        }

        #expect(keyToken?.location.line == 2)
        #expect(keyToken?.location.column == 3)
    }

    @Test("JSON5 single quotes")
    func json5SingleQuotes() throws {
        let lexer = Lexer(source: "'hello'", dialect: .json5)
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .string(quote: .single))
        if case .string(let value) = tokens[0].value {
            #expect(value == "hello")
        }
    }

    @Test("JSON5 single line comment")
    func json5SingleLineComment() throws {
        let lexer = Lexer(source: "// comment\n42", dialect: .json5)
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .singleLineComment)
        if case .comment(let value) = tokens[0].value {
            #expect(value == " comment")
        }
    }

    @Test("JSON5 multi-line comment")
    func json5MultiLineComment() throws {
        let lexer = Lexer(source: "/* comment */", dialect: .json5)
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .multiLineComment)
        if case .comment(let value) = tokens[0].value {
            #expect(value == " comment ")
        }
    }

    @Test("JSON5 unquoted keys")
    func json5UnquotedKeys() throws {
        let lexer = Lexer(source: "key", dialect: .json5)
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .identifier)
        if case .identifier(let value) = tokens[0].value {
            #expect(value == "key")
        }
    }

    @Test("JSONC comments allowed")
    func jsoncComments() throws {
        let lexer = Lexer(source: "// comment", dialect: .jsonc)
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .singleLineComment)
    }
}
