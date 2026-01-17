public final class Lexer {
    private let source: String
    private let dialect: Dialect
    private let sourceChars: [Character]
    private var current: Int = 0
    private var line: Int = 1
    private var column: Int = 1
    private var tokenStart: Int = 0
    private var tokenStartLine: Int = 1
    private var tokenStartColumn: Int = 1

    public init(source: String, dialect: Dialect = .json) {
        self.source = source
        self.dialect = dialect
        self.sourceChars = Array(source)
    }

    public func tokenize() throws -> [Token] {
        var tokens: [Token] = []

        while !isAtEnd() {
            tokenStart = current
            tokenStartLine = line
            tokenStartColumn = column

            let token = try scanToken()
            tokens.append(token)
        }

        tokenStart = current
        tokenStartLine = line
        tokenStartColumn = column
        tokens.append(makeToken(.eof, value: nil))
        return tokens
    }

    private func scanToken() throws -> Token {
        let char = advance()

        switch char {
        case "{":
            return makeToken(.leftBrace, value: nil)
        case "}":
            return makeToken(.rightBrace, value: nil)
        case "[":
            return makeToken(.leftBracket, value: nil)
        case "]":
            return makeToken(.rightBracket, value: nil)
        case ",":
            return makeToken(.comma, value: nil)
        case ":":
            return makeToken(.colon, value: nil)

        case "\n":
            return makeToken(.newline, value: nil)

        case " ", "\t", "\r":
            while !isAtEnd() && (peek() == " " || peek() == "\t" || peek() == "\r") {
                advance()
            }
            return makeToken(.whitespace, value: nil)

        case "/":
            if match("/") {
                return try scanSingleLineComment()
            } else if match("*") {
                return try scanMultiLineComment()
            } else {
                throw makeError(.invalidCharacter(char))
            }

        case "\"":
            return try scanString(quote: .double)

        case "'":
            if !dialect.allowsSingleQuotes {
                throw makeError(.singleQuotesNotAllowed)
            }
            return try scanString(quote: .single)

        case "-", "+", "0"..."9", ".":
            return try scanNumber(firstChar: char)

        case "t", "f":
            return try scanBoolean(firstChar: char)

        case "n":
            return try scanNull()

        case "I", "N":
            if dialect.allowsInfinityAndNaN {
                return try scanSpecialNumber(firstChar: char)
            }
            fallthrough

        default:
            if char.isLetter || char == "_" || char == "$" {
                return try scanIdentifier(firstChar: char)
            }
            throw makeError(.invalidCharacter(char))
        }
    }

    // MARK: - String Scanning

    private func scanString(quote: QuoteStyle) throws -> Token {
        let quoteChar: Character = quote == .double ? "\"" : "'"
        var value = ""

        while !isAtEnd() && peek() != quoteChar {
            if peek() == "\n" {
                throw makeError(.unterminatedString)
            }

            if peek() == "\\" {
                advance()
                if isAtEnd() {
                    throw makeError(.unterminatedString)
                }
                let escaped = try scanEscapeSequence()
                value.append(escaped)
            } else {
                value.append(advance())
            }
        }

        if isAtEnd() {
            throw makeError(.unterminatedString)
        }

        advance()

        return makeToken(.string(quote: quote), value: .string(value))
    }

    private func scanEscapeSequence() throws -> String {
        let char = advance()

        switch char {
        case "\"": return "\""
        case "'": return "'"
        case "\\": return "\\"
        case "/": return "/"
        case "b": return "\u{08}"
        case "f": return "\u{0C}"
        case "n": return "\n"
        case "r": return "\r"
        case "t": return "\t"
        case "u": return try scanUnicodeEscape()
        default:
            throw makeError(.invalidEscapeSequence("\\\(char)"))
        }
    }

    private func scanUnicodeEscape() throws -> String {
        var hexString = ""

        for _ in 0..<4 {
            if isAtEnd() {
                throw makeError(.invalidUnicodeEscape)
            }
            let char = advance()
            if !char.isHexDigit {
                throw makeError(.invalidUnicodeEscape)
            }
            hexString.append(char)
        }

        guard let codePoint = Int(hexString, radix: 16),
              let scalar = Unicode.Scalar(codePoint) else {
            throw makeError(.invalidUnicodeEscape)
        }

        return String(scalar)
    }

    // MARK: - Number Scanning

    private func scanNumber(firstChar: Character) throws -> Token {
        var numberString = String(firstChar)

        if firstChar == "+" {
            if !dialect.allowsPlusSign {
                throw makeError(.invalidCharacter(firstChar))
            }
        }

        if firstChar == "0" && !isAtEnd() && peek() == "x" {
            if !dialect.allowsHexNumbers {
                throw makeError(.invalidNumber("0x..."))
            }
            return try scanHexNumber()
        }

        if firstChar == "." {
            if !dialect.allowsLeadingDecimalPoint {
                throw makeError(.invalidNumber("."))
            }
            while !isAtEnd() && peek().isNumber {
                numberString.append(advance())
            }
        } else {
            while !isAtEnd() && peek().isNumber {
                numberString.append(advance())
            }

            if !isAtEnd() && peek() == "." {
                numberString.append(advance())
                while !isAtEnd() && peek().isNumber {
                    numberString.append(advance())
                }
            }
        }

        if !isAtEnd() && (peek() == "e" || peek() == "E") {
            numberString.append(advance())
            if !isAtEnd() && (peek() == "+" || peek() == "-") {
                numberString.append(advance())
            }
            while !isAtEnd() && peek().isNumber {
                numberString.append(advance())
            }
        }

        if !isAtEnd() && peek() == "." && dialect.allowsTrailingDecimalPoint {
            numberString.append(advance())
        }

        guard let number = Double(numberString) else {
            throw makeError(.invalidNumber(numberString))
        }

        return makeToken(.number, value: .number(number))
    }

    private func scanHexNumber() throws -> Token {
        advance()
        var hexString = ""

        while !isAtEnd() && peek().isHexDigit {
            hexString.append(advance())
        }

        guard !hexString.isEmpty,
              let value = Int(hexString, radix: 16) else {
            throw makeError(.invalidNumber("0x\(hexString)"))
        }

        return makeToken(.number, value: .number(Double(value)))
    }

    // MARK: - Boolean and Null Scanning

    private func scanBoolean(firstChar: Character) throws -> Token {
        if firstChar == "t" {
            if match("r") && match("u") && match("e") {
                return makeToken(.boolean, value: .boolean(true))
            }
        } else if firstChar == "f" {
            if match("a") && match("l") && match("s") && match("e") {
                return makeToken(.boolean, value: .boolean(false))
            }
        }

        throw makeError(.invalidCharacter(firstChar))
    }

    private func scanNull() throws -> Token {
        if match("u") && match("l") && match("l") {
            return makeToken(.null, value: nil)
        }
        throw makeError(.invalidCharacter("n"))
    }

    private func scanSpecialNumber(firstChar: Character) throws -> Token {
        if firstChar == "I" {
            if match("n") && match("f") && match("i") && match("n") && match("i") && match("t") && match("y") {
                return makeToken(.number, value: .number(.infinity))
            }
        } else if firstChar == "N" {
            if match("a") && match("N") {
                return makeToken(.number, value: .number(.nan))
            }
        }

        throw makeError(.invalidCharacter(firstChar))
    }

    // MARK: - Comment Scanning

    private func scanSingleLineComment() throws -> Token {
        if !dialect.allowsComments {
            throw makeError(.commentsNotAllowed)
        }

        var comment = ""

        while !isAtEnd() && peek() != "\n" {
            comment.append(advance())
        }

        return makeToken(.singleLineComment, value: .comment(comment))
    }

    private func scanMultiLineComment() throws -> Token {
        if !dialect.allowsComments {
            throw makeError(.commentsNotAllowed)
        }

        var comment = ""

        while !isAtEnd() {
            if peek() == "*" {
                let star = advance()
                if !isAtEnd() && peek() == "/" {
                    advance()
                    return makeToken(.multiLineComment, value: .comment(comment))
                } else {
                    comment.append(star)
                }
            } else {
                comment.append(advance())
            }
        }

        throw makeError(.unexpectedEndOfFile)
    }

    // MARK: - Identifier Scanning

    private func scanIdentifier(firstChar: Character) throws -> Token {
        if !dialect.allowsUnquotedKeys {
            throw makeError(.unquotedKeysNotAllowed)
        }

        var identifier = String(firstChar)

        while !isAtEnd() {
            let char = peek()
            if char.isLetter || char.isNumber || char == "_" || char == "$" {
                identifier.append(advance())
            } else {
                break
            }
        }

        return makeToken(.identifier, value: .identifier(identifier))
    }

    // MARK: - Helper Methods

    @discardableResult
    private func advance() -> Character {
        let char = sourceChars[current]
        current += 1

        if char == "\n" {
            line += 1
            column = 1
        } else {
            column += 1
        }

        return char
    }

    private func peek() -> Character {
        guard !isAtEnd() else { return "\0" }
        return sourceChars[current]
    }

    @discardableResult
    private func match(_ expected: Character) -> Bool {
        if isAtEnd() { return false }
        if sourceChars[current] != expected { return false }

        advance()
        return true
    }

    private func isAtEnd() -> Bool {
        current >= sourceChars.count
    }

    private func makeToken(_ type: TokenType, value: TokenValue?) -> Token {
        let lexeme = String(sourceChars[tokenStart..<current])
        let location = SourceLocation(
            line: tokenStartLine,
            column: tokenStartColumn,
            offset: tokenStart,
            length: current - tokenStart
        )
        return Token(type: type, lexeme: lexeme, location: location, value: value)
    }

    private func makeError(_ type: LexerError.ErrorType) -> LexerError {
        let contextStart = max(0, tokenStart - 20)
        let contextEnd = min(sourceChars.count, current + 20)
        let context = String(sourceChars[contextStart..<contextEnd])

        let location = SourceLocation(
            line: line,
            column: column,
            offset: current,
            length: 1
        )

        return LexerError(type: type, location: location, context: context)
    }
}
