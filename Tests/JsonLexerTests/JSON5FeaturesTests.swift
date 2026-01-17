import Testing
@testable import JsonLexer

@Suite("JSON5 Features Tests")
struct JSON5FeaturesTests {
    @Test("Hex numbers in JSON5")
    func hexNumbersJSON5() throws {
        let lexer = Lexer(source: "0xFF", dialect: .json5)
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .number)
        if case .number(let value) = tokens[0].value {
            #expect(value == 255.0)
        }
    }

    @Test("Hex numbers not allowed in JSON")
    func hexNumbersNotAllowedJSON() throws {
        let lexer = Lexer(source: "0xFF", dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Plus sign in numbers JSON5")
    func plusSignJSON5() throws {
        let lexer = Lexer(source: "+42", dialect: .json5)
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .number)
        if case .number(let value) = tokens[0].value {
            #expect(value == 42.0)
        }
    }

    @Test("Plus sign not allowed in JSON")
    func plusSignNotAllowedJSON() throws {
        let lexer = Lexer(source: "+42", dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Leading decimal point JSON5")
    func leadingDecimalPointJSON5() throws {
        let lexer = Lexer(source: ".5", dialect: .json5)
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .number)
        if case .number(let value) = tokens[0].value {
            #expect(value == 0.5)
        }
    }

    @Test("Leading decimal point not allowed in JSON")
    func leadingDecimalPointNotAllowedJSON() throws {
        let lexer = Lexer(source: ".5", dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Trailing decimal point JSON5")
    func trailingDecimalPointJSON5() throws {
        let lexer = Lexer(source: "5.", dialect: .json5)
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .number)
        if case .number(let value) = tokens[0].value {
            #expect(value == 5.0)
        }
    }

    @Test("Infinity in JSON5")
    func infinityJSON5() throws {
        let lexer = Lexer(source: "Infinity", dialect: .json5)
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .number)
        if case .number(let value) = tokens[0].value {
            #expect(value.isInfinite)
            #expect(value > 0)
        }
    }

    @Test("NaN in JSON5")
    func nanJSON5() throws {
        let lexer = Lexer(source: "NaN", dialect: .json5)
        let tokens = try lexer.tokenize()

        #expect(tokens[0].type == .number)
        if case .number(let value) = tokens[0].value {
            #expect(value.isNaN)
        }
    }

    @Test("Infinity not allowed in JSON")
    func infinityNotAllowedJSON() throws {
        let lexer = Lexer(source: "Infinity", dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("NaN not allowed in JSON")
    func nanNotAllowedJSON() throws {
        let lexer = Lexer(source: "NaN", dialect: .json)

        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Dialect properties - allowsTrailingCommas")
    func dialectAllowsTrailingCommas() {
        #expect(!Dialect.json.allowsTrailingCommas)
        #expect(Dialect.json5.allowsTrailingCommas)
        #expect(!Dialect.jsonc.allowsTrailingCommas)
    }

    @Test("Dialect properties - allowsHexNumbers")
    func dialectAllowsHexNumbers() {
        #expect(!Dialect.json.allowsHexNumbers)
        #expect(Dialect.json5.allowsHexNumbers)
        #expect(!Dialect.jsonc.allowsHexNumbers)
    }

    @Test("Dialect properties - allowsInfinityAndNaN")
    func dialectAllowsInfinityAndNaN() {
        #expect(!Dialect.json.allowsInfinityAndNaN)
        #expect(Dialect.json5.allowsInfinityAndNaN)
        #expect(!Dialect.jsonc.allowsInfinityAndNaN)
    }

    @Test("Dialect properties - allowsLeadingDecimalPoint")
    func dialectAllowsLeadingDecimalPoint() {
        #expect(!Dialect.json.allowsLeadingDecimalPoint)
        #expect(Dialect.json5.allowsLeadingDecimalPoint)
        #expect(!Dialect.jsonc.allowsLeadingDecimalPoint)
    }

    @Test("Dialect properties - allowsTrailingDecimalPoint")
    func dialectAllowsTrailingDecimalPoint() {
        #expect(!Dialect.json.allowsTrailingDecimalPoint)
        #expect(Dialect.json5.allowsTrailingDecimalPoint)
        #expect(!Dialect.jsonc.allowsTrailingDecimalPoint)
    }

    @Test("Dialect properties - allowsPlusSign")
    func dialectAllowsPlusSign() {
        #expect(!Dialect.json.allowsPlusSign)
        #expect(Dialect.json5.allowsPlusSign)
        #expect(!Dialect.jsonc.allowsPlusSign)
    }
}
