public struct Token: Equatable, Sendable {
    public let type: TokenType
    public let lexeme: String
    public let location: SourceLocation
    public let value: TokenValue?

    public init(type: TokenType, lexeme: String, location: SourceLocation, value: TokenValue? = nil) {
        self.type = type
        self.lexeme = lexeme
        self.location = location
        self.value = value
    }
}

public enum TokenType: Equatable, Sendable {
    // Structural
    case leftBrace
    case rightBrace
    case leftBracket
    case rightBracket
    case comma
    case colon

    // Literals
    case string(quote: QuoteStyle)
    case number
    case boolean
    case null

    // JSON5/JSONC extensions
    case singleLineComment
    case multiLineComment
    case identifier

    // Special
    case whitespace
    case newline
    case eof
    case invalid(reason: String)
}

public enum QuoteStyle: Equatable, Sendable {
    case double
    case single
}

public enum TokenValue: Equatable, Sendable {
    case string(String)
    case number(Double)
    case boolean(Bool)
    case comment(String)
    case identifier(String)
}

public struct SourceLocation: Equatable, Sendable, Comparable {
    public let line: Int
    public let column: Int
    public let offset: Int
    public let length: Int

    public init(line: Int, column: Int, offset: Int, length: Int) {
        self.line = line
        self.column = column
        self.offset = offset
        self.length = length
    }

    public static func < (lhs: SourceLocation, rhs: SourceLocation) -> Bool {
        if lhs.line != rhs.line {
            return lhs.line < rhs.line
        }
        return lhs.column < rhs.column
    }
}

public struct SourceRange: Equatable, Sendable {
    public let start: SourceLocation
    public let end: SourceLocation

    public init(start: SourceLocation, end: SourceLocation) {
        self.start = start
        self.end = end
    }

    public init(location: SourceLocation) {
        self.start = location
        self.end = SourceLocation(
            line: location.line,
            column: location.column + location.length,
            offset: location.offset + location.length,
            length: 0
        )
    }
}
