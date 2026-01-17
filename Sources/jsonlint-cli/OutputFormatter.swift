import Foundation
import JsonRules

public protocol OutputFormatter {
    func print(_ results: [FileResult])
    func printResult(_ result: FileResult)
    func printSummary(filesChecked: Int, totalViolations: Int, totalErrors: Int, totalWarnings: Int, totalFixed: Int)
}

public func createOutputFormatter(format: String) -> any OutputFormatter {
    switch format.lowercased() {
    case "json":
        return JSONOutputFormatter()
    default:
        return TextOutputFormatter()
    }
}

public struct TextOutputFormatter: OutputFormatter {
    public init() {}

    public func print(_ results: [FileResult]) {
        for result in results {
            printResult(result)
        }

        let totalFiles = results.count
        let totalViolations = results.reduce(0) { $0 + $1.violations.count }
        let totalFixed = results.filter(\.fixed).count
        let totalErrors = results.reduce(0) { result, file in
            result + file.violations.filter { $0.severity == .error }.count
        }
        let totalWarnings = results.reduce(0) { result, file in
            result + file.violations.filter { $0.severity == .warning }.count
        }

        printSummary(filesChecked: totalFiles, totalViolations: totalViolations,
                    totalErrors: totalErrors, totalWarnings: totalWarnings, totalFixed: totalFixed)
    }

    public func printResult(_ result: FileResult) {
        Swift.print("\(result.path):")

        if let error = result.error {
            Swift.print("  ✗ Error: \(error)")
            Swift.print()
            return
        }

        if result.violations.isEmpty {
            Swift.print("  ✓ No issues found")
        } else {
            for violation in result.violations {
                let icon = severityIcon(violation.severity)
                let location = "\(violation.location.start.line):\(violation.location.start.column)"
                Swift.print("  \(icon) \(location) \(violation.message) [\(violation.rule)]")

                if let suggestion = violation.suggestion {
                    Swift.print("    💡 \(suggestion)")
                }
            }
        }

        if result.fixed {
            Swift.print("  ✓ Fixed automatically")
        }

        Swift.print()
    }

    public func printSummary(filesChecked: Int, totalViolations: Int, totalErrors: Int, totalWarnings: Int, totalFixed: Int) {
        Swift.print("Summary:")
        Swift.print("  Files checked: \(filesChecked)")
        Swift.print("  Total violations: \(totalViolations)")
        if totalErrors > 0 {
            Swift.print("    Errors: \(totalErrors)")
        }
        if totalWarnings > 0 {
            Swift.print("    Warnings: \(totalWarnings)")
        }
        if totalFixed > 0 {
            Swift.print("  Files fixed: \(totalFixed)")
        }
    }

    private func severityIcon(_ severity: Severity) -> String {
        switch severity {
        case .error: return "✗"
        case .warning: return "⚠"
        case .info: return "ℹ"
        }
    }
}

public struct JSONOutputFormatter: OutputFormatter {
    public init() {}

    public func print(_ results: [FileResult]) {
        // Print each result as a JSON Lines entry
        for result in results {
            printResult(result)
        }
    }

    public func printResult(_ result: FileResult) {
        var dict: [String: Any] = [
            "path": result.path,
            "fixed": result.fixed
        ]

        if let error = result.error {
            dict["error"] = error
        } else {
            dict["violations"] = result.violations.map { violation -> [String: Any] in
                var violationDict: [String: Any] = [
                    "rule": violation.rule,
                    "severity": violation.severity.rawValue,
                    "message": violation.message,
                    "line": violation.location.start.line,
                    "column": violation.location.start.column
                ]

                if let suggestion = violation.suggestion {
                    violationDict["suggestion"] = suggestion
                }

                return violationDict
            }
        }

        // Print as a single-line JSON object (JSON Lines format)
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            Swift.print(jsonString)
        }
    }

    public func printSummary(filesChecked: Int, totalViolations: Int, totalErrors: Int, totalWarnings: Int, totalFixed: Int) {
        // Print summary as a JSON object
        var summary: [String: Any] = [
            "summary": true,
            "filesChecked": filesChecked,
            "totalViolations": totalViolations
        ]

        if totalErrors > 0 {
            summary["errors"] = totalErrors
        }
        if totalWarnings > 0 {
            summary["warnings"] = totalWarnings
        }
        if totalFixed > 0 {
            summary["filesFixed"] = totalFixed
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: summary, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            Swift.print(jsonString)
        }
    }
}
