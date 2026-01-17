import JsonParser
import JsonRules
import JsonLexer

public final class Formatter: Sendable {
    private let config: RuleConfiguration

    public init(config: RuleConfiguration) {
        self.config = config
    }

    public func format(_ ast: JSONValue) -> String {
        var output = ""
        formatValue(ast, into: &output, depth: 0)
        return output
    }

    private func formatValue(_ value: JSONValue, into output: inout String, depth: Int) {
        switch value {
        case .object(let obj):
            formatObject(obj, into: &output, depth: depth)
        case .array(let arr):
            formatArray(arr, into: &output, depth: depth)
        case .string(let str):
            formatString(str, into: &output)
        case .number(let num):
            output.append(String(num.value))
        case .boolean(let bool):
            output.append(bool.value ? "true" : "false")
        case .null:
            output.append("null")
        }
    }

    private func formatObject(_ obj: JSONObject, into output: inout String, depth: Int) {
        output.append("{")

        if !obj.members.isEmpty {
            output.append("\n")

            for (index, member) in obj.members.enumerated() {
                output.append(indent(depth + 1))

                formatKey(member.key, into: &output)
                output.append(": ")
                formatValue(member.value, into: &output, depth: depth + 1)

                if index < obj.members.count - 1 {
                    output.append(",")
                }
                output.append("\n")
            }

            output.append(indent(depth))
        }

        output.append("}")
    }

    private func formatArray(_ arr: JSONArray, into output: inout String, depth: Int) {
        output.append("[")

        if !arr.elements.isEmpty {
            output.append("\n")

            for (index, element) in arr.elements.enumerated() {
                output.append(indent(depth + 1))
                formatValue(element.value, into: &output, depth: depth + 1)

                if index < arr.elements.count - 1 {
                    output.append(",")
                }
                output.append("\n")
            }

            output.append(indent(depth))
        }

        output.append("]")
    }

    private func formatKey(_ key: JSONKey, into output: inout String) {
        if case .identifier = key.token.type, config.dialect.allowsUnquotedKeys {
            output.append(key.value)
        } else {
            let quote = config.quoteStyle == .double ? "\"" : "'"
            output.append("\(quote)\(key.value)\(quote)")
        }
    }

    private func formatString(_ str: JSONString, into output: inout String) {
        let quote = config.quoteStyle == .double ? "\"" : "'"
        let escaped = escapeString(str.value)
        output.append("\(quote)\(escaped)\(quote)")
    }

    private func escapeString(_ str: String) -> String {
        var result = ""
        for char in str {
            switch char {
            case "\"":
                result.append("\\\"")
            case "'":
                result.append("\\'")
            case "\\":
                result.append("\\\\")
            case "\n":
                result.append("\\n")
            case "\r":
                result.append("\\r")
            case "\t":
                result.append("\\t")
            default:
                result.append(char)
            }
        }
        return result
    }

    private func indent(_ depth: Int) -> String {
        let unit = config.indentStyle == .spaces
            ? String(repeating: " ", count: config.indentSize)
            : "\t"
        return String(repeating: unit, count: depth)
    }
}
