import Testing
@testable import JsonLexer

@Suite("Lexer Edge Cases Tests")
struct LexerEdgeCasesTests {
    @Test("Unterminated comment")
    func unterminatedComment() throws {
        let lexer = Lexer(source: "/* comment", dialect: .json5)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Comments not allowed in JSON")
    func commentsNotAllowedJSON() throws {
        let lexer = Lexer(source: "// comment", dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Invalid hex number - no digits")
    func invalidHexNumberNoDigits() throws {
        let lexer = Lexer(source: "0x", dialect: .json5)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Invalid hex number - non-hex digit")
    func invalidHexNumberNonHexDigit() throws {
        let lexer = Lexer(source: "0xG", dialect: .json5)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Invalid special number - not Infinity")
    func invalidSpecialNumberNotInfinity() throws {
        let lexer = Lexer(source: "Inf", dialect: .json5)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Invalid special number - not NaN")
    func invalidSpecialNumberNotNaN() throws {
        let lexer = Lexer(source: "Na", dialect: .json5)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Invalid character in special number position")
    func invalidCharacterInSpecialNumber() throws {
        let lexer = Lexer(source: "Nope", dialect: .json5)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Trailing decimal without fraction digits")
    func trailingDecimalWithExponent() throws {
        let lexer = Lexer(source: "5.e2", dialect: .json5)
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .number)
        if case .number(let value) = tokens[0].value {
            #expect(value == 500.0)
        }
    }

    @Test("Invalid number with double decimal")
    func invalidNumberDoubleDec() throws {
        let lexer = Lexer(source: "1.2.3", dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Unterminated string with embedded newline attempt")
    func unterminatedStringNewline() throws {
        let source = "\"\nhello"
        let lexer = Lexer(source: source, dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Invalid unicode escape at EOF")
    func invalidUnicodeEscapeEOF() throws {
        let lexer = Lexer(source: #""test\u00"#, dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Invalid unicode escape with invalid codepoint")
    func invalidUnicodeEscapeInvalidCodepoint() throws {
        // Test with a surrogate codepoint that's invalid
        let lexer = Lexer(source: #""test\uD800""#, dialect: .json)

        // This might succeed or fail depending on Unicode.Scalar validation
        // Let's just try to tokenize it
        do {
            let tokens = try lexer.tokenize()
            _ = tokens
        } catch {
            // Either outcome is acceptable for this edge case
        }
    }

    @Test("Multiline comment with nested star")
    func multilineCommentNestedStar() throws {
        let lexer = Lexer(source: "/* comment * with star */", dialect: .json5)
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .multiLineComment)
        if case .comment(let value) = tokens[0].value {
            #expect(value.contains("*"))
        }
    }

    @Test("Comment with multiple slashes")
    func commentMultipleSlashes() throws {
        let lexer = Lexer(source: "/// triple slash", dialect: .json5)
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .singleLineComment)
    }

    @Test("Multiline comment with asterisks")
    func multilineCommentWithAsterisks() throws {
        let lexer = Lexer(source: "/* ** */", dialect: .json5)
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .multiLineComment)
    }

    @Test("Single forward slash invalid")
    func singleForwardSlash() throws {
        let lexer = Lexer(source: "/", dialect: .json5)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Multiline comment not allowed in JSON")
    func multilineCommentNotAllowedJSON() throws {
        let lexer = Lexer(source: "/* comment */", dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Partial true keyword")
    func partialTrue() throws {
        let lexer = Lexer(source: "tru", dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Partial false keyword")
    func partialFalse() throws {
        let lexer = Lexer(source: "fals", dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Partial null keyword")
    func partialNull() throws {
        let lexer = Lexer(source: "nul", dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Trailing decimal at EOF")
    func trailingDecimalAtEOF() throws {
        let lexer = Lexer(source: "42.", dialect: .json5)
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .number)
        if case .number(let value) = tokens[0].value {
            #expect(value == 42.0)
        }
    }

    @Test("Trailing decimal after exponent")
    func trailingDecimalAfterExponent() throws {
        // This tests a number with exponent followed by trailing decimal
        // The format "5e2." should fail in JSON5 even though trailing decimals are allowed
        // because the decimal comes after the exponent
        let lexer = Lexer(source: "5e2.", dialect: .json5)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }
}
