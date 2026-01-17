import JsonLexer

public final class Parser {
    private let tokens: [Token]
    private var current: Int = 0

    public init(tokens: [Token]) {
        self.tokens = tokens
    }

    public func parse() throws -> JSONValue {
        let value = try parseValue()
        skipTrivia()
        try expect(.eof)
        return value
    }

    // MARK: - Value Parsing

    private func parseValue() throws -> JSONValue {
        let leading = collectTrivia()

        guard !isAtEnd() else {
            throw makeError(.unexpectedEndOfFile)
        }

        let value: JSONValue

        switch peek().type {
        case .leftBrace:
            value = .object(try parseObject(leadingTrivia: leading))
        case .leftBracket:
            value = .array(try parseArray(leadingTrivia: leading))
        case .string:
            value = .string(try parseString(leadingTrivia: leading))
        case .number:
            value = .number(try parseNumber(leadingTrivia: leading))
        case .boolean:
            value = .boolean(try parseBoolean(leadingTrivia: leading))
        case .null:
            value = .null(try parseNull(leadingTrivia: leading))
        default:
            throw makeError(.invalidValue)
        }

        return value
    }

    // MARK: - Object Parsing

    private func parseObject(leadingTrivia: [Token]) throws -> JSONObject {
        let startToken = try consume(.leftBrace)
        var members: [JSONObject.Member] = []
        var seenKeys: Set<String> = []
        var hasTrailingComma = false

        skipTrivia()

        while !check(.rightBrace) && !isAtEnd() {
            let member = try parseObjectMember()

            if seenKeys.contains(member.key.value) {
                throw ParserError(
                    type: .duplicateKey(member.key.value),
                    location: member.key.location
                )
            }
            seenKeys.insert(member.key.value)

            members.append(member)

            skipTrivia()

            if check(.comma) {
                let comma = advance()
                members[members.count - 1] = JSONObject.Member(
                    key: member.key,
                    colon: member.colon,
                    value: member.value,
                    comma: comma
                )

                skipTrivia()

                if check(.rightBrace) {
                    hasTrailingComma = true
                }
            } else if !check(.rightBrace) {
                throw makeError(.expectedCommaOrClosingBrace)
            }
        }

        let endToken = try consume(.rightBrace)
        let trailing = collectTrivia()

        let location = SourceRange(
            start: startToken.location,
            end: endToken.location
        )

        return JSONObject(
            location: location,
            leadingTrivia: leadingTrivia,
            trailingTrivia: trailing,
            members: members,
            hasTrailingComma: hasTrailingComma
        )
    }

    private func parseObjectMember() throws -> JSONObject.Member {
        let key = try parseKey()

        skipTrivia()

        let colon = try consume(.colon)

        skipTrivia()

        let value = try parseValue()

        return JSONObject.Member(key: key, colon: colon, value: value, comma: nil)
    }

    internal func parseKey() throws -> JSONKey {
        skipTrivia()

        // Note: isAtEnd() check omitted as parseObject ensures we're not at EOF before calling parseKey
        let token = advance()

        switch token.type {
        case .string:
            if case .string(let str) = token.value {
                return JSONKey(
                    token: token,
                    value: str,
                    location: SourceRange(location: token.location)
                )
            }
            fallthrough
        case .identifier:
            if case .identifier(let id) = token.value {
                return JSONKey(
                    token: token,
                    value: id,
                    location: SourceRange(location: token.location)
                )
            }
            fallthrough
        default:
            throw ParserError(
                type: .unexpectedToken(expected: "object key", got: token.type),
                location: SourceRange(location: token.location),
                token: token
            )
        }
    }

    // MARK: - Array Parsing

    private func parseArray(leadingTrivia: [Token]) throws -> JSONArray {
        let startToken = try consume(.leftBracket)
        var elements: [JSONArray.Element] = []
        var hasTrailingComma = false

        skipTrivia()

        while !check(.rightBracket) && !isAtEnd() {
            let value = try parseValue()
            elements.append(JSONArray.Element(value: value, comma: nil))

            skipTrivia()

            if check(.comma) {
                let comma = advance()
                elements[elements.count - 1] = JSONArray.Element(value: value, comma: comma)

                skipTrivia()

                if check(.rightBracket) {
                    hasTrailingComma = true
                }
            } else if !check(.rightBracket) {
                throw makeError(.expectedCommaOrClosingBracket)
            }
        }

        let endToken = try consume(.rightBracket)
        let trailing = collectTrivia()

        let location = SourceRange(
            start: startToken.location,
            end: endToken.location
        )

        return JSONArray(
            location: location,
            leadingTrivia: leadingTrivia,
            trailingTrivia: trailing,
            elements: elements,
            hasTrailingComma: hasTrailingComma
        )
    }

    // MARK: - Literal Parsing

    private func parseString(leadingTrivia: [Token]) throws -> JSONString {
        let token = try consumeString()

        guard case .string(let str) = token.value else {
            throw makeError(.invalidValue)
        }

        let trailing = collectTrivia()

        return JSONString(
            location: SourceRange(location: token.location),
            leadingTrivia: leadingTrivia,
            trailingTrivia: trailing,
            token: token,
            value: str
        )
    }

    private func parseNumber(leadingTrivia: [Token]) throws -> JSONNumber {
        let token = try consume(.number)

        guard case .number(let num) = token.value else {
            throw makeError(.invalidValue)
        }

        let trailing = collectTrivia()

        return JSONNumber(
            location: SourceRange(location: token.location),
            leadingTrivia: leadingTrivia,
            trailingTrivia: trailing,
            token: token,
            value: num
        )
    }

    private func parseBoolean(leadingTrivia: [Token]) throws -> JSONBoolean {
        let token = try consume(.boolean)

        guard case .boolean(let bool) = token.value else {
            throw makeError(.invalidValue)
        }

        let trailing = collectTrivia()

        return JSONBoolean(
            location: SourceRange(location: token.location),
            leadingTrivia: leadingTrivia,
            trailingTrivia: trailing,
            token: token,
            value: bool
        )
    }

    private func parseNull(leadingTrivia: [Token]) throws -> JSONNull {
        let token = try consume(.null)
        let trailing = collectTrivia()

        return JSONNull(
            location: SourceRange(location: token.location),
            leadingTrivia: leadingTrivia,
            trailingTrivia: trailing,
            token: token
        )
    }

    // MARK: - Token Management

    @discardableResult
    private func advance() -> Token {
        let token = tokens[current]
        if !isAtEnd() {
            current += 1
        }
        return token
    }

    private func peek() -> Token {
        tokens[current]
    }

    private func previous() -> Token {
        tokens[current - 1]
    }

    private func isAtEnd() -> Bool {
        peek().type == .eof
    }

    private func check(_ type: TokenType) -> Bool {
        return peek().type == type
    }

    @discardableResult
    private func consume(_ type: TokenType) throws -> Token {
        if check(type) {
            return advance()
        }

        throw ParserError(
            type: .unexpectedToken(expected: "\(type)", got: peek().type),
            location: SourceRange(location: peek().location),
            token: peek()
        )
    }

    @discardableResult
    private func consumeString() throws -> Token {
        // Called only after verifying token type in parseValue
        return advance()
    }

    @discardableResult
    private func expect(_ type: TokenType) throws -> Token {
        if check(type) {
            return peek()
        }

        throw ParserError(
            type: .unexpectedToken(expected: "\(type)", got: peek().type),
            location: SourceRange(location: peek().location),
            token: peek()
        )
    }

    // MARK: - Trivia Handling

    private func collectTrivia() -> [Token] {
        var trivia: [Token] = []

        while !isAtEnd() {
            switch peek().type {
            case .whitespace, .newline, .singleLineComment, .multiLineComment:
                trivia.append(advance())
            default:
                return trivia
            }
        }

        return trivia
    }

    private func skipTrivia() {
        while !isAtEnd() {
            switch peek().type {
            case .whitespace, .newline, .singleLineComment, .multiLineComment:
                advance()
            default:
                return
            }
        }
    }

    // MARK: - Error Handling

    private func makeError(_ type: ParserError.ErrorType) -> ParserError {
        let token = (current > 0 && isAtEnd()) ? previous() : peek()
        return ParserError(
            type: type,
            location: SourceRange(location: token.location),
            token: token
        )
    }
}
