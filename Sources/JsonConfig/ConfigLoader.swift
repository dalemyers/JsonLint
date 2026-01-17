import Foundation
import TOMLKit

public final class ConfigLoader: Sendable {
    public enum Error: Swift.Error, CustomStringConvertible {
        case fileNotFound(String)
        case invalidTOML(String)
        case invalidStructure(String)

        public var description: String {
            switch self {
            case .fileNotFound(let path):
                return "Config file not found: \(path)"
            case .invalidTOML(let message):
                return "Invalid TOML: \(message)"
            case .invalidStructure(let message):
                return "Invalid config structure: \(message)"
            }
        }
    }

    public init() {}

    public func load(from path: String) throws -> Configuration {
        guard FileManager.default.fileExists(atPath: path) else {
            throw Error.fileNotFound(path)
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        guard let tomlString = String(data: data, encoding: .utf8) else {
            throw Error.invalidTOML("Could not read file as UTF-8")
        }

        do {
            let table = try TOMLTable(string: tomlString)
            return try decodeConfiguration(from: table)
        } catch let error as TOMLParseError {
            throw Error.invalidTOML(error.localizedDescription)
        } catch {
            throw Error.invalidStructure(error.localizedDescription)
        }
    }

    public func discover(startingFrom directory: String) -> Configuration? {
        var current = directory

        while current != "/" {
            let configPath = "\(current)/.jsonlint.toml"
            if FileManager.default.fileExists(atPath: configPath) {
                return try? load(from: configPath)
            }

            current = (current as NSString).deletingLastPathComponent
        }

        return nil
    }

    private func decodeConfiguration(from table: TOMLTable) throws -> Configuration {
        // Use .table property to extract TOMLTable from TOMLValueConvertible
        let general = try decodeGeneral(from: table["general"]?.table)
        let formatting = try decodeFormatting(from: table["formatting"]?.table)
        let output = try decodeOutput(from: table["output"]?.table)
        let rules = try decodeRules(from: table["rules"]?.table)

        return Configuration(
            general: general,
            formatting: formatting,
            rules: rules,
            output: output
        )
    }

    private func decodeGeneral(from table: TOMLTable?) throws -> Configuration.GeneralConfig {
        guard let table = table else {
            return Configuration.GeneralConfig()
        }

        let dialect = table["dialect"]?.string ?? "json"
        return Configuration.GeneralConfig(dialect: dialect)
    }

    private func decodeFormatting(from table: TOMLTable?) throws -> Configuration.FormattingConfig {
        guard let table = table else {
            return Configuration.FormattingConfig()
        }

        let indentStyle = table["indent_style"]?.string ?? "spaces"
        let indentSize = table["indent_size"]?.int ?? 2
        let lineWidth = table["line_width"]?.int
        let quoteStyle = table["quote_style"]?.string ?? "double"

        return Configuration.FormattingConfig(
            indentStyle: indentStyle,
            indentSize: indentSize,
            lineWidth: lineWidth,
            quoteStyle: quoteStyle
        )
    }

    private func decodeOutput(from table: TOMLTable?) throws -> Configuration.OutputConfig {
        guard let table = table else {
            return Configuration.OutputConfig()
        }

        let format = table["format"]?.string ?? "text"
        return Configuration.OutputConfig(format: format)
    }

    private func decodeRules(from table: TOMLTable?) throws -> [String: Configuration.RuleConfig]? {
        guard let table = table else {
            return nil
        }

        var rules: [String: Configuration.RuleConfig] = [:]

        for (key, value) in table {
            if let ruleTable = value.table {
                let enabled = ruleTable["enabled"]?.bool
                let severity = ruleTable["severity"]?.string

                rules[key] = Configuration.RuleConfig(
                    enabled: enabled,
                    severity: severity,
                    options: nil
                )
            }
        }

        return rules.isEmpty ? nil : rules
    }

    public static func merge(_ configs: Configuration...) -> Configuration {
        var result = configs.first ?? Configuration.default

        for config in configs.dropFirst() {
            result = Configuration(
                general: config.general,
                formatting: config.formatting,
                rules: config.rules ?? result.rules,
                output: config.output
            )
        }

        return result
    }
}
