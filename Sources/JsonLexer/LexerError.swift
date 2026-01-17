public struct LexerError: Error, Sendable, CustomStringConvertible {
    public let type: ErrorType
    public let location: SourceLocation
    public let context: String

    public init(type: ErrorType, location: SourceLocation, context: String) {
        self.type = type
        self.location = location
        self.context = context
    }

    public var description: String {
        "\(location.line):\(location.column): \(type.description) - \(context)"
    }

    public enum ErrorType: Equatable, Sendable, CustomStringConvertible {
        case unterminatedString
        case invalidEscapeSequence(String)
        case invalidNumber(String)
        case invalidCharacter(Character)
        case unexpectedEndOfFile
        case invalidUnicodeEscape
        case singleQuotesNotAllowed
        case commentsNotAllowed
        case unquotedKeysNotAllowed

        public var description: String {
            switch self {
            case .unterminatedString:
                return "Unterminated string"
            case .invalidEscapeSequence(let seq):
                return "Invalid escape sequence: \(seq)"
            case .invalidNumber(let num):
                return "Invalid number: \(num)"
            case .invalidCharacter(let char):
                return "Invalid character: \(char)"
            case .unexpectedEndOfFile:
                return "Unexpected end of file"
            case .invalidUnicodeEscape:
                return "Invalid unicode escape sequence"
            case .singleQuotesNotAllowed:
                return "Single quotes not allowed in this dialect"
            case .commentsNotAllowed:
                return "Comments not allowed in this dialect"
            case .unquotedKeysNotAllowed:
                return "Unquoted keys not allowed in this dialect"
            }
        }
    }
}
