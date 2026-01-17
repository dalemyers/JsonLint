import Testing
@testable import JsonLintCore

@Suite("JsonLintCore Public API Tests")
struct JsonLintCoreTests {
    @Test("JsonLintCore initialization")
    func initialization() {
        let _ = JsonLintCore()
    }

    @Test("Lint valid JSON")
    func lintValidJSON() throws {
        let source = #"{"name": "test", "value": 123}"#
        let result = try JsonLintCore.lint(source: source, dialect: .json)

        #expect(result.isValid)
        #expect(result.violations.isEmpty)
        #expect(result.errorCount == 0)
        #expect(result.warningCount == 0)
    }

    @Test("Lint JSON with duplicates")
    func lintJSONWithDuplicates() throws {
        let source = #"{"key": 1, "key": 2}"#

        // This should fail at parse time due to duplicate keys
        #expect(throws: ParserError.self) {
            try JsonLintCore.lint(source: source, dialect: .json)
        }
    }

    @Test("Format JSON")
    func formatJSON() throws {
        let source = #"{"name":"test","value":123}"#
        let formatted = try JsonLintCore.format(source: source, dialect: .json)

        #expect(formatted.contains("{\n"))
        #expect(formatted.contains("  \"name\""))
        #expect(formatted.contains("  \"value\""))
    }

    @Test("Fix JSON")
    func fixJSON() throws {
        let source = #"{"name":"test"}"#
        let result = try JsonLintCore.fix(source: source, dialect: .json)

        #expect(result.fixedSource.contains("{\n"))
        #expect(result.isFullyFixed)
    }

    @Test("Parse JSON")
    func parseJSON() throws {
        let source = #"{"name": "test"}"#
        let ast = try JsonLintCore.parse(source: source, dialect: .json)

        if case .object(let obj) = ast {
            #expect(obj.members.count == 1)
            #expect(obj.members[0].key.value == "name")
        } else {
            Issue.record("Expected object")
        }
    }

    @Test("Lint JSON5 with comments")
    func lintJSON5WithComments() throws {
        let source = """
        {
          // This is a comment
          "key": "value"
        }
        """

        let result = try JsonLintCore.lint(source: source, dialect: .json5)
        #expect(result.isValid)
    }

    @Test("Lint JSONC")
    func lintJSONC() throws {
        let source = """
        {
          /* Comment */
          "key": "value"
        }
        """

        let result = try JsonLintCore.lint(source: source, dialect: .jsonc)
        #expect(result.isValid)
    }

    @Test("Format preserves values")
    func formatPreservesValues() throws {
        let source = #"{"string":"hello","number":42,"boolean":true,"null":null}"#
        let formatted = try JsonLintCore.format(source: source, dialect: .json)

        #expect(formatted.contains("\"hello\""))
        #expect(formatted.contains("42"))
        #expect(formatted.contains("true"))
        #expect(formatted.contains("null"))
    }

    @Test("Lint with custom config")
    func lintWithCustomConfig() throws {
        let source = #"{"name": "test"}"#
        let config = Configuration(
            formatting: Configuration.FormattingConfig(
                indentStyle: "tabs",
                indentSize: 1
            )
        )

        let result = try JsonLintCore.lint(source: source, dialect: .json, config: config)
        #expect(result.isValid)
    }

    @Test("Parse arrays")
    func parseArrays() throws {
        let source = "[1, 2, 3]"
        let ast = try JsonLintCore.parse(source: source, dialect: .json)

        if case .array(let arr) = ast {
            #expect(arr.elements.count == 3)
        } else {
            Issue.record("Expected array")
        }
    }

    @Test("Parse nested structures")
    func parseNestedStructures() throws {
        let source = #"{"outer": {"inner": [1, 2]}}"#
        let ast = try JsonLintCore.parse(source: source, dialect: .json)

        if case .object(let obj) = ast {
            #expect(obj.members.count == 1)

            if case .object(let inner) = obj.members[0].value {
                #expect(inner.members.count == 1)
            } else {
                Issue.record("Expected nested object")
            }
        } else {
            Issue.record("Expected object")
        }
    }

    @Test("Format empty structures")
    func formatEmptyStructures() throws {
        let emptyObject = try JsonLintCore.format(source: "{}", dialect: .json)
        #expect(emptyObject == "{}")

        let emptyArray = try JsonLintCore.format(source: "[]", dialect: .json)
        #expect(emptyArray == "[]")
    }
}
