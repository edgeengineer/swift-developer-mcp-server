import Foundation
import MCP

// MARK: - Error Types

public enum ToolError: Swift.Error {
    case invalidInput(String)
}

// MARK: - Process Execution

public struct ProcessResult {
    public let output: String
    public let success: Bool
    public let exitCode: Int32
    
    public init(output: String, success: Bool, exitCode: Int32) {
        self.output = output
        self.success = success
        self.exitCode = exitCode
    }
}

public func executeProcess(command: [String], workingDirectory: String? = nil) async throws -> ProcessResult {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = command
    
    if let workingDirectory = workingDirectory {
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
    }
    
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe
    
    try process.run()
    process.waitUntilExit()
    
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
    
    let output = String(data: outputData, encoding: .utf8) ?? ""
    let error = String(data: errorData, encoding: .utf8) ?? ""
    
    let success = process.terminationStatus == 0
    let combinedOutput = success ? output : "\(output)\n\(error)"
    
    return ProcessResult(
        output: combinedOutput,
        success: success,
        exitCode: process.terminationStatus
    )
}

// MARK: - API Extraction Helpers

public func parseSymbolGraphForDependency(_ symbolGraph: String, dependencyName: String) -> String {
    let lines = symbolGraph.components(separatedBy: .newlines)
    var apiInfo = "Symbols for \(dependencyName):\n"
    
    for line in lines {
        if line.contains(dependencyName) && (line.contains("public") || line.contains("\"kind\"")) {
            apiInfo += "  \(line.trimmingCharacters(in: .whitespaces))\n"
        }
    }
    
    if apiInfo == "Symbols for \(dependencyName):\n" {
        apiInfo += "  No public symbols found in symbol graph for \(dependencyName)\n"
        apiInfo += "  This may indicate the dependency is not built or has no public API\n"
    }
    
    return apiInfo
}

public func extractAPIFallback(dependencyName: String, packagePath: String) async throws -> String {
    let buildCommand = ["swift", "build"]
    let buildResult = try await executeProcess(command: buildCommand, workingDirectory: packagePath)
    
    if !buildResult.success {
        return "Failed to build project for API extraction:\n\(buildResult.output)"
    }
    
    let buildPath = "\(packagePath)/.build"
    
    guard FileManager.default.fileExists(atPath: buildPath) else {
        return "No build directory found. Please build the project first."
    }
    
    var result = "API extraction fallback for \(dependencyName):\n"
    result += "Build completed successfully, but detailed API extraction requires additional tooling.\n"
    result += "Consider using swift-api-extract or DocC for comprehensive API documentation.\n"
    result += "\nTo extract API manually:\n"
    result += "1. swift package generate-documentation\n"
    result += "2. swift package dump-symbol-graph\n"
    result += "3. Use swift-api-extract tool if available\n"
    
    return result
}