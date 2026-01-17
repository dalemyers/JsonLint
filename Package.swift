// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JsonLint",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        // Public library API
        .library(
            name: "JsonLintCore",
            targets: ["JsonLintCore"]
        ),
        // CLI executable
        .executable(
            name: "jsonlint",
            targets: ["jsonlint"]
        ),
    ],
    dependencies: [
        // CLI argument parsing
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        // TOML parsing
        .package(url: "https://github.com/LebJe/TOMLKit", from: "0.5.0"),
    ],
    targets: [
        // MARK: - Core Modules

        // Lexer (completely independent, no dependencies)
        .target(
            name: "JsonLexer",
            dependencies: []
        ),

        // Parser (depends on Lexer)
        .target(
            name: "JsonParser",
            dependencies: ["JsonLexer"]
        ),

        // Rules system (depends on Parser)
        .target(
            name: "JsonRules",
            dependencies: ["JsonParser"]
        ),

        // Validator (depends on Rules)
        .target(
            name: "JsonValidator",
            dependencies: ["JsonRules"]
        ),

        // Fixer (depends on Rules)
        .target(
            name: "JsonFixer",
            dependencies: ["JsonRules"]
        ),

        // Config system (depends on Lexer for dialect types and Rules for rule configuration)
        .target(
            name: "JsonConfig",
            dependencies: [
                "JsonLexer",
                "JsonRules",
                .product(name: "TOMLKit", package: "TOMLKit"),
            ]
        ),

        // MARK: - Public API

        // Core library facade (aggregates all modules)
        .target(
            name: "JsonLintCore",
            dependencies: [
                "JsonLexer",
                "JsonParser",
                "JsonRules",
                "JsonValidator",
                "JsonFixer",
                "JsonConfig",
            ]
        ),

        // MARK: - CLI

        // CLI library (testable)
        .target(
            name: "JsonLintCLI",
            dependencies: [
                "JsonLintCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/jsonlint-cli"
        ),

        // CLI executable (thin wrapper)
        .executableTarget(
            name: "jsonlint",
            dependencies: ["JsonLintCLI"]
        ),

        // MARK: - Tests

        .testTarget(
            name: "JsonLexerTests",
            dependencies: ["JsonLexer"]
        ),

        .testTarget(
            name: "JsonParserTests",
            dependencies: ["JsonParser"]
        ),

        .testTarget(
            name: "JsonRulesTests",
            dependencies: ["JsonRules"]
        ),

        .testTarget(
            name: "JsonValidatorTests",
            dependencies: ["JsonValidator"]
        ),

        .testTarget(
            name: "JsonFixerTests",
            dependencies: ["JsonFixer"]
        ),

        .testTarget(
            name: "JsonConfigTests",
            dependencies: ["JsonConfig", "JsonParser", "JsonRules"]
        ),

        .testTarget(
            name: "JsonLintCoreTests",
            dependencies: ["JsonLintCore"]
        ),

        .testTarget(
            name: "CLITests",
            dependencies: [
                "JsonLintCLI",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ]
)
