import Foundation
import MCP

// MARK: - Package Info Tools

public struct GetPackageInfoTool {
    public static let tool = Tool(
        name: "get_package_info",
        description: "Get Swift package information",
        inputSchema: [
            "type": "object",
            "properties": [
                "package_path": [
                    "type": "string",
                    "description": "Path to the Swift package (optional)"
                ]
            ]
        ]
    )
    
    public static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        let packagePath = arguments["package_path"]?.stringValue ?? FileManager.default.currentDirectoryPath
        let packageSwiftPath = "\(packagePath)/Package.swift"
        
        guard FileManager.default.fileExists(atPath: packageSwiftPath) else {
            throw ToolError.invalidInput("Package.swift not found at \(packageSwiftPath)")
        }
        
        let command = ["swift", "package", "describe", "--type", "json"]
        let result = try await executeProcess(command: command, workingDirectory: packagePath)
        
        if result.success {
            let formattedInfo = "Swift Package Information:\n\(result.output)"
            return CallTool.Result(content: [.text(formattedInfo)])
        } else {
            return CallTool.Result(content: [.text("Failed to get package information:\n\(result.output)")], isError: true)
        }
    }
}

public struct PrintDependencyPublicAPITool {
    public static let tool = Tool(
        name: "print_dependency_public_api",
        description: "Print the public API of a dependency",
        inputSchema: [
            "type": "object",
            "properties": [
                "dependency_name": [
                    "type": "string",
                    "description": "Name of the dependency (required)"
                ],
                "package_path": [
                    "type": "string",
                    "description": "Path to the Swift package (optional)"
                ],
                "verbose": [
                    "type": "boolean",
                    "description": "Enable verbose output",
                    "default": false
                ]
            ],
            "required": ["dependency_name"]
        ]
    )
    
    public static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        guard let dependencyName = arguments["dependency_name"]?.stringValue else {
            throw ToolError.invalidInput("dependency_name is required")
        }
        
        let packagePath = arguments["package_path"]?.stringValue ?? FileManager.default.currentDirectoryPath
        let verbose = arguments["verbose"]?.boolValue ?? false
        
        let describeCommand = ["swift", "package", "describe", "--type", "json"]
        let describeResult = try await executeProcess(command: describeCommand, workingDirectory: packagePath)
        
        guard describeResult.success else {
            return CallTool.Result(content: [.text("Failed to get package information:\n\(describeResult.output)")], isError: true)
        }
        
        var command = ["swift", "package", "dump-symbol-graph"]
        
        if verbose {
            command.append("--verbose")
        }
        
        let result = try await executeProcess(command: command, workingDirectory: packagePath)
        
        if result.success {
            let apiInfo = parseSymbolGraphForDependency(result.output, dependencyName: dependencyName)
            return CallTool.Result(content: [.text("Public API for \(dependencyName):\n\(apiInfo)")])
        } else {
            let fallbackResult = try await extractAPIFallback(dependencyName: dependencyName, packagePath: packagePath)
            return CallTool.Result(content: [.text(fallbackResult)])
        }
    }
}