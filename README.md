# JsonLint

[![CI](https://github.com/dalemyers/JsonLint/actions/workflows/ci.yml/badge.svg)](https://github.com/dalemyers/JsonLint/actions/workflows/ci.yml)
[![Release](https://github.com/dalemyers/JsonLint/actions/workflows/release.yml/badge.svg)](https://github.com/dalemyers/JsonLint/actions/workflows/release.yml)
[![Swift Version](https://img.shields.io/badge/swift-5.9+-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey.svg)](https://github.com/dalemyers/JsonLint)

A modular JSON linter and formatter for Swift, supporting JSON, JSON5, and JSONC dialects.

## Installation

### Pre-built Binaries (Recommended)

Download the latest release for your platform:

#### macOS

```bash
# Apple Silicon (M1/M2/M3)
curl -L -o jsonlint https://github.com/dalemyers/JsonLint/releases/latest/download/jsonlint-macos-arm64
chmod +x jsonlint
sudo mv jsonlint /usr/local/bin/

# Intel
curl -L -o jsonlint https://github.com/dalemyers/JsonLint/releases/latest/download/jsonlint-macos-x86_64
chmod +x jsonlint
sudo mv jsonlint /usr/local/bin/

# Either
curl -L -o jsonlint https://github.com/dalemyers/JsonLint/releases/latest/download/jsonlint-macos-universal
chmod +x jsonlint
sudo mv jsonlint /usr/local/bin/

```

#### Linux

```bash
curl -L -o jsonlint https://github.com/dalemyers/JsonLint/releases/latest/download/jsonlint-linux-x86_64
chmod +x jsonlint
sudo mv jsonlint /usr/local/bin/
```

#### Windows

```powershell
Invoke-WebRequest -Uri "https://github.com/dalemyers/JsonLint/releases/latest/download/jsonlint-windows-x86_64.exe" -OutFile "jsonlint.exe"
# Move to a directory in your PATH
```

### Homebrew (macOS)

```bash
# Coming soon
brew install jsonlint
```

### Building from Source

```bash
git clone <repository-url>
cd JsonLint
swift build -c release
```

The executable will be available at `.build/release/jsonlint`.

### Using as a Library

Add JsonLintCore to your Swift package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/dalemyers/JsonLint.git", from: "1.0.0")
]
```

## CLI Usage

### Basic Linting

```bash
# Lint a single file
jsonlint file.json

# Lint multiple files
jsonlint file1.json file2.json

# Lint a directory
jsonlint src/

# Read from stdin
echo '{"key": "value"}' | jsonlint --stdin
```

### Auto-Fix

```bash
# Fix violations and format
jsonlint --fix file.json

# Fix multiple files
jsonlint --fix src/
```

### Dialect Support

```bash
# Lint JSON5 files
jsonlint --dialect json5 config.json5

# Lint JSONC files
jsonlint --dialect jsonc tsconfig.json
```

### Output Formats

```bash
# Plain text output (default)
jsonlint file.json

# JSON output for tooling
jsonlint --format json file.json
```

### Configuration

```bash
# Use specific config file
jsonlint --config .jsonlint.toml file.json

# Override config options
jsonlint --indent-style tabs --indent-size 4 file.json
```

## Configuration File

Create a `.jsonlint.toml` file in your project root:

```toml
[general]
dialect = "json"

[formatting]
indent_style = "spaces"
indent_size = 2
line_width = 100
quote_style = "double"

[output]
format = "text"

[rules."structural.duplicate-keys"]
enabled = true
severity = "error"

[rules."style.trailing-comma"]
enabled = true
severity = "warning"
```

## Library Usage

```swift
import JsonLintCore

// Lint JSON
let result = try JsonLintCore.lint(
    source: #"{"key": "value"}"#,
    dialect: .json
)

if result.isValid {
    print("Valid JSON!")
} else {
    print("Found \(result.errorCount) errors")
    for violation in result.violations {
        print("\(violation.location.start.line):\(violation.location.start.column) - \(violation.message)")
    }
}

// Format JSON
let formatted = try JsonLintCore.format(
    source: #"{"key":"value"}"#,
    dialect: .json
)
print(formatted)
// {
//   "key": "value"
// }

// Fix violations
let fixResult = try JsonLintCore.fix(
    source: #"{"key":"value"}"#,
    dialect: .json
)
print(fixResult.fixedSource)
```

## Built-in Rules

### Structural Rules
- `structural.duplicate-keys`: Disallows duplicate keys in objects
- `structural.max-depth`: Limits maximum nesting depth

### Style Rules
- `style.trailing-comma`: Enforces trailing comma rules based on dialect
- `style.quote-style`: Enforces consistent quote style (single/double)

### Dialect Rules
- `dialect.no-comments`: Disallows comments in JSON (allowed in JSON5/JSONC)

## Supported Dialects

### JSON
Standard JSON as per RFC 8259.

### JSON5
Superset of JSON with:
- Single and double quoted strings
- Trailing commas in objects and arrays
- Unquoted object keys
- Comments (single-line and multi-line)
- Hexadecimal numbers
- Leading/trailing decimal points
- Infinity and NaN

### JSONC
JSON with Comments:
- Single and double quoted strings
- Comments (single-line and multi-line)
- Trailing commas NOT allowed (unlike JSON5)

## Development

### Running Tests

```bash
swift test
```

### Building

```bash
swift build
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
