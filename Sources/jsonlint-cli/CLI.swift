import ArgumentParser
import Foundation
import JsonConfig
import JsonFixer
import JsonLexer
import JsonParser
import JsonRules
import JsonValidator

/// Command-line options (separate from ParsableCommand for testability)
public struct CLIOptions {
    public var paths: [String]
    public var fix: Bool
    public var dialect: String?
    public var config: String?
    public var format: String?
    public var stdin: Bool
    public var indentStyle: String?
    public var indentSize: Int?
    public var verbose: Bool

    public init(
        paths: [String] = [],
        fix: Bool = false,
        dialect: String? = nil,
        config: String? = nil,
        format: String? = nil,
        stdin: Bool = false,
        indentStyle: String? = nil,
        indentSize: Int? = nil,
        verbose: Bool = false
    ) {
        self.paths = paths
        self.fix = fix
        self.dialect = dialect
        self.config = config
        self.format = format
        self.stdin = stdin
        self.indentStyle = indentStyle
        self.indentSize = indentSize
        self.verbose = verbose
    }
}

public struct JsonLintCLI: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "jsonlint",
        abstract: "A JSON linter and formatter",
        version: "1.2.0"
    )

    public init() {}

    @Argument(help: "Files or directories to lint")
    var paths: [String] = []

    @Flag(name: .long, help: "Fix violations automatically")
    var fix: Bool = false

    @Option(name: .long, help: "Dialect: json, json5, jsonc")
    var dialect: String?

    @Option(name: .long, help: "Config file path")
    var config: String?

    @Option(name: .long, help: "Output format: text, json")
    var format: String?

    @Flag(name: .long, help: "Read from stdin")
    var stdin: Bool = false

    @Option(name: .long, help: "Indent style: spaces, tabs")
    var indentStyle: String?

    @Option(name: .long, help: "Indent size")
    var indentSize: Int?

    @Flag(name: .long, help: "Enable verbose output")
    var verbose: Bool = false

    public mutating func run() throws {
        let options = CLIOptions(
            paths: paths,
            fix: fix,
            dialect: dialect,
            config: config,
            format: format,
            stdin: stdin,
            indentStyle: indentStyle,
            indentSize: indentSize,
            verbose: verbose
        )
        let cli = CLI()
        try cli.run(with: options)
    }
}

public struct CLI {
    public init() {}

    public func run(with options: CLIOptions) throws {
        let config = buildConfiguration(options: options)

        let filePaths: [String]
        if options.stdin {
            let stdinContent = readStdin()
            let file = InputFile(path: "<stdin>", content: stdinContent)

            let result: FileResult
            do {
                result = try processFile(file, config: config, fix: options.fix)
            } catch {
                result = FileResult(
                    path: "<stdin>",
                    violations: [],
                    error: error.localizedDescription,
                    fixed: false
                )
            }

            let formatter = createOutputFormatter(format: config.output.format)
            formatter.printResult(result)

            let totalErrors = result.violations.filter { $0.severity == .error }.count
            let totalWarnings = result.violations.filter { $0.severity == .warning }.count

            formatter.printSummary(
                filesChecked: 1, totalViolations: result.violations.count,
                totalErrors: totalErrors, totalWarnings: totalWarnings,
                totalFixed: result.fixed ? 1 : 0)

            let exitCode: Int32 = result.violations.count == 0 && result.error == nil ? 0 : 1
            throw ExitCode(exitCode)
        } else if options.paths.isEmpty {
            print("Error: No input files specified. Use --stdin to read from standard input.")
            throw ExitCode(1)
        } else {
            filePaths = try discoverFilePaths(from: options.paths)
        }

        let formatter = createOutputFormatter(format: config.output.format)

        var totalViolations = 0
        var totalErrors = 0
        var totalWarnings = 0
        var totalFixed = 0
        var filesChecked = 0

        for path in filePaths {
            if options.verbose {
                print("Processing: \(path)")
            }

            let result: FileResult
            do {
                // Load file content on-demand, only when processing
                let content = try String(contentsOfFile: path, encoding: .utf8)
                let file = InputFile(path: path, content: content)
                result = try processFile(file, config: config, fix: options.fix)
            } catch {
                result = FileResult(
                    path: path,
                    violations: [],
                    error: error.localizedDescription,
                    fixed: false
                )
            }

            // Stream result immediately
            formatter.printResult(result)

            // Update counters
            filesChecked += 1
            totalViolations += result.violations.count
            if result.fixed {
                totalFixed += 1
            }
            for violation in result.violations {
                if violation.severity == .error {
                    totalErrors += 1
                } else if violation.severity == .warning {
                    totalWarnings += 1
                }
            }
        }

        // Print summary at the end
        formatter.printSummary(
            filesChecked: filesChecked, totalViolations: totalViolations,
            totalErrors: totalErrors, totalWarnings: totalWarnings, totalFixed: totalFixed)

        let exitCode: Int32 = totalViolations == 0 ? 0 : 1
        throw ExitCode(exitCode)
    }

    public func buildConfiguration(options: CLIOptions) -> Configuration {
        var fileConfig = Configuration.default

        if let configPath = options.config {
            fileConfig = (try? ConfigLoader().load(from: configPath)) ?? Configuration.default
        } else if let discovered = ConfigLoader().discover(
            startingFrom: FileManager.default.currentDirectoryPath)
        {
            fileConfig = discovered
        }

        var general = fileConfig.general
        if let dialect = options.dialect {
            general = Configuration.GeneralConfig(dialect: dialect)
        }

        var formatting = fileConfig.formatting
        if let indentStyle = options.indentStyle {
            formatting = Configuration.FormattingConfig(
                indentStyle: indentStyle,
                indentSize: options.indentSize ?? formatting.indentSize,
                lineWidth: formatting.lineWidth,
                quoteStyle: formatting.quoteStyle
            )
        }

        var output = fileConfig.output
        if let format = options.format {
            output = Configuration.OutputConfig(format: format)
        }

        return Configuration(
            general: general,
            formatting: formatting,
            rules: fileConfig.rules,
            output: output
        )
    }

    private func discoverFilePaths(from paths: [String]) throws -> [String] {
        var filePaths: [String] = []

        for path in paths {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else {
                throw CLIError.fileNotFound(path)
            }

            if isDirectory.boolValue {
                filePaths.append(contentsOf: try findJSONFilePaths(in: path))
            } else {
                filePaths.append(path)
            }
        }

        return filePaths
    }

    private func findJSONFilePaths(in directory: String) throws -> [String] {
        var filePaths: [String] = []
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(atPath: directory) else {
            return filePaths
        }

        for case let file as String in enumerator {
            let fullPath = "\(directory)/\(file)"
            if file.hasSuffix(".json") || file.hasSuffix(".json5") || file.hasSuffix(".jsonc") {
                filePaths.append(fullPath)
            }
        }

        return filePaths
    }

    private func processFile(_ file: InputFile, config: Configuration, fix: Bool) throws
        -> FileResult
    {
        let lexer = Lexer(source: file.content, dialect: config.general.dialectEnum)
        let tokens = try lexer.tokenize()

        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let ruleConfig = config.toRuleConfiguration()
        let validator = Validator(config: ruleConfig)
        let validationResult = validator.validate(ast, sourceText: file.content)

        var fixedContent: String?
        if fix {
            let formatter = Formatter(config: ruleConfig)
            let formatted = formatter.format(ast)

            if file.path == "<stdin>" {
                print(formatted)
            } else {
                try formatted.write(toFile: file.path, atomically: true, encoding: .utf8)
            }

            fixedContent = formatted
        }

        return FileResult(
            path: file.path,
            violations: validationResult.violations,
            error: nil,
            fixed: fixedContent != nil
        )
    }

    private func readStdin() -> String {
        var input = ""
        while let line = readLine() {
            input += line + "\n"
        }
        return input
    }
}

public struct InputFile {
    public let path: String
    public let content: String

    public init(path: String, content: String) {
        self.path = path
        self.content = content
    }
}

public struct FileResult {
    public let path: String
    public let violations: [Violation]
    public let error: String?
    public let fixed: Bool

    public init(path: String, violations: [Violation], error: String?, fixed: Bool) {
        self.path = path
        self.violations = violations
        self.error = error
        self.fixed = fixed
    }
}

public enum CLIError: Error, CustomStringConvertible {
    case fileNotFound(String)

    public var description: String {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        }
    }
}
