import JsonLexer

public final class RulePackage: Sendable {
    public let name: String
    public let rules: [String]
    public let basePackage: RulePackage?

    public init(name: String, rules: [String], basePackage: RulePackage? = nil) {
        self.name = name
        self.rules = rules
        self.basePackage = basePackage
    }

    public func allRules() -> [String] {
        var result = basePackage?.allRules() ?? []
        result.append(contentsOf: rules)
        return result
    }

    public static let json = RulePackage(
        name: "JSON",
        rules: [
            "structural.duplicate-keys",
            "structural.max-depth",
            "style.quote-style",
            "style.trailing-comma",
            "style.no-blank-lines",
            "dialect.no-comments",
        ]
    )

    public static let json5 = RulePackage(
        name: "JSON5",
        rules: [
            "structural.duplicate-keys",
            "structural.max-depth",
            "style.no-blank-lines",
        ]
    )

    public static let jsonc = RulePackage(
        name: "JSONC",
        rules: [
            "structural.duplicate-keys",
            "structural.max-depth",
            "style.quote-style",
            "style.trailing-comma",
            "style.no-blank-lines",
        ]
    )

    public static func `for`(dialect: Dialect) -> RulePackage {
        switch dialect {
        case .json:
            return .json
        case .json5:
            return .json5
        case .jsonc:
            return .jsonc
        }
    }
}
