import Testing
@testable import JsonLexer
@testable import JsonParser

@Suite("Parser Error Tests")
struct ParserErrorTests {
    @Test("Unexpected end of file")
    func unexpectedEndOfFile() throws {
        let source = "{"
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("Invalid value at top level")
    func invalidValueAtTopLevel() throws {
        let source = ","
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("Missing colon after key")
    func missingColonAfterKey() throws {
        let source = #"{"key" "value"}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("Missing closing brace")
    func missingClosingBrace() throws {
        let source = #"{"key": "value""#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("Missing closing bracket")
    func missingClosingBracket() throws {
        let source = "[1, 2, 3"
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("Invalid object key")
    func invalidObjectKey() throws {
        let source = "{123: \"value\"}"
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("Missing comma between object members")
    func missingCommaBetweenMembers() throws {
        let source = #"{"a": 1 "b": 2}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("Missing comma between array elements")
    func missingCommaBetweenElements() throws {
        let source = "[1 2]"
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("Extra tokens after valid JSON")
    func extraTokensAfterValidJSON() throws {
        let source = "{} }"
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("Incomplete object member")
    func incompleteObjectMember() throws {
        let source = #"{"key":}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("Empty source")
    func emptySource() throws {
        let source = ""
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("Only whitespace")
    func onlyWhitespace() throws {
        let source = "   \n\t  "
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("ParserError description")
    func parserErrorDescription() {
        let location = SourceRange(
            start: SourceLocation(line: 1, column: 5, offset: 4, length: 1),
            end: SourceLocation(line: 1, column: 6, offset: 5, length: 1)
        )
        let token = Token(
            type: .rightBrace,
            lexeme: "}",
            location: SourceLocation(line: 1, column: 5, offset: 4, length: 1),
            value: nil
        )

        let error1 = ParserError(
            type: .unexpectedToken(expected: "value", got: .rightBrace),
            location: location,
            token: token
        )
        #expect(error1.description.contains("1:5"))
        #expect(error1.description.contains("}"))

        let error2 = ParserError(
            type: .unexpectedEndOfFile,
            location: location
        )
        #expect(error2.description.contains("Unexpected end of file"))

        let error3 = ParserError(
            type: .duplicateKey("test"),
            location: location
        )
        #expect(error3.description.contains("test"))

        let error4 = ParserError(
            type: .invalidValue,
            location: location
        )
        #expect(error4.description.contains("Invalid value"))

        let error5 = ParserError(
            type: .expectedColon,
            location: location
        )
        #expect(error5.description.contains("':'"))

        let error6 = ParserError(
            type: .expectedCommaOrClosingBrace,
            location: location
        )
        #expect(error6.description.contains("',' or '}'"))

        let error7 = ParserError(
            type: .expectedCommaOrClosingBracket,
            location: location
        )
        #expect(error7.description.contains("',' or ']'"))
    }
}
