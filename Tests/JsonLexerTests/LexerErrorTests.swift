import Testing
@testable import JsonLexer

@Suite("Lexer Error Tests")
struct LexerErrorTests {
    @Test("Unterminated string at EOF")
    func unterminatedStringEOF() throws {
        let lexer = Lexer(source: #""hello"#, dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Unterminated string with escaped quote")
    func unterminatedStringEscaped() throws {
        let lexer = Lexer(source: #""hello\""#, dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Unterminated string with backslash at end")
    func unterminatedStringBackslash() throws {
        let lexer = Lexer(source: #""hello\"#, dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Invalid escape sequence")
    func invalidEscapeSequence() throws {
        let lexer = Lexer(source: #""hello\x""#, dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Invalid character")
    func invalidCharacter() throws {
        let lexer = Lexer(source: "§", dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Single quotes not allowed in JSON")
    func singleQuotesNotAllowed() throws {
        let lexer = Lexer(source: "'hello'", dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Unquoted keys not allowed in JSON")
    func unquotedKeysNotAllowed() throws {
        let lexer = Lexer(source: "{key: 'value'}", dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Invalid unicode escape - too short")
    func invalidUnicodeEscapeTooShort() throws {
        let lexer = Lexer(source: #""hello\u00""#, dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Invalid unicode escape - non-hex")
    func invalidUnicodeEscapeNonHex() throws {
        let lexer = Lexer(source: #""hello\u00ZZ""#, dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Valid unicode escape")
    func validUnicodeEscape() throws {
        let lexer = Lexer(source: #""hello\u0041""#, dialect: .json)
        let tokens = try lexer.tokenize()

        if case .string(let value) = tokens[0].value {
            #expect(value == "helloA")
        }
    }

    @Test("Invalid number format")
    func invalidNumberFormat() throws {
        let lexer = Lexer(source: "12.34.56", dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("LexerError descriptions")
    func lexerErrorDescriptions() {
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 1)

        let error1 = LexerError(type: .unterminatedString, location: loc, context: "\"hello")
        #expect(error1.description.contains("Unterminated string"))

        let error2 = LexerError(type: .invalidEscapeSequence("\\x"), location: loc, context: "\\x")
        #expect(error2.description.contains("Invalid escape sequence"))
        #expect(error2.description.contains("\\x"))

        let error3 = LexerError(type: .invalidNumber("123abc"), location: loc, context: "123abc")
        #expect(error3.description.contains("Invalid number"))
        #expect(error3.description.contains("123abc"))

        let error4 = LexerError(type: .invalidCharacter("§"), location: loc, context: "§")
        #expect(error4.description.contains("Invalid character"))
        #expect(error4.description.contains("§"))

        let error5 = LexerError(type: .unexpectedEndOfFile, location: loc, context: "")
        #expect(error5.description.contains("Unexpected end of file"))

        let error6 = LexerError(type: .invalidUnicodeEscape, location: loc, context: "\\u00ZZ")
        #expect(error6.description.contains("Invalid unicode escape"))

        let error7 = LexerError(type: .singleQuotesNotAllowed, location: loc, context: "'")
        #expect(error7.description.contains("Single quotes not allowed"))

        let error8 = LexerError(type: .unquotedKeysNotAllowed, location: loc, context: "key")
        #expect(error8.description.contains("Unquoted keys not allowed"))
    }
}
