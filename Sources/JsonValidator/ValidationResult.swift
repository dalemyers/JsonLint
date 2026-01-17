import JsonRules

public struct ValidationResult: Sendable {
    public let violations: [Violation]
    public let isValid: Bool

    public init(violations: [Violation], isValid: Bool) {
        self.violations = violations
        self.isValid = isValid
    }

    public var errorCount: Int {
        violations.filter { $0.severity == .error }.count
    }

    public var warningCount: Int {
        violations.filter { $0.severity == .warning }.count
    }

    public var infoCount: Int {
        violations.filter { $0.severity == .info }.count
    }

    public var hasErrors: Bool {
        errorCount > 0
    }

    public var hasWarnings: Bool {
        warningCount > 0
    }
}
