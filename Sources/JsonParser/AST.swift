import JsonLexer

public protocol ASTNode: Sendable {
    var location: SourceRange { get }
    var leadingTrivia: [Token] { get }
    var trailingTrivia: [Token] { get }
}

public indirect enum JSONValue: ASTNode, Sendable {
    case object(JSONObject)
    case array(JSONArray)
    case string(JSONString)
    case number(JSONNumber)
    case boolean(JSONBoolean)
    case null(JSONNull)

    public var location: SourceRange {
        switch self {
        case .object(let obj): return obj.location
        case .array(let arr): return arr.location
        case .string(let str): return str.location
        case .number(let num): return num.location
        case .boolean(let bool): return bool.location
        case .null(let null): return null.location
        }
    }

    public var leadingTrivia: [Token] {
        switch self {
        case .object(let obj): return obj.leadingTrivia
        case .array(let arr): return arr.leadingTrivia
        case .string(let str): return str.leadingTrivia
        case .number(let num): return num.leadingTrivia
        case .boolean(let bool): return bool.leadingTrivia
        case .null(let null): return null.leadingTrivia
        }
    }

    public var trailingTrivia: [Token] {
        switch self {
        case .object(let obj): return obj.trailingTrivia
        case .array(let arr): return arr.trailingTrivia
        case .string(let str): return str.trailingTrivia
        case .number(let num): return num.trailingTrivia
        case .boolean(let bool): return bool.trailingTrivia
        case .null(let null): return null.trailingTrivia
        }
    }
}

public struct JSONObject: ASTNode, Sendable {
    public let location: SourceRange
    public let leadingTrivia: [Token]
    public let trailingTrivia: [Token]
    public let members: [Member]
    public let hasTrailingComma: Bool

    public init(
        location: SourceRange,
        leadingTrivia: [Token],
        trailingTrivia: [Token],
        members: [Member],
        hasTrailingComma: Bool
    ) {
        self.location = location
        self.leadingTrivia = leadingTrivia
        self.trailingTrivia = trailingTrivia
        self.members = members
        self.hasTrailingComma = hasTrailingComma
    }

    public struct Member: Sendable {
        public let key: JSONKey
        public let colon: Token
        public let value: JSONValue
        public let comma: Token?

        public init(key: JSONKey, colon: Token, value: JSONValue, comma: Token?) {
            self.key = key
            self.colon = colon
            self.value = value
            self.comma = comma
        }
    }
}

public struct JSONArray: ASTNode, Sendable {
    public let location: SourceRange
    public let leadingTrivia: [Token]
    public let trailingTrivia: [Token]
    public let elements: [Element]
    public let hasTrailingComma: Bool

    public init(
        location: SourceRange,
        leadingTrivia: [Token],
        trailingTrivia: [Token],
        elements: [Element],
        hasTrailingComma: Bool
    ) {
        self.location = location
        self.leadingTrivia = leadingTrivia
        self.trailingTrivia = trailingTrivia
        self.elements = elements
        self.hasTrailingComma = hasTrailingComma
    }

    public struct Element: Sendable {
        public let value: JSONValue
        public let comma: Token?

        public init(value: JSONValue, comma: Token?) {
            self.value = value
            self.comma = comma
        }
    }
}

public struct JSONKey: Sendable {
    public let token: Token
    public let value: String
    public let location: SourceRange

    public init(token: Token, value: String, location: SourceRange) {
        self.token = token
        self.value = value
        self.location = location
    }
}

public struct JSONString: ASTNode, Sendable {
    public let location: SourceRange
    public let leadingTrivia: [Token]
    public let trailingTrivia: [Token]
    public let token: Token
    public let value: String

    public init(
        location: SourceRange,
        leadingTrivia: [Token],
        trailingTrivia: [Token],
        token: Token,
        value: String
    ) {
        self.location = location
        self.leadingTrivia = leadingTrivia
        self.trailingTrivia = trailingTrivia
        self.token = token
        self.value = value
    }
}

public struct JSONNumber: ASTNode, Sendable {
    public let location: SourceRange
    public let leadingTrivia: [Token]
    public let trailingTrivia: [Token]
    public let token: Token
    public let value: Double

    public init(
        location: SourceRange,
        leadingTrivia: [Token],
        trailingTrivia: [Token],
        token: Token,
        value: Double
    ) {
        self.location = location
        self.leadingTrivia = leadingTrivia
        self.trailingTrivia = trailingTrivia
        self.token = token
        self.value = value
    }
}

public struct JSONBoolean: ASTNode, Sendable {
    public let location: SourceRange
    public let leadingTrivia: [Token]
    public let trailingTrivia: [Token]
    public let token: Token
    public let value: Bool

    public init(
        location: SourceRange,
        leadingTrivia: [Token],
        trailingTrivia: [Token],
        token: Token,
        value: Bool
    ) {
        self.location = location
        self.leadingTrivia = leadingTrivia
        self.trailingTrivia = trailingTrivia
        self.token = token
        self.value = value
    }
}

public struct JSONNull: ASTNode, Sendable {
    public let location: SourceRange
    public let leadingTrivia: [Token]
    public let trailingTrivia: [Token]
    public let token: Token

    public init(
        location: SourceRange,
        leadingTrivia: [Token],
        trailingTrivia: [Token],
        token: Token
    ) {
        self.location = location
        self.leadingTrivia = leadingTrivia
        self.trailingTrivia = trailingTrivia
        self.token = token
    }
}

// MARK: - AST Walking

extension JSONValue {
    public func walk(_ visitor: (any ASTNode) -> Void) {
        visitor(self)

        switch self {
        case .object(let obj):
            visitor(obj)
            for member in obj.members {
                member.value.walk(visitor)
            }
        case .array(let arr):
            visitor(arr)
            for element in arr.elements {
                element.value.walk(visitor)
            }
        case .string(let str):
            visitor(str)
        case .number(let num):
            visitor(num)
        case .boolean(let bool):
            visitor(bool)
        case .null(let null):
            visitor(null)
        }
    }
}
