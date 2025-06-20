import Foundation
import MCP

// MARK: - Build & Test Tools

public struct SwiftBuildTool {
    public static let tool = Tool(
        name: "swift_build",
        description: "Build your Swift project",
        inputSchema: [
            "type": "object",
            "properties": [
                "project_path": [
                    "type": "string",
                    "description": "Path to the Swift project (optional, defaults to current directory)"
                ],
                "configuration": [
                    "type": "string",
                    "enum": ["debug", "release"],
                    "description": "Build configuration",
                    "default": "debug"
                ],
                "target": [
                    "type": "string",
                    "description": "Specific target to build (optional, builds all if not specified)"
                ],
                "verbose": [
                    "type": "boolean",
                    "description": "Enable verbose output",
                    "default": false
                ]
            ]
        ]
    )
    
    public static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        let projectPath = arguments["project_path"]?.stringValue ?? FileManager.default.currentDirectoryPath
        let configuration = arguments["configuration"]?.stringValue ?? "debug"
        let target = arguments["target"]?.stringValue
        let verbose = arguments["verbose"]?.boolValue ?? false
        
        var command = ["swift", "build"]
        
        if configuration == "release" {
            command.append("-c")
            command.append("release")
        }
        
        if let target = target {
            command.append("--target")
            command.append(target)
        }
        
        if verbose {
            command.append("--verbose")
        }
        
        let result = try await executeProcess(command: command, workingDirectory: projectPath)
        return CallTool.Result(content: [.text(result.output)], isError: !result.success)
    }
}

public struct SwiftTestTool {
    public static let tool = Tool(
        name: "swift_test",
        description: "Run Swift tests",
        inputSchema: [
            "type": "object",
            "properties": [
                "project_path": [
                    "type": "string",
                    "description": "Path to the Swift project (optional)"
                ],
                "test_filter": [
                    "type": "string",
                    "description": "Filter tests by name pattern (optional)"
                ],
                "parallel": [
                    "type": "boolean",
                    "description": "Run tests in parallel",
                    "default": true
                ],
                "verbose": [
                    "type": "boolean",
                    "description": "Enable verbose output",
                    "default": false
                ]
            ]
        ]
    )
    
    public static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        let projectPath = arguments["project_path"]?.stringValue ?? FileManager.default.currentDirectoryPath
        let testFilter = arguments["test_filter"]?.stringValue
        let parallel = arguments["parallel"]?.boolValue ?? true
        let verbose = arguments["verbose"]?.boolValue ?? false
        
        var command = ["swift", "test"]
        
        if let testFilter = testFilter {
            command.append("--filter")
            command.append(testFilter)
        }
        
        if !parallel {
            command.append("--parallel")
        }
        
        if verbose {
            command.append("--verbose")
        }
        
        let result = try await executeProcess(command: command, workingDirectory: projectPath)
        return CallTool.Result(content: [.text(result.output)], isError: !result.success)
    }
}

public struct RunTargetTool {
    public static let tool = Tool(
        name: "run_target",
        description: "Run a specific executable target",
        inputSchema: [
            "type": "object",
            "properties": [
                "target": [
                    "type": "string",
                    "description": "Name of the target to run (required)"
                ],
                "project_path": [
                    "type": "string",
                    "description": "Path to the Swift project (optional)"
                ],
                "arguments": [
                    "type": "array",
                    "items": ["type": "string"],
                    "description": "Command line arguments to pass"
                ]
            ],
            "required": ["target"]
        ]
    )
    
    public static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        guard let target = arguments["target"]?.stringValue else {
            throw ToolError.invalidInput("Target is required")
        }
        
        let projectPath = arguments["project_path"]?.stringValue ?? FileManager.default.currentDirectoryPath
        let targetArguments = arguments["arguments"]?.arrayValue?.compactMap { $0.stringValue } ?? []
        
        var command = ["swift", "run", target]
        if !targetArguments.isEmpty {
            command.append("--")
            command.append(contentsOf: targetArguments)
        }
        
        let result = try await executeProcess(command: command, workingDirectory: projectPath)
        return CallTool.Result(content: [.text(result.output)], isError: !result.success)
    }
}