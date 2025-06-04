import Foundation
import MCP

// MARK: - Swiftly Tools

public struct SwiftlyInstallTool {
    public static let tool = Tool(
        name: "swiftly_install",
        description: "Install a Swift toolchain using swiftly",
        inputSchema: [
            "type": "object",
            "properties": [
                "version": [
                    "type": "string",
                    "description": "Version to install (required, e.g., '5.9', 'main', 'latest')"
                ],
                "channel": [
                    "type": "string",
                    "enum": ["release", "development", "nightly"],
                    "description": "Channel to use",
                    "default": "release"
                ],
                "force": [
                    "type": "boolean",
                    "description": "Force reinstall if already present",
                    "default": false
                ]
            ],
            "required": ["version"]
        ]
    )
    
    public static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        guard let version = arguments["version"]?.stringValue else {
            throw ToolError.invalidInput("Version is required")
        }
        
        let channel = arguments["channel"]?.stringValue ?? "release"
        let force = arguments["force"]?.boolValue ?? false
        
        var command = ["swiftly", "install", version]
        
        if channel != "release" {
            command.append("--channel")
            command.append(channel)
        }
        
        if force {
            command.append("--force")
        }
        
        let result = try await executeProcess(command: command)
        return CallTool.Result(content: [.text("Installing Swift \(version):\n\(result.output)")], isError: !result.success)
    }
}

public struct SwiftlyListTool {
    public static let tool = Tool(
        name: "swiftly_list",
        description: "List installed Swift toolchains",
        inputSchema: [
            "type": "object",
            "properties": [
                "include_system": [
                    "type": "boolean",
                    "description": "Include system toolchains",
                    "default": true
                ],
                "show_paths": [
                    "type": "boolean",
                    "description": "Show installation paths",
                    "default": false
                ]
            ]
        ]
    )
    
    public static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        let includeSystem = arguments["include_system"]?.boolValue ?? true
        let showPaths = arguments["show_paths"]?.boolValue ?? false
        
        var command = ["swiftly", "list"]
        
        if !includeSystem {
            command.append("--no-system")
        }
        
        if showPaths {
            command.append("--verbose")
        }
        
        let result = try await executeProcess(command: command)
        return CallTool.Result(content: [.text("Installed Swift toolchains:\n\(result.output)")], isError: !result.success)
    }
}

public struct SwiftlyListAvailableTool {
    public static let tool = Tool(
        name: "swiftly_list_available",
        description: "List available Swift versions to install",
        inputSchema: [
            "type": "object",
            "properties": [
                "channel": [
                    "type": "string",
                    "enum": ["release", "development", "nightly"],
                    "description": "Filter by channel (optional)"
                ],
                "latest_only": [
                    "type": "boolean",
                    "description": "Show only latest versions",
                    "default": false
                ]
            ]
        ]
    )
    
    public static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        let channel = arguments["channel"]?.stringValue
        let latestOnly = arguments["latest_only"]?.boolValue ?? false
        
        var command = ["swiftly", "list", "--available"]
        
        if let channel = channel {
            command.append("--channel")
            command.append(channel)
        }
        
        if latestOnly {
            command.append("--latest")
        }
        
        let result = try await executeProcess(command: command)
        return CallTool.Result(content: [.text("Available Swift versions:\n\(result.output)")], isError: !result.success)
    }
}

public struct SwiftlyUseTool {
    public static let tool = Tool(
        name: "swiftly_use",
        description: "Switch to a specific Swift version",
        inputSchema: [
            "type": "object",
            "properties": [
                "version": [
                    "type": "string",
                    "description": "Version to use (required)"
                ],
                "global": [
                    "type": "boolean",
                    "description": "Set as global default",
                    "default": false
                ],
                "project_path": [
                    "type": "string",
                    "description": "Set for specific project only (optional)"
                ]
            ],
            "required": ["version"]
        ]
    )
    
    public static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        guard let version = arguments["version"]?.stringValue else {
            throw ToolError.invalidInput("Version is required")
        }
        
        let global = arguments["global"]?.boolValue ?? false
        let projectPath = arguments["project_path"]?.stringValue
        
        var command = ["swiftly", "use", version]
        
        if global {
            command.append("--global")
        }
        
        let workingDirectory = projectPath ?? FileManager.default.currentDirectoryPath
        let result = try await executeProcess(command: command, workingDirectory: workingDirectory)
        return CallTool.Result(content: [.text("Switching to Swift \(version):\n\(result.output)")], isError: !result.success)
    }
}

public struct SwiftlyRunTool {
    public static let tool = Tool(
        name: "swiftly_run",
        description: "Run a command with a specific Swift version",
        inputSchema: [
            "type": "object",
            "properties": [
                "version": [
                    "type": "string",
                    "description": "Swift version to use (required)"
                ],
                "command": [
                    "type": "string",
                    "description": "Command to run (required)"
                ],
                "arguments": [
                    "type": "array",
                    "items": ["type": "string"],
                    "description": "Arguments to pass to the command"
                ]
            ],
            "required": ["version", "command"]
        ]
    )
    
    public static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        guard let version = arguments["version"]?.stringValue,
              let command = arguments["command"]?.stringValue else {
            throw ToolError.invalidInput("Version and command are required")
        }
        
        let commandArguments = arguments["arguments"]?.arrayValue?.compactMap { $0.stringValue } ?? []
        
        var swiftlyCommand = ["swiftly", "run", version, command]
        swiftlyCommand.append(contentsOf: commandArguments)
        
        let result = try await executeProcess(command: swiftlyCommand)
        return CallTool.Result(content: [.text("Running \(command) with Swift \(version):\n\(result.output)")], isError: !result.success)
    }
}

public struct SwiftlyUninstallTool {
    public static let tool = Tool(
        name: "swiftly_uninstall",
        description: "Uninstall a Swift toolchain",
        inputSchema: [
            "type": "object",
            "properties": [
                "version": [
                    "type": "string",
                    "description": "Version to uninstall (required)"
                ],
                "force": [
                    "type": "boolean",
                    "description": "Force removal",
                    "default": false
                ]
            ],
            "required": ["version"]
        ]
    )
    
    public static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        guard let version = arguments["version"]?.stringValue else {
            throw ToolError.invalidInput("Version is required")
        }
        
        let force = arguments["force"]?.boolValue ?? false
        
        var command = ["swiftly", "uninstall", version]
        
        if force {
            command.append("--force")
        }
        
        let result = try await executeProcess(command: command)
        return CallTool.Result(content: [.text("Uninstalling Swift \(version):\n\(result.output)")], isError: !result.success)
    }
}