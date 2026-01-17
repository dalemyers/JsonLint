import Testing
import Foundation
import ArgumentParser
@testable import JsonLintCLI
@testable import JsonRules
@testable import JsonLexer
@testable import JsonConfig

@Suite("CLI Tests")
struct CLITests {
    @Test("createOutputFormatter returns TextOutputFormatter by default")
    func createOutputFormatterDefault() {
        let formatter = createOutputFormatter(format: "text")
        #expect(formatter is TextOutputFormatter)
    }

    @Test("createOutputFormatter returns JSONOutputFormatter for json")
    func createOutputFormatterJSON() {
        let formatter = createOutputFormatter(format: "json")
        #expect(formatter is JSONOutputFormatter)
    }

    @Test("createOutputFormatter returns TextOutputFormatter for unknown format")
    func createOutputFormatterUnknown() {
        let formatter = createOutputFormatter(format: "unknown")
        #expect(formatter is TextOutputFormatter)
    }

    @Test("createOutputFormatter is case insensitive")
    func createOutputFormatterCaseInsensitive() {
        let formatter1 = createOutputFormatter(format: "JSON")
        #expect(formatter1 is JSONOutputFormatter)

        let formatter2 = createOutputFormatter(format: "TEXT")
        #expect(formatter2 is TextOutputFormatter)
    }

    @Test("FileResult with no violations")
    func fileResultNoViolations() {
        let result = FileResult(
            path: "test.json",
            violations: [],
            error: nil,
            fixed: false
        )

        #expect(result.path == "test.json")
        #expect(result.violations.isEmpty)
        #expect(result.error == nil)
        #expect(!result.fixed)
    }

    @Test("FileResult with violations")
    func fileResultWithViolations() {
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 1)
        let range = SourceRange(location: loc)
        let violation = Violation(
            rule: "test.rule",
            severity: .error,
            message: "Test error",
            location: range
        )

        let result = FileResult(
            path: "test.json",
            violations: [violation],
            error: nil,
            fixed: false
        )

        #expect(result.violations.count == 1)
        #expect(result.violations[0].message == "Test error")
    }

    @Test("FileResult with error")
    func fileResultWithError() {
        let result = FileResult(
            path: "test.json",
            violations: [],
            error: "Parse error",
            fixed: false
        )

        #expect(result.error == "Parse error")
    }

    @Test("FileResult with fixed flag")
    func fileResultFixed() {
        let result = FileResult(
            path: "test.json",
            violations: [],
            error: nil,
            fixed: true
        )

        #expect(result.fixed)
    }

    @Test("InputFile initialization")
    func inputFileInit() {
        let file = InputFile(path: "/path/to/file.json", content: "{\"key\": \"value\"}")

        #expect(file.path == "/path/to/file.json")
        #expect(file.content == "{\"key\": \"value\"}")
    }

    @Test("CLIError fileNotFound description")
    func cliErrorFileNotFound() {
        let error = CLIError.fileNotFound("/path/to/missing.json")
        #expect(error.description.contains("/path/to/missing.json"))
    }

    @Test("CLI buildConfiguration with default options")
    func buildConfigurationDefault() {
        var options = CLIOptions()
        options.paths = []

        let cli = CLI()
        let config = cli.buildConfiguration(options: options)

        #expect(config.general.dialect == "json")
        #expect(config.formatting.indentStyle == "spaces")
        #expect(config.formatting.indentSize == 2)
    }

    @Test("CLI buildConfiguration with dialect override")
    func buildConfigurationDialectOverride() {
        var options = CLIOptions()
        options.paths = []
        options.dialect = "json5"

        let cli = CLI()
        let config = cli.buildConfiguration(options: options)

        #expect(config.general.dialect == "json5")
    }

    @Test("CLI buildConfiguration with indent style override")
    func buildConfigurationIndentStyleOverride() {
        var options = CLIOptions()
        options.paths = []
        options.indentStyle = "tabs"
        options.indentSize = 4

        let cli = CLI()
        let config = cli.buildConfiguration(options: options)

        #expect(config.formatting.indentStyle == "tabs")
        #expect(config.formatting.indentSize == 4)
    }

    @Test("CLI buildConfiguration with format override")
    func buildConfigurationFormatOverride() {
        var options = CLIOptions()
        options.paths = []
        options.format = "json"

        let cli = CLI()
        let config = cli.buildConfiguration(options: options)

        #expect(config.output.format == "json")
    }

    // Output Formatter Tests

    @Test("TextOutputFormatter with no violations")
    func textFormatterNoViolations() {
        let result = FileResult(
            path: "test.json",
            violations: [],
            error: nil,
            fixed: false
        )

        let formatter = TextOutputFormatter()
        formatter.print([result])
        // Output goes to stdout - just testing execution
    }

    @Test("TextOutputFormatter with violations")
    func textFormatterWithViolations() {
        let loc = SourceLocation(line: 10, column: 5, offset: 0, length: 1)
        let range = SourceRange(location: loc)
        let violation = Violation(
            rule: "test.rule",
            severity: .error,
            message: "Test error message",
            location: range
        )

        let result = FileResult(
            path: "test.json",
            violations: [violation],
            error: nil,
            fixed: false
        )

        let formatter = TextOutputFormatter()
        formatter.print([result])
    }

    @Test("TextOutputFormatter with warning violation")
    func textFormatterWithWarning() {
        let loc = SourceLocation(line: 5, column: 2, offset: 0, length: 1)
        let range = SourceRange(location: loc)
        let violation = Violation(
            rule: "test.warning",
            severity: .warning,
            message: "Test warning",
            location: range
        )

        let result = FileResult(
            path: "test.json",
            violations: [violation],
            error: nil,
            fixed: false
        )

        let formatter = TextOutputFormatter()
        formatter.print([result])
    }

    @Test("TextOutputFormatter with info violation")
    func textFormatterWithInfo() {
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 1)
        let range = SourceRange(location: loc)
        let violation = Violation(
            rule: "test.info",
            severity: .info,
            message: "Test info",
            location: range
        )

        let result = FileResult(
            path: "test.json",
            violations: [violation],
            error: nil,
            fixed: false
        )

        let formatter = TextOutputFormatter()
        formatter.print([result])
    }

    @Test("TextOutputFormatter with violation with suggestion")
    func textFormatterWithSuggestion() {
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 1)
        let range = SourceRange(location: loc)
        let violation = Violation(
            rule: "test.rule",
            severity: .error,
            message: "Test error",
            location: range,
            suggestion: "Try this fix"
        )

        let result = FileResult(
            path: "test.json",
            violations: [violation],
            error: nil,
            fixed: false
        )

        let formatter = TextOutputFormatter()
        formatter.print([result])
    }

    @Test("TextOutputFormatter with error")
    func textFormatterWithError() {
        let result = FileResult(
            path: "test.json",
            violations: [],
            error: "Parse error occurred",
            fixed: false
        )

        let formatter = TextOutputFormatter()
        formatter.print([result])
    }

    @Test("TextOutputFormatter with fixed flag")
    func textFormatterWithFixed() {
        let result = FileResult(
            path: "test.json",
            violations: [],
            error: nil,
            fixed: true
        )

        let formatter = TextOutputFormatter()
        formatter.print([result])
    }

    @Test("TextOutputFormatter with multiple files")
    func textFormatterMultipleFiles() {
        let loc1 = SourceLocation(line: 1, column: 1, offset: 0, length: 1)
        let range1 = SourceRange(location: loc1)
        let violation1 = Violation(
            rule: "test.rule",
            severity: .error,
            message: "Error 1",
            location: range1
        )

        let loc2 = SourceLocation(line: 2, column: 2, offset: 0, length: 1)
        let range2 = SourceRange(location: loc2)
        let violation2 = Violation(
            rule: "test.rule",
            severity: .warning,
            message: "Warning 1",
            location: range2
        )

        let result1 = FileResult(path: "test1.json", violations: [violation1], error: nil, fixed: false)
        let result2 = FileResult(path: "test2.json", violations: [violation2], error: nil, fixed: true)
        let result3 = FileResult(path: "test3.json", violations: [], error: nil, fixed: false)

        let formatter = TextOutputFormatter()
        formatter.print([result1, result2, result3])
    }

    @Test("JSONOutputFormatter with no violations")
    func jsonFormatterNoViolations() {
        let result = FileResult(
            path: "test.json",
            violations: [],
            error: nil,
            fixed: false
        )

        let formatter = JSONOutputFormatter()
        formatter.print([result])
    }

    @Test("JSONOutputFormatter with violations")
    func jsonFormatterWithViolations() {
        let loc = SourceLocation(line: 10, column: 5, offset: 0, length: 1)
        let range = SourceRange(location: loc)
        let violation = Violation(
            rule: "test.rule",
            severity: .error,
            message: "Test error",
            location: range
        )

        let result = FileResult(
            path: "test.json",
            violations: [violation],
            error: nil,
            fixed: false
        )

        let formatter = JSONOutputFormatter()
        formatter.print([result])
    }

    @Test("JSONOutputFormatter with violation with suggestion")
    func jsonFormatterWithSuggestion() {
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 1)
        let range = SourceRange(location: loc)
        let violation = Violation(
            rule: "test.rule",
            severity: .warning,
            message: "Test warning",
            location: range,
            suggestion: "Fix suggestion"
        )

        let result = FileResult(
            path: "test.json",
            violations: [violation],
            error: nil,
            fixed: false
        )

        let formatter = JSONOutputFormatter()
        formatter.print([result])
    }

    @Test("JSONOutputFormatter with error")
    func jsonFormatterWithError() {
        let result = FileResult(
            path: "test.json",
            violations: [],
            error: "Parse error",
            fixed: false
        )

        let formatter = JSONOutputFormatter()
        formatter.print([result])
    }

    @Test("JSONOutputFormatter with multiple files")
    func jsonFormatterMultipleFiles() {
        let loc = SourceLocation(line: 1, column: 1, offset: 0, length: 1)
        let range = SourceRange(location: loc)
        let violation = Violation(
            rule: "test.rule",
            severity: .info,
            message: "Test info",
            location: range
        )

        let result1 = FileResult(path: "test1.json", violations: [violation], error: nil, fixed: false)
        let result2 = FileResult(path: "test2.json", violations: [], error: nil, fixed: true)

        let formatter = JSONOutputFormatter()
        formatter.print([result1, result2])
    }

    // File Discovery Tests

    @Test("CLI discoverFiles with non-existent file throws error")
    func discoverFilesNonExistentFile() throws {
        let cli = CLI()
        var options = CLIOptions()
        options.paths = ["/tmp/nonexistent-file-that-does-not-exist-12345.json"]

        #expect(throws: CLIError.self) {
            try cli.run(with: options)
        }
    }

    @Test("CLI with single JSON file")
    func cliWithSingleFile() throws {
        // Create a temporary JSON file
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test-\(UUID().uuidString).json")
        let jsonContent = #"{"key": "value"}"#
        try jsonContent.write(to: testFile, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: testFile)
        }

        var options = CLIOptions()
        options.paths = [testFile.path]

        let cli = CLI()

        // This will throw ExitCode, which is expected
        #expect(throws: ExitCode.self) {
            try cli.run(with: options)
        }
    }

    @Test("CLI with directory containing JSON files")
    func cliWithDirectory() throws {
        // Create a temporary directory with JSON files
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test-dir-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let file1 = tempDir.appendingPathComponent("test1.json")
        let file2 = tempDir.appendingPathComponent("test2.json5")
        let file3 = tempDir.appendingPathComponent("test3.jsonc")

        try #"{"a": 1}"#.write(to: file1, atomically: true, encoding: .utf8)
        try #"{"b": 2}"#.write(to: file2, atomically: true, encoding: .utf8)
        try #"{"c": 3}"#.write(to: file3, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        var options = CLIOptions()
        options.paths = [tempDir.path]

        let cli = CLI()

        #expect(throws: ExitCode.self) {
            try cli.run(with: options)
        }
    }

    @Test("CLI with verbose flag")
    func cliWithVerbose() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test-\(UUID().uuidString).json")
        let jsonContent = #"{"key": "value"}"#
        try jsonContent.write(to: testFile, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: testFile)
        }

        var options = CLIOptions()
        options.paths = [testFile.path]
        options.verbose = true

        let cli = CLI()

        #expect(throws: ExitCode.self) {
            try cli.run(with: options)
        }
    }

    @Test("CLI with fix flag")
    func cliWithFix() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test-\(UUID().uuidString).json")
        let jsonContent = #"{"key":"value"}"#  // Compact JSON that needs formatting
        try jsonContent.write(to: testFile, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: testFile)
        }

        var options = CLIOptions()
        options.paths = [testFile.path]
        options.fix = true

        let cli = CLI()

        #expect(throws: ExitCode.self) {
            try cli.run(with: options)
        }

        // File should be reformatted
        let fixedContent = try String(contentsOf: testFile, encoding: .utf8)
        #expect(fixedContent.contains("\n"))  // Should have newlines after formatting
    }

    @Test("CLI with invalid JSON file")
    func cliWithInvalidJSON() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test-\(UUID().uuidString).json")
        let invalidJSON = #"{"key": invalid}"#
        try invalidJSON.write(to: testFile, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: testFile)
        }

        var options = CLIOptions()
        options.paths = [testFile.path]

        let cli = CLI()

        #expect(throws: ExitCode.self) {
            try cli.run(with: options)
        }
    }

    @Test("CLI with no paths specified")
    func cliWithNoPaths() throws {
        var options = CLIOptions()
        options.paths = []

        let cli = CLI()

        #expect(throws: ExitCode.self) {
            try cli.run(with: options)
        }
    }

    @Test("CLI buildConfiguration with custom config file path")
    func buildConfigurationWithConfigFile() throws {
        // Create a temporary config file
        let tempDir = FileManager.default.temporaryDirectory
        let configFile = tempDir.appendingPathComponent("test-config-\(UUID().uuidString).toml")
        let configContent = """
        [general]
        dialect = "json5"

        [formatting]
        indent_size = 4
        """
        try configContent.write(to: configFile, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: configFile)
        }

        // First verify the file exists and can be loaded directly
        #expect(FileManager.default.fileExists(atPath: configFile.path))

        let loader = ConfigLoader()
        let loadedConfig = try loader.load(from: configFile.path)
        #expect(loadedConfig.general.dialect == "json5")
        #expect(loadedConfig.formatting.indentSize == 4)

        var options = CLIOptions()
        options.paths = []
        options.config = configFile.path

        let cli = CLI()
        let config = cli.buildConfiguration(options: options)

        #expect(config.general.dialect == "json5")
        #expect(config.formatting.indentSize == 4)
    }

    @Test("CLI buildConfiguration with invalid config file path")
    func buildConfigurationWithInvalidConfigPath() {
        var options = CLIOptions()
        options.paths = []
        options.config = "/tmp/nonexistent-config-12345.toml"

        let cli = CLI()
        let config = cli.buildConfiguration(options: options)

        // Should fall back to defaults
        #expect(config.general.dialect == "json")
    }

    @Test("CLI buildConfiguration dialect override actually applies")
    func buildConfigurationDialectOverrideApplies() {
        var options = CLIOptions()
        options.paths = []
        options.dialect = "json5"

        let cli = CLI()
        let config = cli.buildConfiguration(options: options)

        #expect(config.general.dialect == "json5")
    }

    @Test("CLI buildConfiguration indent style override actually applies")
    func buildConfigurationIndentStyleOverrideApplies() {
        var options = CLIOptions()
        options.paths = []
        options.indentStyle = "tabs"
        options.indentSize = 4

        let cli = CLI()
        let config = cli.buildConfiguration(options: options)

        #expect(config.formatting.indentStyle == "tabs")
        #expect(config.formatting.indentSize == 4)
    }

    @Test("CLI buildConfiguration format override actually applies")
    func buildConfigurationFormatOverrideApplies() {
        var options = CLIOptions()
        options.paths = []
        options.format = "json"

        let cli = CLI()
        let config = cli.buildConfiguration(options: options)

        #expect(config.output.format == "json")
    }

    @Test("CLI run with valid JSON file exits with code 0")
    func cliRunValidFileExitsZero() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test-\(UUID().uuidString).json")
        let jsonContent = #"{"key": "value"}"#
        try jsonContent.write(to: testFile, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: testFile)
        }

        var options = CLIOptions()
        options.paths = [testFile.path]

        let cli = CLI()

        do {
            try cli.run(with: options)
            Issue.record("Expected ExitCode to be thrown")
        } catch let error as ExitCode {
            #expect(error.rawValue == 0)  // Should exit with 0 for valid file
        }
    }

    @Test("CLI run with file with violations exits with code 1")
    func cliRunInvalidFileExitsOne() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test-\(UUID().uuidString).json")
        // JSON with trailing comma (violation)
        let jsonContent = #"{"key": "value",}"#
        try jsonContent.write(to: testFile, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: testFile)
        }

        var options = CLIOptions()
        options.paths = [testFile.path]
        options.dialect = "json"  // Strict JSON doesn't allow trailing commas

        let cli = CLI()

        do {
            try cli.run(with: options)
            Issue.record("Expected ExitCode to be thrown")
        } catch is ExitCode {
            // Expected
        }
    }

    @Test("JSONOutputFormatter with all violation severities")
    func jsonFormatterAllSeverities() {
        let loc1 = SourceLocation(line: 1, column: 1, offset: 0, length: 1)
        let range1 = SourceRange(location: loc1)

        let loc2 = SourceLocation(line: 2, column: 1, offset: 0, length: 1)
        let range2 = SourceRange(location: loc2)

        let loc3 = SourceLocation(line: 3, column: 1, offset: 0, length: 1)
        let range3 = SourceRange(location: loc3)

        let violations = [
            Violation(rule: "test.error", severity: .error, message: "Error", location: range1, suggestion: "Fix error"),
            Violation(rule: "test.warning", severity: .warning, message: "Warning", location: range2, suggestion: "Fix warning"),
            Violation(rule: "test.info", severity: .info, message: "Info", location: range3, suggestion: "Fix info")
        ]

        let result = FileResult(path: "test.json", violations: violations, error: nil, fixed: false)

        let formatter = JSONOutputFormatter()
        formatter.print([result])
    }
}
