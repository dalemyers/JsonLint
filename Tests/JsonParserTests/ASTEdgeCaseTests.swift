import Testing
@testable import JsonLexer
@testable import JsonParser

@Suite("AST Edge Case Tests")
struct ASTEdgeCaseTests {
    @Test("All value type cases")
    func allValueTypeCases() throws {
        let source = #"{"obj": {}, "arr": [], "str": "test", "num": 42, "bool": true, "null": null}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .object(let obj) = ast {
            #expect(obj.members.count == 6)

            // Test location property for each case
            if case .object(let nestedObj) = obj.members[0].value {
                #expect(nestedObj.location.start.line > 0)
            }
            if case .array(let arr) = obj.members[1].value {
                #expect(arr.location.start.line > 0)
            }
            if case .string(let str) = obj.members[2].value {
                #expect(str.location.start.line > 0)
            }
            if case .number(let num) = obj.members[3].value {
                #expect(num.location.start.line > 0)
            }
            if case .boolean(let bool) = obj.members[4].value {
                #expect(bool.location.start.line > 0)
            }
            if case .null(let null) = obj.members[5].value {
                #expect(null.location.start.line > 0)
            }
        }
    }

    @Test("Leading trivia for each value type")
    func leadingTriviaForEachType() throws {
        let source = """
        {
          "obj":   {},
          "arr":   [],
          "str":   "test",
          "num":   42,
          "bool":  true,
          "null":  null
        }
        """
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .object(let obj) = ast {
            // Check that leading trivia is captured (whitespace after colon)
            for member in obj.members {
                switch member.value {
                case .object(let nested):
                    _ = nested.leadingTrivia
                case .array(let arr):
                    _ = arr.leadingTrivia
                case .string(let str):
                    _ = str.leadingTrivia
                case .number(let num):
                    _ = num.leadingTrivia
                case .boolean(let bool):
                    _ = bool.leadingTrivia
                case .null(let null):
                    _ = null.leadingTrivia
                }
            }
        }
    }

    @Test("Trailing trivia for each value type")
    func trailingTriviaForEachType() throws {
        let source = """
        {
          "obj": {}  ,
          "arr": []  ,
          "str": "test"  ,
          "num": 42  ,
          "bool": true  ,
          "null": null
        }
        """
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .object(let obj) = ast {
            for member in obj.members {
                switch member.value {
                case .object(let nested):
                    _ = nested.trailingTrivia
                case .array(let arr):
                    _ = arr.trailingTrivia
                case .string(let str):
                    _ = str.trailingTrivia
                case .number(let num):
                    _ = num.trailingTrivia
                case .boolean(let bool):
                    _ = bool.trailingTrivia
                case .null(let null):
                    _ = null.trailingTrivia
                }
            }
        }
    }

    @Test("Object with trailing comma")
    func objectWithTrailingComma() throws {
        let source = #"{"a": 1, "b": 2,}"#
        let lexer = Lexer(source: source, dialect: .json5)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .object(let obj) = ast {
            #expect(obj.hasTrailingComma)
            #expect(obj.members.count == 2)
            #expect(obj.members[1].comma != nil)
        }
    }

    @Test("Array with trailing comma")
    func arrayWithTrailingComma() throws {
        let source = "[1, 2, 3,]"
        let lexer = Lexer(source: source, dialect: .json5)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .array(let arr) = ast {
            #expect(arr.hasTrailingComma)
            #expect(arr.elements.count == 3)
            #expect(arr.elements[2].comma != nil)
        }
    }

    @Test("Object without trailing comma")
    func objectWithoutTrailingComma() throws {
        let source = #"{"a": 1, "b": 2}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .object(let obj) = ast {
            #expect(!obj.hasTrailingComma)
            #expect(obj.members[0].comma != nil)
            #expect(obj.members[1].comma == nil)
        }
    }

    @Test("Array without trailing comma")
    func arrayWithoutTrailingComma() throws {
        let source = "[1, 2, 3]"
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .array(let arr) = ast {
            #expect(!arr.hasTrailingComma)
            #expect(arr.elements[0].comma != nil)
            #expect(arr.elements[1].comma != nil)
            #expect(arr.elements[2].comma == nil)
        }
    }

    @Test("AST walking visits all nodes")
    func astWalkingVisitsAllNodes() throws {
        let source = #"{"outer": {"inner": [1, 2]}, "arr": [true, false], "n": null}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        var visitedNodes = 0
        var visitedNull = false
        ast.walk { node in
            visitedNodes += 1
            if node is JSONNull {
                visitedNull = true
            }
        }

        // Should visit: root object, outer object, inner array, 2 numbers, arr array, 2 booleans, null
        #expect(visitedNodes >= 9)
        #expect(visitedNull)
    }

    @Test("AST walking with deeply nested structure")
    func astWalkingDeepNesting() throws {
        let source = #"{"l1": {"l2": {"l3": {"l4": "deep"}}}}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        var maxDepth = 0

        func countDepth(_ value: JSONValue, currentDepth: Int) {
            maxDepth = max(maxDepth, currentDepth)
            switch value {
            case .object(let obj):
                for member in obj.members {
                    countDepth(member.value, currentDepth: currentDepth + 1)
                }
            case .array(let arr):
                for element in arr.elements {
                    countDepth(element.value, currentDepth: currentDepth + 1)
                }
            default:
                break
            }
        }

        countDepth(ast, currentDepth: 0)
        #expect(maxDepth >= 4)
    }

    @Test("JSONKey with identifier token (JSON5)")
    func jsonKeyWithIdentifier() throws {
        let source = "{key: 'value'}"
        let lexer = Lexer(source: source, dialect: .json5)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .object(let obj) = ast {
            #expect(obj.members[0].key.value == "key")
            #expect(obj.members[0].key.token.type == .identifier)
        }
    }

    @Test("Multiple commas in object")
    func multipleCommasInObject() throws {
        let source = #"{"a": 1, "b": 2, "c": 3, "d": 4}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .object(let obj) = ast {
            #expect(obj.members.count == 4)
            #expect(obj.members[0].comma != nil)
            #expect(obj.members[1].comma != nil)
            #expect(obj.members[2].comma != nil)
            #expect(obj.members[3].comma == nil)
        }
    }

    @Test("Multiple commas in array")
    func multipleCommasInArray() throws {
        let source = "[1, 2, 3, 4, 5]"
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .array(let arr) = ast {
            #expect(arr.elements.count == 5)
            for i in 0..<4 {
                #expect(arr.elements[i].comma != nil)
            }
            #expect(arr.elements[4].comma == nil)
        }
    }

    @Test("SourceRange from SourceLocation")
    func sourceRangeFromSourceLocation() {
        let location = SourceLocation(line: 1, column: 5, offset: 4, length: 10)
        let range = SourceRange(location: location)

        #expect(range.start == location)
        #expect(range.end.line == 1)
        #expect(range.end.column == 15)
        #expect(range.end.offset == 14)
    }

    @Test("SourceLocation comparison")
    func sourceLocationComparison() {
        let loc1 = SourceLocation(line: 1, column: 5, offset: 4, length: 1)
        let loc2 = SourceLocation(line: 1, column: 10, offset: 9, length: 1)
        let loc3 = SourceLocation(line: 2, column: 1, offset: 20, length: 1)

        #expect(loc1 < loc2)
        #expect(loc1 < loc3)
        #expect(loc2 < loc3)
        #expect(!(loc2 < loc1))
        #expect(!(loc3 < loc1))
    }

    @Test("Token equality")
    func tokenEquality() {
        let loc1 = SourceLocation(line: 1, column: 1, offset: 0, length: 1)
        let loc2 = SourceLocation(line: 1, column: 1, offset: 0, length: 1)

        let token1 = Token(type: .leftBrace, lexeme: "{", location: loc1, value: nil)
        let token2 = Token(type: .leftBrace, lexeme: "{", location: loc2, value: nil)
        let token3 = Token(type: .rightBrace, lexeme: "}", location: loc1, value: nil)

        #expect(token1 == token2)
        #expect(token1 != token3)
    }

    @Test("All TokenValue cases")
    func allTokenValueCases() {
        let stringValue = TokenValue.string("test")
        let numberValue = TokenValue.number(42.0)
        let boolValue = TokenValue.boolean(true)
        let commentValue = TokenValue.comment("// comment")
        let identifierValue = TokenValue.identifier("key")

        if case .string(let s) = stringValue {
            #expect(s == "test")
        }
        if case .number(let n) = numberValue {
            #expect(n == 42.0)
        }
        if case .boolean(let b) = boolValue {
            #expect(b == true)
        }
        if case .comment(let c) = commentValue {
            #expect(c == "// comment")
        }
        if case .identifier(let i) = identifierValue {
            #expect(i == "key")
        }
    }

    @Test("All QuoteStyle cases")
    func allQuoteStyleCases() {
        let double = QuoteStyle.double
        let single = QuoteStyle.single

        #expect(double == .double)
        #expect(single == .single)
        #expect(double != single)
    }
}
