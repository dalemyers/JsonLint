import Foundation
import JsonParser
import JsonLexer

public protocol Rule: Sendable {
    var identifier: String { get }
    var category: RuleCategory { get }
    var description: String { get }
    var defaultSeverity: Severity { get }

    func validate(_ node: any ASTNode, context: ValidationContext) -> [Violation]

    func fix(_ violation: Violation, context: FixContext) -> Fix?
}

public enum RuleCategory: String, Sendable, Codable {
    case formatting
    case style
    case structural
    case dialect
}

public enum Severity: String, Sendable, Comparable, Codable {
    case error
    case warning
    case info

    public static func < (lhs: Severity, rhs: Severity) -> Bool {
        let order: [Severity] = [.info, .warning, .error]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

public struct Violation: Sendable, Identifiable {
    public let id: UUID
    public let rule: String
    public let severity: Severity
    public let message: String
    public let location: SourceRange
    public let suggestion: String?

    public init(
        id: UUID = UUID(),
        rule: String,
        severity: Severity,
        message: String,
        location: SourceRange,
        suggestion: String? = nil
    ) {
        self.id = id
        self.rule = rule
        self.severity = severity
        self.message = message
        self.location = location
        self.suggestion = suggestion
    }
}

public struct ValidationContext: Sendable {
    public let ast: JSONValue
    public let config: RuleConfiguration
    public let sourceText: String

    public init(ast: JSONValue, config: RuleConfiguration, sourceText: String) {
        self.ast = ast
        self.config = config
        self.sourceText = sourceText
    }
}

public struct FixContext: Sendable {
    public let ast: JSONValue
    public let config: RuleConfiguration
    public let sourceText: String

    public init(ast: JSONValue, config: RuleConfiguration, sourceText: String) {
        self.ast = ast
        self.config = config
        self.sourceText = sourceText
    }
}

public struct Fix: Sendable {
    public let range: SourceRange
    public let replacement: String

    public init(range: SourceRange, replacement: String) {
        self.range = range
        self.replacement = replacement
    }
}

public struct RuleConfiguration: Sendable {
    public let dialect: Dialect
    public let enabledRules: Set<String>
    public let disabledRules: Set<String>
    public let severityOverrides: [String: Severity]
    public let ruleOptions: [String: RuleOptions]

    public let indentStyle: IndentStyle
    public let indentSize: Int
    public let lineWidth: Int?
    public let quoteStyle: QuoteStyle

    public enum IndentStyle: String, Sendable, Codable {
        case spaces
        case tabs
    }

    public init(
        dialect: Dialect = .json,
        enabledRules: Set<String> = [],
        disabledRules: Set<String> = [],
        severityOverrides: [String: Severity] = [:],
        ruleOptions: [String: RuleOptions] = [:],
        indentStyle: IndentStyle = .spaces,
        indentSize: Int = 2,
        lineWidth: Int? = 100,
        quoteStyle: QuoteStyle = .double
    ) {
        self.dialect = dialect
        self.enabledRules = enabledRules
        self.disabledRules = disabledRules
        self.severityOverrides = severityOverrides
        self.ruleOptions = ruleOptions
        self.indentStyle = indentStyle
        self.indentSize = indentSize
        self.lineWidth = lineWidth
        self.quoteStyle = quoteStyle
    }

    public func isEnabled(_ ruleIdentifier: String) -> Bool {
        if disabledRules.contains(ruleIdentifier) { return false }
        if enabledRules.isEmpty { return true }
        return enabledRules.contains(ruleIdentifier)
    }

    public func severity(for ruleIdentifier: String, default defaultSeverity: Severity) -> Severity {
        severityOverrides[ruleIdentifier] ?? defaultSeverity
    }
}

public struct RuleOptions: Sendable {
    private let values: [String: ConfigValue]

    public init(values: [String: ConfigValue] = [:]) {
        self.values = values
    }

    public subscript(key: String) -> ConfigValue? {
        values[key]
    }
}

public enum ConfigValue: Sendable, Codable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case array([ConfigValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let array = try? container.decode([ConfigValue].self) {
            self = .array(array)
        } else {
            throw DecodingError.typeMismatch(
                ConfigValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Could not decode ConfigValue"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }
}
