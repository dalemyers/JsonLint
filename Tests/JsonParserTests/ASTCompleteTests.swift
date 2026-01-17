import Testing
@testable import JsonLexer
@testable import JsonParser

@Suite("AST Complete Coverage Tests")
struct ASTCompleteTests {
    @Test("JSONValue location property for all types")
    func jsonValueLocationProperty() throws {
        let source = #"{"obj": {}, "arr": [], "str": "test", "num": 42, "bool": true, "null": null}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .object(let obj) = ast {
            // Test location property on JSONValue enum
            for member in obj.members {
                let valueLocation = member.value.location
                #expect(valueLocation.start.line > 0)
            }
        }
    }

    @Test("Direct JSONObject initialization")
    func directJSONObjectInit() {
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 2)
        let range = SourceRange(location: loc)

        let keyToken = Token(type: .string(quote: .double), lexeme: "\"key\"", location: loc, value: .string("key"))
        let colonToken = Token(type: .colon, lexeme: ":", location: loc, value: nil)
        let valueToken = Token(type: .string(quote: .double), lexeme: "\"value\"", location: loc, value: .string("value"))

        let key = JSONKey(token: keyToken, value: "key", location: range)
        let value = JSONValue.string(JSONString(
            location: range,
            leadingTrivia: [],
            trailingTrivia: [],
            token: valueToken,
            value: "value"
        ))

        let member = JSONObject.Member(key: key, colon: colonToken, value: value, comma: nil)

        let obj = JSONObject(
            location: range,
            leadingTrivia: [],
            trailingTrivia: [],
            members: [member],
            hasTrailingComma: false
        )

        #expect(obj.members.count == 1)
        #expect(obj.hasTrailingComma == false)
    }

    @Test("Direct JSONArray initialization")
    func directJSONArrayInit() {
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 1)
        let range = SourceRange(location: loc)

        let numToken = Token(type: .number, lexeme: "42", location: loc, value: .number(42))
        let value = JSONValue.number(JSONNumber(
            location: range,
            leadingTrivia: [],
            trailingTrivia: [],
            token: numToken,
            value: 42.0
        ))

        let element = JSONArray.Element(value: value, comma: nil)

        let arr = JSONArray(
            location: range,
            leadingTrivia: [],
            trailingTrivia: [],
            elements: [element],
            hasTrailingComma: false
        )

        #expect(arr.elements.count == 1)
        #expect(arr.hasTrailingComma == false)
    }

    @Test("Direct JSONString initialization")
    func directJSONStringInit() {
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 4)
        let range = SourceRange(location: loc)
        let token = Token(type: .string(quote: .double), lexeme: "\"hi\"", location: loc, value: .string("hi"))

        let str = JSONString(
            location: range,
            leadingTrivia: [],
            trailingTrivia: [],
            token: token,
            value: "hi"
        )

        #expect(str.value == "hi")
        #expect(str.location == range)
    }

    @Test("Direct JSONNumber initialization")
    func directJSONNumberInit() {
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 2)
        let range = SourceRange(location: loc)
        let token = Token(type: .number, lexeme: "99", location: loc, value: .number(99))

        let num = JSONNumber(
            location: range,
            leadingTrivia: [],
            trailingTrivia: [],
            token: token,
            value: 99.0
        )

        #expect(num.value == 99.0)
        #expect(num.location == range)
    }

    @Test("Direct JSONBoolean initialization")
    func directJSONBooleanInit() {
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 4)
        let range = SourceRange(location: loc)
        let token = Token(type: .boolean, lexeme: "true", location: loc, value: .boolean(true))

        let bool = JSONBoolean(
            location: range,
            leadingTrivia: [],
            trailingTrivia: [],
            token: token,
            value: true
        )

        #expect(bool.value == true)
        #expect(bool.location == range)
    }

    @Test("Direct JSONNull initialization")
    func directJSONNullInit() {
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 4)
        let range = SourceRange(location: loc)
        let token = Token(type: .null, lexeme: "null", location: loc, value: nil)

        let null = JSONNull(
            location: range,
            leadingTrivia: [],
            trailingTrivia: [],
            token: token
        )

        #expect(null.location == range)
    }

    @Test("SourceRange initialization from two locations")
    func sourceRangeFromTwoLocations() {
        let start = SourceLocation(line: 1, column: 5, offset: 4, length: 3)
        let end = SourceLocation(line: 1, column: 10, offset: 9, length: 2)

        let range = SourceRange(start: start, end: end)

        #expect(range.start == start)
        #expect(range.end == end)
    }
}
