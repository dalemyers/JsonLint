public enum Dialect: String, Sendable, CaseIterable, Codable {
    case json
    case json5
    case jsonc

    public var allowsSingleQuotes: Bool {
        switch self {
        case .json:
            return false
        case .json5, .jsonc:
            return true
        }
    }

    public var allowsComments: Bool {
        switch self {
        case .json:
            return false
        case .json5, .jsonc:
            return true
        }
    }

    public var allowsTrailingCommas: Bool {
        switch self {
        case .json, .jsonc:
            return false
        case .json5:
            return true
        }
    }

    public var allowsUnquotedKeys: Bool {
        self == .json5
    }

    public var allowsHexNumbers: Bool {
        self == .json5
    }

    public var allowsInfinityAndNaN: Bool {
        self == .json5
    }

    public var allowsLeadingDecimalPoint: Bool {
        self == .json5
    }

    public var allowsTrailingDecimalPoint: Bool {
        self == .json5
    }

    public var allowsPlusSign: Bool {
        self == .json5
    }
}
