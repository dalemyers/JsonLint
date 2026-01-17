import JsonLexer

public struct ParserError: Error, Sendable, CustomStringConvertible {
    public let type: ErrorType
    public let location: SourceRange
    public let token: Token?

    public init(type: ErrorType, location: SourceRange, token: Token? = nil) {
        self.type = type
        self.location = location
        self.token = token
    }

    public var description: String {
        let position = "\(location.start.line):\(location.start.column)"
        if let token = token {
            return "\(position): \(type.description) (found '\(token.lexeme)')"
        }
        return "\(position): \(type.description)"
    }

    public enum ErrorType: Equatable, Sendable, CustomStringConvertible {
        case unexpectedToken(expected: String, got: TokenType)
        case duplicateKey(String)
        case unexpectedEndOfFile
        case invalidValue
        case expectedColon
        case expectedCommaOrClosingBrace
        case expectedCommaOrClosingBracket

        public var description: String {
            switch self {
            case .unexpectedToken(let expected, let got):
                return "Expected \(expected), but got \(got)"
            case .duplicateKey(let key):
                return "Duplicate key '\(key)'"
            case .unexpectedEndOfFile:
                return "Unexpected end of file"
            case .invalidValue:
                return "Invalid value"
            case .expectedColon:
                return "Expected ':' after object key"
            case .expectedCommaOrClosingBrace:
                return "Expected ',' or '}' in object"
            case .expectedCommaOrClosingBracket:
                return "Expected ',' or ']' in array"
            }
        }
    }
}
