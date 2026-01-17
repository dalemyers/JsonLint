import Testing
import Foundation
@testable import JsonConfig
@testable import JsonLexer
@testable import JsonRules

@Suite("Config Tests")
struct ConfigTests {
    @Test("Configuration default values")
    func configurationDefaultValues() {
        let config = Configuration()
        #expect(config.general.dialect == "json")
        #expect(config.formatting.indentStyle == "spaces")
        #expect(config.formatting.indentSize == 2)
        #expect(config.formatting.quoteStyle == "double")
        #expect(config.output.format == "text")
    }

    @Test("Configuration static default")
    func configurationStaticDefault() {
        let config = Configuration.default
        #expect(config.general.dialect == "json")
    }

    @Test("GeneralConfig dialectEnum conversion")
    func generalConfigDialectEnum() {
        let json = Configuration.GeneralConfig(dialect: "json")
        #expect(json.dialectEnum == .json)

        let json5 = Configuration.GeneralConfig(dialect: "json5")
        #expect(json5.dialectEnum == .json5)

        let jsonc = Configuration.GeneralConfig(dialect: "jsonc")
        #expect(jsonc.dialectEnum == .jsonc)

        let invalid = Configuration.GeneralConfig(dialect: "invalid")
        #expect(invalid.dialectEnum == .json)
    }

    @Test("FormattingConfig indentStyleEnum conversion")
    func formattingConfigIndentStyleEnum() {
        let spaces = Configuration.FormattingConfig(indentStyle: "spaces")
        #expect(spaces.indentStyleEnum == .spaces)

        let tabs = Configuration.FormattingConfig(indentStyle: "tabs")
        #expect(tabs.indentStyleEnum == .tabs)

        let invalid = Configuration.FormattingConfig(indentStyle: "invalid")
        #expect(invalid.indentStyleEnum == .spaces)
    }

    @Test("FormattingConfig quoteStyleEnum conversion")
    func formattingConfigQuoteStyleEnum() {
        let double = Configuration.FormattingConfig(quoteStyle: "double")
        #expect(double.quoteStyleEnum == .double)

        let single = Configuration.FormattingConfig(quoteStyle: "single")
        #expect(single.quoteStyleEnum == .single)

        let singleUpper = Configuration.FormattingConfig(quoteStyle: "SINGLE")
        #expect(singleUpper.quoteStyleEnum == .single)

        let invalid = Configuration.FormattingConfig(quoteStyle: "invalid")
        #expect(invalid.quoteStyleEnum == .double)
    }

    @Test("RuleConfig severityEnum conversion")
    func ruleConfigSeverityEnum() {
        let error = Configuration.RuleConfig(severity: "error")
        #expect(error.severityEnum == .error)

        let warning = Configuration.RuleConfig(severity: "warning")
        #expect(warning.severityEnum == .warning)

        let info = Configuration.RuleConfig(severity: "info")
        #expect(info.severityEnum == .info)

        let noSeverity = Configuration.RuleConfig()
        #expect(noSeverity.severityEnum == nil)
    }

    @Test("Configuration toRuleConfiguration with no rules")
    func configurationToRuleConfigurationEmpty() {
        let config = Configuration()
        let ruleConfig = config.toRuleConfiguration()

        #expect(ruleConfig.dialect == .json)
        #expect(ruleConfig.indentStyle == .spaces)
        #expect(ruleConfig.indentSize == 2)
        #expect(ruleConfig.quoteStyle == .double)
    }

    @Test("Configuration toRuleConfiguration with enabled rules")
    func configurationToRuleConfigurationWithEnabledRules() {
        let rules = [
            "test.rule": Configuration.RuleConfig(enabled: true, severity: "error")
        ]
        let config = Configuration(rules: rules)
        let ruleConfig = config.toRuleConfiguration()

        #expect(ruleConfig.isEnabled("test.rule"))
        #expect(ruleConfig.severity(for: "test.rule", default: .warning) == .error)
    }

    @Test("Configuration toRuleConfiguration with disabled rules")
    func configurationToRuleConfigurationWithDisabledRules() {
        let rules = [
            "test.rule": Configuration.RuleConfig(enabled: false)
        ]
        let config = Configuration(rules: rules)
        let ruleConfig = config.toRuleConfiguration()

        #expect(!ruleConfig.isEnabled("test.rule"))
    }

    @Test("TOMLValueWrapper string encoding and decoding")
    func tomlValueWrapperString() throws {
        let json = "\"test\""
        let data = json.data(using: .utf8)!
        let wrapper = try JSONDecoder().decode(TOMLValueWrapper.self, from: data)

        if case .string(let value) = wrapper.toConfigValue() {
            #expect(value == "test")
        } else {
            Issue.record("Expected string ConfigValue")
        }

        let encoded = try JSONEncoder().encode(wrapper)
        let encodedString = String(data: encoded, encoding: .utf8)
        #expect(encodedString?.contains("test") == true)
    }

    @Test("TOMLValueWrapper int encoding and decoding")
    func tomlValueWrapperInt() throws {
        let json = "42"
        let data = json.data(using: .utf8)!
        let wrapper = try JSONDecoder().decode(TOMLValueWrapper.self, from: data)

        if case .int(let value) = wrapper.toConfigValue() {
            #expect(value == 42)
        } else {
            Issue.record("Expected int ConfigValue")
        }

        let encoded = try JSONEncoder().encode(wrapper)
        let encodedString = String(data: encoded, encoding: .utf8)
        #expect(encodedString == "42")
    }

    @Test("TOMLValueWrapper bool encoding and decoding")
    func tomlValueWrapperBool() throws {
        let json = "true"
        let data = json.data(using: .utf8)!
        let wrapper = try JSONDecoder().decode(TOMLValueWrapper.self, from: data)

        if case .bool(let value) = wrapper.toConfigValue() {
            #expect(value == true)
        } else {
            Issue.record("Expected bool ConfigValue")
        }

        let encoded = try JSONEncoder().encode(wrapper)
        let encodedString = String(data: encoded, encoding: .utf8)
        #expect(encodedString == "true")
    }

    @Test("TOMLValueWrapper fallback for invalid type")
    func tomlValueWrapperFallback() throws {
        let json = "[1, 2, 3]"
        let data = json.data(using: .utf8)!
        let wrapper = try JSONDecoder().decode(TOMLValueWrapper.self, from: data)

        // Should fallback to empty string for unsupported types
        if case .string(let value) = wrapper.toConfigValue() {
            #expect(value == "")
        } else {
            Issue.record("Expected empty string ConfigValue")
        }
    }

    @Test("ConfigLoader error descriptions")
    func configLoaderErrorDescriptions() {
        let fileNotFound = ConfigLoader.Error.fileNotFound("/path/to/file")
        #expect(fileNotFound.description.contains("/path/to/file"))

        let invalidTOML = ConfigLoader.Error.invalidTOML("syntax error")
        #expect(invalidTOML.description.contains("syntax error"))

        let invalidStructure = ConfigLoader.Error.invalidStructure("missing field")
        #expect(invalidStructure.description.contains("missing field"))
    }

    @Test("ConfigLoader load throws fileNotFound for missing file")
    func configLoaderFileNotFound() {
        let loader = ConfigLoader()
        #expect(throws: ConfigLoader.Error.self) {
            try loader.load(from: "/nonexistent/path/.jsonlint.toml")
        }
    }

    @Test("ConfigLoader merge with single config")
    func configLoaderMergeSingle() {
        let config = Configuration(
            general: Configuration.GeneralConfig(dialect: "json5")
        )
        let merged = ConfigLoader.merge(config)

        #expect(merged.general.dialect == "json5")
    }

    @Test("ConfigLoader merge with multiple configs")
    func configLoaderMergeMultiple() {
        let config1 = Configuration(
            general: Configuration.GeneralConfig(dialect: "json")
        )
        let config2 = Configuration(
            general: Configuration.GeneralConfig(dialect: "json5"),
            formatting: Configuration.FormattingConfig(indentSize: 4)
        )

        let merged = ConfigLoader.merge(config1, config2)

        #expect(merged.general.dialect == "json5")
        #expect(merged.formatting.indentSize == 4)
    }

    @Test("ConfigLoader merge preserves rules from earlier config")
    func configLoaderMergePreservesRules() {
        let rules1 = ["rule1": Configuration.RuleConfig(enabled: true)]
        let config1 = Configuration(rules: rules1)
        let config2 = Configuration()

        let merged = ConfigLoader.merge(config1, config2)

        #expect(merged.rules != nil)
        #expect(merged.rules?["rule1"]?.enabled == true)
    }

    @Test("ConfigLoader merge with empty list returns default")
    func configLoaderMergeEmpty() {
        let merged = ConfigLoader.merge()
        #expect(merged.general.dialect == "json")
    }

    @Test("Configuration toRuleConfiguration with rule options")
    func configurationToRuleConfigurationWithOptions() throws {
        // Create TOMLValueWrapper via JSON decoding
        let maxWrapper = try JSONDecoder().decode(TOMLValueWrapper.self, from: "10".data(using: .utf8)!)
        let options = ["max": maxWrapper]

        let rules = [
            "structural.max-depth": Configuration.RuleConfig(enabled: true, options: options)
        ]
        let config = Configuration(rules: rules)
        let ruleConfig = config.toRuleConfiguration()

        // Verify the options were converted to RuleOptions
        if let maxOption = ruleConfig.ruleOptions["structural.max-depth"]?["max"] {
            if case .int(let value) = maxOption {
                #expect(value == 10)
            } else {
                Issue.record("Expected int option")
            }
        } else {
            Issue.record("Expected max option to be present")
        }
    }

    @Test("TOMLValueWrapper toConfigValue fallback to empty string")
    func tomlValueWrapperEmptyStringFallback() throws {
        // Create a wrapper with an empty string as fallback
        let json = "[]"
        let data = json.data(using: .utf8)!
        let wrapper = try JSONDecoder().decode(TOMLValueWrapper.self, from: data)

        // The toConfigValue should return empty string for unsupported types
        let configValue = wrapper.toConfigValue()
        if case .string(let str) = configValue {
            #expect(str == "")
        } else {
            Issue.record("Expected empty string fallback")
        }
    }
}
