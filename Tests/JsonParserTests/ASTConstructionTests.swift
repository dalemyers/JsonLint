import Testing
@testable import JsonLexer
@testable import JsonParser

@Suite("Parser AST Construction")
struct ASTConstructionTests {
    @Test("Empty object")
    func emptyObject() throws {
        let source = "{}"
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .object(let obj) = ast {
            #expect(obj.members.isEmpty)
            #expect(obj.hasTrailingComma == false)
        } else {
            Issue.record("Expected object")
        }
    }

    @Test("Empty array")
    func emptyArray() throws {
        let source = "[]"
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .array(let arr) = ast {
            #expect(arr.elements.isEmpty)
            #expect(arr.hasTrailingComma == false)
        } else {
            Issue.record("Expected array")
        }
    }

    @Test("Simple object")
    func simpleObject() throws {
        let source = #"{"key": "value"}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .object(let obj) = ast {
            #expect(obj.members.count == 1)
            #expect(obj.members[0].key.value == "key")

            if case .string(let str) = obj.members[0].value {
                #expect(str.value == "value")
            } else {
                Issue.record("Expected string value")
            }
        } else {
            Issue.record("Expected object")
        }
    }

    @Test("Nested object")
    func nestedObject() throws {
        let source = #"{"outer": {"inner": 42}}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .object(let obj) = ast {
            #expect(obj.members.count == 1)
            if case .object(let inner) = obj.members[0].value {
                #expect(inner.members.count == 1)
                if case .number(let num) = inner.members[0].value {
                    #expect(num.value == 42)
                } else {
                    Issue.record("Expected number")
                }
            } else {
                Issue.record("Expected nested object")
            }
        } else {
            Issue.record("Expected object")
        }
    }

    @Test("Array with elements")
    func arrayWithElements() throws {
        let source = "[1, 2, 3]"
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .array(let arr) = ast {
            #expect(arr.elements.count == 3)

            for (index, element) in arr.elements.enumerated() {
                if case .number(let num) = element.value {
                    #expect(num.value == Double(index + 1))
                } else {
                    Issue.record("Expected number at index \(index)")
                }
            }
        } else {
            Issue.record("Expected array")
        }
    }

    @Test("Object with multiple members")
    func objectWithMultipleMembers() throws {
        let source = #"{"a": 1, "b": 2, "c": 3}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .object(let obj) = ast {
            #expect(obj.members.count == 3)
            #expect(obj.members[0].key.value == "a")
            #expect(obj.members[1].key.value == "b")
            #expect(obj.members[2].key.value == "c")
        } else {
            Issue.record("Expected object")
        }
    }

    @Test("Trailing comma in JSON5")
    func trailingCommaInJSON5() throws {
        let source = "[1, 2, 3,]"
        let lexer = Lexer(source: source, dialect: .json5)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .array(let arr) = ast {
            #expect(arr.elements.count == 3)
            #expect(arr.hasTrailingComma == true)
        } else {
            Issue.record("Expected array")
        }
    }

    @Test("Whitespace preservation")
    func whitespacePreservation() throws {
        let source = """
        {
          "key": "value"
        }
        """
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .object(let obj) = ast {
            #expect(obj.members.count == 1)
        } else {
            Issue.record("Expected object")
        }
    }

    @Test("All value types")
    func allValueTypes() throws {
        let source = #"{"str": "text", "num": 42, "bool": true, "null": null, "arr": [], "obj": {}}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .object(let obj) = ast {
            #expect(obj.members.count == 6)

            if case .string = obj.members[0].value {
                // OK
            } else {
                Issue.record("Expected string")
            }

            if case .number = obj.members[1].value {
                // OK
            } else {
                Issue.record("Expected number")
            }

            if case .boolean = obj.members[2].value {
                // OK
            } else {
                Issue.record("Expected boolean")
            }

            if case .null = obj.members[3].value {
                // OK
            } else {
                Issue.record("Expected null")
            }

            if case .array = obj.members[4].value {
                // OK
            } else {
                Issue.record("Expected array")
            }

            if case .object = obj.members[5].value {
                // OK
            } else {
                Issue.record("Expected object")
            }
        } else {
            Issue.record("Expected object")
        }
    }

    @Test("Duplicate keys detected")
    func duplicateKeysDetected() throws {
        let source = #"{"key": 1, "key": 2}"#
        let lexer = Lexer(source: source, dialect: .json)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)

        #expect(throws: ParserError.self) {
            try parser.parse()
        }
    }

    @Test("JSON5 unquoted keys")
    func json5UnquotedKeys() throws {
        let source = "{key: 'value'}"
        let lexer = Lexer(source: source, dialect: .json5)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .object(let obj) = ast {
            #expect(obj.members.count == 1)
            #expect(obj.members[0].key.value == "key")
        } else {
            Issue.record("Expected object")
        }
    }

    @Test("JSON5 with comments")
    func json5WithComments() throws {
        let source = """
        {
          // Comment
          "key": "value"
        }
        """
        let lexer = Lexer(source: source, dialect: .json5)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        if case .object(let obj) = ast {
            #expect(obj.members.count == 1)

            let hasComment = obj.members[0].key.token.location.line > 1
            #expect(hasComment)
        } else {
            Issue.record("Expected object")
        }
    }
}
