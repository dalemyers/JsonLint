import Testing
@testable import JsonLexer
@testable import JsonParser

@Suite("Parser Internal Coverage Tests")
struct ParserInternalTests {
    @Test("String token without value throws error")
    func stringTokenWithoutValue() throws {
        // Create a malformed token stream: string token without value
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 1)
        let stringToken = Token(type: .string(quote: .double), lexeme: "\"", location: loc, value: nil)
        let eofToken = Token(type: .eof, lexeme: "", location: loc, value: nil)

        let tokens = [stringToken, eofToken]
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("Number token without value throws error")
    func numberTokenWithoutValue() throws {
        // Create a malformed token stream: number token without value
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 1)
        let numberToken = Token(type: .number, lexeme: "1", location: loc, value: nil)
        let eofToken = Token(type: .eof, lexeme: "", location: loc, value: nil)

        let tokens = [numberToken, eofToken]
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("Boolean token without value throws error")
    func booleanTokenWithoutValue() throws {
        // Create a malformed token stream: boolean token without value
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 4)
        let boolToken = Token(type: .boolean, lexeme: "true", location: loc, value: nil)
        let eofToken = Token(type: .eof, lexeme: "", location: loc, value: nil)

        let tokens = [boolToken, eofToken]
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("Object key that is EOF throws unexpectedEndOfFile")
    func objectKeyAtEOF() throws {
        // Create token stream: { EOF
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 1)
        let leftBrace = Token(type: .leftBrace, lexeme: "{", location: loc, value: nil)
        let eofToken = Token(type: .eof, lexeme: "", location: loc, value: nil)

        let tokens = [leftBrace, eofToken]
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("String key token with wrong value type")
    func stringKeyTokenWithWrongValue() throws {
        // Create malformed token stream: string token with number value
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 1)
        let leftBrace = Token(type: .leftBrace, lexeme: "{", location: loc, value: nil)
        let badStringToken = Token(type: .string(quote: .double), lexeme: "\"key\"", location: loc, value: .number(42))
        let eofToken = Token(type: .eof, lexeme: "", location: loc, value: nil)

        let tokens = [leftBrace, badStringToken, eofToken]
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("Identifier key token with wrong value type")
    func identifierKeyTokenWithWrongValue() throws {
        // Create malformed token stream: identifier token with boolean value
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 1)
        let leftBrace = Token(type: .leftBrace, lexeme: "{", location: loc, value: nil)
        let badIdentToken = Token(type: .identifier, lexeme: "key", location: loc, value: .boolean(true))
        let eofToken = Token(type: .eof, lexeme: "", location: loc, value: nil)

        let tokens = [leftBrace, badIdentToken, eofToken]
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("Array with invalid element type")
    func arrayWithInvalidElement() throws {
        // Create token stream: [ comma ]
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 1)
        let leftBracket = Token(type: .leftBracket, lexeme: "[", location: loc, value: nil)
        let comma = Token(type: .comma, lexeme: ",", location: loc, value: nil)
        let rightBracket = Token(type: .rightBracket, lexeme: "]", location: loc, value: nil)
        let eofToken = Token(type: .eof, lexeme: "", location: loc, value: nil)

        let tokens = [leftBracket, comma, rightBracket, eofToken]
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("Object with number as key")
    func objectWithNumberKey() throws {
        // This should be caught by normal parsing
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 1)
        let leftBrace = Token(type: .leftBrace, lexeme: "{", location: loc, value: nil)
        let numberToken = Token(type: .number, lexeme: "42", location: loc, value: .number(42))
        let colonToken = Token(type: .colon, lexeme: ":", location: loc, value: nil)
        let stringToken = Token(type: .string(quote: .double), lexeme: "\"val\"", location: loc, value: .string("val"))
        let rightBrace = Token(type: .rightBrace, lexeme: "}", location: loc, value: nil)
        let eofToken = Token(type: .eof, lexeme: "", location: loc, value: nil)

        let tokens = [leftBrace, numberToken, colonToken, stringToken, rightBrace, eofToken]
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }
}
