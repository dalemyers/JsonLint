import JsonLexer

public final class RuleRegistry: Sendable {
    private let rules: [String: any Rule]

    public init(rules: [any Rule]) {
        self.rules = Dictionary(uniqueKeysWithValues: rules.map { ($0.identifier, $0) })
    }

    public func rule(for identifier: String) -> (any Rule)? {
        rules[identifier]
    }

    public func allRules() -> [any Rule] {
        Array(rules.values)
    }

    public func rules(for identifiers: [String]) -> [any Rule] {
        identifiers.compactMap { rule(for: $0) }
    }

    public static let standard = RuleRegistry(rules: StandardRules.all)
}

public struct StandardRules {
    public static let all: [any Rule] = [
        DuplicateKeyRule(),
        MaxDepthRule(),
        TrailingCommaRule(),
        QuoteStyleRule(),
        CommentsRule(),
        BlankLinesRule(),
    ]

    public static let byCategory: [RuleCategory: [any Rule]] = {
        var result: [RuleCategory: [any Rule]] = [:]
        for rule in all {
            result[rule.category, default: []].append(rule)
        }
        return result
    }()
}
