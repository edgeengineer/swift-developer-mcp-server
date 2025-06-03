import Foundation
import MCP

// MARK: - Swiftly Tools

public struct SwiftlyInstallTool {
    public static let tool = Tool(
        name: "swiftly_install",
        description: "Install a Swift toolchain using swiftly"
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
        description: "List installed Swift toolchains"
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
        description: "List available Swift versions to install"
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
        description: "Switch to a specific Swift version"
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
        description: "Run a command with a specific Swift version"
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
        description: "Uninstall a Swift toolchain"
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