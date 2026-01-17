import Foundation
import JsonLexer
import JsonRules
import TOMLKit

public struct Configuration: Codable, Sendable {
    public let general: GeneralConfig
    public let formatting: FormattingConfig
    public let rules: [String: RuleConfig]?
    public let output: OutputConfig

    public init(
        general: GeneralConfig = GeneralConfig(),
        formatting: FormattingConfig = FormattingConfig(),
        rules: [String: RuleConfig]? = nil,
        output: OutputConfig = OutputConfig()
    ) {
        self.general = general
        self.formatting = formatting
        self.rules = rules
        self.output = output
    }

    public struct GeneralConfig: Codable, Sendable {
        public let dialect: String

        public init(dialect: String = "json") {
            self.dialect = dialect
        }

        public var dialectEnum: Dialect {
            Dialect(rawValue: dialect) ?? .json
        }
    }

    public struct FormattingConfig: Codable, Sendable {
        public let indentStyle: String
        public let indentSize: Int
        public let lineWidth: Int?
        public let quoteStyle: String

        public init(
            indentStyle: String = "spaces",
            indentSize: Int = 2,
            lineWidth: Int? = 100,
            quoteStyle: String = "double"
        ) {
            self.indentStyle = indentStyle
            self.indentSize = indentSize
            self.lineWidth = lineWidth
            self.quoteStyle = quoteStyle
        }

        public var indentStyleEnum: RuleConfiguration.IndentStyle {
            RuleConfiguration.IndentStyle(rawValue: indentStyle) ?? .spaces
        }

        public var quoteStyleEnum: QuoteStyle {
            switch quoteStyle.lowercased() {
            case "single": return .single
            default: return .double
            }
        }
    }

    public struct RuleConfig: Codable, Sendable {
        public let enabled: Bool?
        public let severity: String?
        public let options: [String: TOMLValueWrapper]?

        public init(enabled: Bool? = nil, severity: String? = nil, options: [String: TOMLValueWrapper]? = nil) {
            self.enabled = enabled
            self.severity = severity
            self.options = options
        }

        public var severityEnum: Severity? {
            guard let severity = severity else { return nil }
            return Severity(rawValue: severity)
        }
    }

    public struct OutputConfig: Codable, Sendable {
        public let format: String

        public init(format: String = "text") {
            self.format = format
        }
    }

    public static let `default` = Configuration()

    public func toRuleConfiguration() -> RuleConfiguration {
        var enabledRules: Set<String> = []
        var disabledRules: Set<String> = []
        var severityOverrides: [String: Severity] = [:]
        var ruleOptions: [String: RuleOptions] = [:]

        if let rules = rules {
            for (ruleId, ruleConfig) in rules {
                if let enabled = ruleConfig.enabled {
                    if enabled {
                        enabledRules.insert(ruleId)
                    } else {
                        disabledRules.insert(ruleId)
                    }
                }

                if let severity = ruleConfig.severityEnum {
                    severityOverrides[ruleId] = severity
                }

                if let options = ruleConfig.options {
                    let configValues = options.mapValues { $0.toConfigValue() }
                    ruleOptions[ruleId] = RuleOptions(values: configValues)
                }
            }
        }

        return RuleConfiguration(
            dialect: general.dialectEnum,
            enabledRules: enabledRules,
            disabledRules: disabledRules,
            severityOverrides: severityOverrides,
            ruleOptions: ruleOptions,
            indentStyle: formatting.indentStyleEnum,
            indentSize: formatting.indentSize,
            lineWidth: formatting.lineWidth,
            quoteStyle: formatting.quoteStyleEnum
        )
    }
}

public struct TOMLValueWrapper: Codable, Sendable {
    let value: TOMLValueConvertible

    enum CodingKeys: String, CodingKey {
        case value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            value = ""
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        }
    }

    func toConfigValue() -> ConfigValue {
        if let string = value as? String {
            return .string(string)
        } else if let int = value as? Int {
            return .int(int)
        } else if let bool = value as? Bool {
            return .bool(bool)
        } else {
            return .string("")
        }
    }
}

protocol TOMLValueConvertible: Sendable {}
extension String: TOMLValueConvertible {}
extension Int: TOMLValueConvertible {}
extension Bool: TOMLValueConvertible {}
