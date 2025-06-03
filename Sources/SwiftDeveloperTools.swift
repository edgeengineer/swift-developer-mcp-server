import Foundation
import MCP

// MARK: - Error Types

enum ToolError: Swift.Error {
    case invalidInput(String)
}

// MARK: - Debug Session Management

@MainActor
class DebugSessionManager {
    static let shared = DebugSessionManager()
    private var sessions: [String: DebugSession] = [:]
    
    private init() {}
    
    func createSession(id: String, target: String, projectPath: String, arguments: [String]) -> DebugSession {
        let session = DebugSession(id: id, target: target, projectPath: projectPath, arguments: arguments)
        sessions[id] = session
        return session
    }
    
    func getSession(id: String) -> DebugSession? {
        return sessions[id]
    }
    
    func removeSession(id: String) {
        sessions.removeValue(forKey: id)
    }
    
    func getAllSessions() -> [DebugSession] {
        return Array(sessions.values)
    }
}

class DebugSession: @unchecked Sendable {
    let id: String
    let target: String
    let projectPath: String
    let arguments: [String]
    var breakpoints: [Breakpoint] = []
    var process: Process?
    var isRunning: Bool = false
    
    init(id: String, target: String, projectPath: String, arguments: [String]) {
        self.id = id
        self.target = target
        self.projectPath = projectPath
        self.arguments = arguments
    }
    
    func addBreakpoint(_ breakpoint: Breakpoint) {
        breakpoints.append(breakpoint)
    }
}

struct Breakpoint: Sendable {
    let filePath: String
    let lineNumber: Int
    let condition: String?
}

// MARK: - Tools

struct SwiftBuildTool {
    static let tool = Tool(
        name: "swift_build",
        description: "Build your Swift project"
    )
    
    static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
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

struct SwiftTestTool {
    static let tool = Tool(
        name: "swift_test",
        description: "Run Swift tests"
    )
    
    static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
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

struct RunTargetTool {
    static let tool = Tool(
        name: "run_target",
        description: "Run a specific executable target"
    )
    
    static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
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

struct GetPackageInfoTool {
    static let tool = Tool(
        name: "get_package_info",
        description: "Get Swift package information"
    )
    
    static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
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

struct PrintDependencyPublicAPITool {
    static let tool = Tool(
        name: "print_dependency_public_api",
        description: "Print the public API of a dependency"
    )
    
    static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        guard let dependencyName = arguments["dependency_name"]?.stringValue else {
            throw ToolError.invalidInput("dependency_name is required")
        }
        
        let packagePath = arguments["package_path"]?.stringValue ?? FileManager.default.currentDirectoryPath
        let verbose = arguments["verbose"]?.boolValue ?? false
        
        // First, get package info to check if dependency exists
        let describeCommand = ["swift", "package", "describe", "--type", "json"]
        let describeResult = try await executeProcess(command: describeCommand, workingDirectory: packagePath)
        
        guard describeResult.success else {
            return CallTool.Result(content: [.text("Failed to get package information:\n\(describeResult.output)")], isError: true)
        }
        
        // Use swift-api-extract if available, or fall back to symbol dumping
        var command = ["swift", "package", "dump-symbol-graph"]
        
        if verbose {
            command.append("--verbose")
        }
        
        let result = try await executeProcess(command: command, workingDirectory: packagePath)
        
        if result.success {
            // Parse symbol graph output to extract API for specific dependency
            let apiInfo = parseSymbolGraphForDependency(result.output, dependencyName: dependencyName)
            return CallTool.Result(content: [.text("Public API for \(dependencyName):\n\(apiInfo)")])
        } else {
            // Fallback: try to use nm or objdump on built products
            let fallbackResult = try await extractAPIFallback(dependencyName: dependencyName, packagePath: packagePath)
            return CallTool.Result(content: [.text(fallbackResult)])
        }
    }
}

// MARK: - Debug Tools

struct DebugStartTool {
    static let tool = Tool(
        name: "debug_start",
        description: "Start a debugging session"
    )
    
    static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        guard let target = arguments["target"]?.stringValue else {
            throw ToolError.invalidInput("Target is required")
        }
        
        let projectPath = arguments["project_path"]?.stringValue ?? FileManager.default.currentDirectoryPath
        let targetArguments = arguments["arguments"]?.arrayValue?.compactMap { $0.stringValue } ?? []
        let sessionId = "debug_\(UUID().uuidString)"
        
        let session = await DebugSessionManager.shared.createSession(
            id: sessionId,
            target: target,
            projectPath: projectPath,
            arguments: targetArguments
        )
        
        let result = """
        Debug session started successfully.
        Session ID: \(sessionId)
        Target: \(target)
        Project Path: \(projectPath)
        Arguments: \(targetArguments.joined(separator: " "))
        
        Use debug_set_breakpoint to set breakpoints before continuing.
        Use debug_continue to start execution.
        """
        
        return CallTool.Result(content: [.text(result)])
    }
}

struct DebugSetBreakpointTool {
    static let tool = Tool(
        name: "debug_set_breakpoint",
        description: "Set a breakpoint"
    )
    
    static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        guard let filePath = arguments["file_path"]?.stringValue,
              let lineNumber = arguments["line_number"]?.intValue else {
            throw ToolError.invalidInput("file_path and line_number are required")
        }
        
        let sessionId = arguments["session_id"]?.stringValue ?? "default"
        let condition = arguments["condition"]?.stringValue
        
        guard let session = await DebugSessionManager.shared.getSession(id: sessionId) else {
            throw ToolError.invalidInput("Debug session not found: \(sessionId)")
        }
        
        let breakpoint = Breakpoint(filePath: filePath, lineNumber: lineNumber, condition: condition)
        session.addBreakpoint(breakpoint)
        
        let result = """
        Breakpoint set successfully.
        File: \(filePath)
        Line: \(lineNumber)
        \(condition != nil ? "Condition: \(condition!)" : "")
        Session: \(sessionId)
        """
        
        return CallTool.Result(content: [.text(result)])
    }
}

struct DebugStepTool {
    static let tool = Tool(
        name: "debug_step",
        description: "Step through code"
    )
    
    static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        guard let sessionId = arguments["session_id"]?.stringValue else {
            throw ToolError.invalidInput("session_id is required")
        }
        
        let stepType = arguments["step_type"]?.stringValue ?? "over"
        
        guard let session = await DebugSessionManager.shared.getSession(id: sessionId) else {
            throw ToolError.invalidInput("Debug session not found: \(sessionId)")
        }
        
        let result = """
        Debug step executed.
        Session: \(sessionId)
        Step Type: \(stepType)
        
        Note: This is a mock implementation. In a real debugger, this would step through the code.
        """
        
        return CallTool.Result(content: [.text(result)])
    }
}

struct DebugContinueTool {
    static let tool = Tool(
        name: "debug_continue",
        description: "Continue execution"
    )
    
    static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        guard let sessionId = arguments["session_id"]?.stringValue else {
            throw ToolError.invalidInput("session_id is required")
        }
        
        guard let session = await DebugSessionManager.shared.getSession(id: sessionId) else {
            throw ToolError.invalidInput("Debug session not found: \(sessionId)")
        }
        
        let result = """
        Debug execution continued.
        Session: \(sessionId)
        Target: \(session.target)
        
        Note: This is a mock implementation. In a real debugger, this would continue execution until the next breakpoint.
        """
        
        return CallTool.Result(content: [.text(result)])
    }
}

struct DebugInspectVariableTool {
    static let tool = Tool(
        name: "debug_inspect_variable",
        description: "Inspect variables"
    )
    
    static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        guard let sessionId = arguments["session_id"]?.stringValue else {
            throw ToolError.invalidInput("session_id is required")
        }
        
        let variableName = arguments["variable_name"]?.stringValue
        let expression = arguments["expression"]?.stringValue
        
        guard let session = await DebugSessionManager.shared.getSession(id: sessionId) else {
            throw ToolError.invalidInput("Debug session not found: \(sessionId)")
        }
        
        let target = variableName ?? expression ?? "local variables"
        
        let result = """
        Variable inspection results.
        Session: \(sessionId)
        Target: \(target)
        
        Note: This is a mock implementation. In a real debugger, this would show the actual variable values and types.
        """
        
        return CallTool.Result(content: [.text(result)])
    }
}

// MARK: - Swiftly Tools

struct SwiftlyInstallTool {
    static let tool = Tool(
        name: "swiftly_install",
        description: "Install a Swift toolchain using swiftly"
    )
    
    static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
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

struct SwiftlyListTool {
    static let tool = Tool(
        name: "swiftly_list",
        description: "List installed Swift toolchains"
    )
    
    static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
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

struct SwiftlyListAvailableTool {
    static let tool = Tool(
        name: "swiftly_list_available",
        description: "List available Swift versions to install"
    )
    
    static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
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

struct SwiftlyUseTool {
    static let tool = Tool(
        name: "swiftly_use",
        description: "Switch to a specific Swift version"
    )
    
    static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
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

struct SwiftlyRunTool {
    static let tool = Tool(
        name: "swiftly_run",
        description: "Run a command with a specific Swift version"
    )
    
    static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
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

struct SwiftlyUninstallTool {
    static let tool = Tool(
        name: "swiftly_uninstall",
        description: "Uninstall a Swift toolchain"
    )
    
    static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
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

// MARK: - Resources

struct SwiftProjectInfoResource {
    static let resource = Resource(
        name: "Swift Project Information",
        uri: "swift://project/info",
        description: "Current project information and structure",
        mimeType: "text/plain"
    )
    
    static func handle() async throws -> ReadResource.Result {
        let currentPath = FileManager.default.currentDirectoryPath
        let packageSwiftPath = "\(currentPath)/Package.swift"
        
        var content = "Swift Project Information\n"
        content += "========================\n\n"
        content += "Current Directory: \(currentPath)\n"
        
        if FileManager.default.fileExists(atPath: packageSwiftPath) {
            content += "Package.swift: Found\n"
            
            if let packageContent = try? String(contentsOfFile: packageSwiftPath) {
                content += "\nPackage.swift Contents:\n"
                content += "```swift\n"
                content += packageContent
                content += "\n```\n"
            }
        } else {
            content += "Package.swift: Not found\n"
        }
        
        // List source files
        let sourcesPath = "\(currentPath)/Sources"
        if FileManager.default.fileExists(atPath: sourcesPath) {
            content += "\nSource Files:\n"
            if let files = try? FileManager.default.contentsOfDirectory(atPath: sourcesPath) {
                for file in files.sorted() {
                    content += "  - \(file)\n"
                }
            }
        }
        
        return ReadResource.Result(contents: [.text(content, uri: "swift://project/info", mimeType: "text/plain")])
    }
}

struct SwiftBuildStatusResource {
    static let resource = Resource(
        name: "Build Status and History",
        uri: "swift://build/status",
        description: "Build status and history",
        mimeType: "text/plain"
    )
    
    static func handle() async throws -> ReadResource.Result {
        let currentPath = FileManager.default.currentDirectoryPath
        
        var content = "Swift Build Status\n"
        content += "==================\n\n"
        
        // Check if .build directory exists
        let buildPath = "\(currentPath)/.build"
        if FileManager.default.fileExists(atPath: buildPath) {
            content += "Build Directory: Exists\n"
            
            // List build artifacts
            if let buildContents = try? FileManager.default.contentsOfDirectory(atPath: buildPath) {
                content += "\nBuild Contents:\n"
                for item in buildContents.sorted() {
                    content += "  - \(item)\n"
                }
            }
        } else {
            content += "Build Directory: Not found (project not built yet)\n"
        }
        
        content += "\nTo build the project, use the swift_build tool.\n"
        
        return ReadResource.Result(contents: [.text(content, uri: "swift://build/status", mimeType: "text/plain")])
    }
}

struct SwiftDebugSessionsResource {
    static let resource = Resource(
        name: "Active Debug Sessions",
        uri: "swift://debug/sessions",
        description: "Active debug sessions and breakpoints",
        mimeType: "text/plain"
    )
    
    static func handle() async throws -> ReadResource.Result {
        var content = "Active Debug Sessions\n"
        content += "=====================\n\n"
        
        let sessions = await DebugSessionManager.shared.getAllSessions()
        
        if sessions.isEmpty {
            content += "No active debug sessions.\n"
            content += "Use the debug_start tool to create a new debug session.\n"
        } else {
            for session in sessions {
                content += "Session ID: \(session.id)\n"
                content += "Target: \(session.target)\n"
                content += "Project Path: \(session.projectPath)\n"
                content += "Arguments: \(session.arguments.joined(separator: " "))\n"
                content += "Running: \(session.isRunning)\n"
                
                if !session.breakpoints.isEmpty {
                    content += "Breakpoints:\n"
                    for breakpoint in session.breakpoints {
                        content += "  - \(breakpoint.filePath):\(breakpoint.lineNumber)"
                        if let condition = breakpoint.condition {
                            content += " (condition: \(condition))"
                        }
                        content += "\n"
                    }
                }
                content += "\n"
            }
        }
        
        return ReadResource.Result(contents: [.text(content, uri: "swift://debug/sessions", mimeType: "text/plain")])
    }
}

// MARK: - Prompts

struct SwiftDebugSessionPrompt {
    static let prompt = Prompt(
        name: "swift_debug_session",
        description: "Guided debugging session setup",
        arguments: [
            Prompt.Argument(name: "target", description: "Target to debug (required)", required: true),
            Prompt.Argument(name: "file", description: "Specific file to focus on (optional)", required: false)
        ]
    )
    
    static func handle(arguments: [String: Value]) async throws -> GetPrompt.Result {
        guard let target = arguments["target"]?.stringValue else {
            throw ToolError.invalidInput("Target is required")
        }
        
        let file = arguments["file"]?.stringValue
        
        var prompt = """
        # Swift Debugging Session Setup
        
        You are helping set up a debugging session for the Swift target: **\(target)**
        """
        
        if let file = file {
            prompt += "\nFocusing on file: **\(file)**"
        }
        
        prompt += """
        
        ## Suggested Steps:
        
        1. **Start Debug Session**
           Use debug_start tool with target: \(target)
        
        2. **Set Breakpoints**
           Use debug_set_breakpoint tool to set breakpoints in key locations
        """
        
        if let file = file {
            prompt += """
           
           Consider setting breakpoints in \(file) at:
           - Function entry points
           - Error handling code
           - Key logic branches
           """
        }
        
        prompt += """
        
        3. **Continue Execution**
           Use debug_continue to start execution until first breakpoint
        
        4. **Inspect Variables**
           Use debug_inspect_variable to examine variable values
        
        5. **Step Through Code**
           Use debug_step with different step types (over, into, out)
        
        ## Debugging Tips:
        
        - Set breakpoints at the beginning of functions you want to examine
        - Use conditional breakpoints for loops or frequently called functions
        - Inspect variables at each breakpoint to understand program state
        - Step through code line by line to understand execution flow
        
        What would you like to debug specifically in this target?
        """
        
        return GetPrompt.Result(
            description: "Swift debugging session setup guide",
            messages: [.user(.text(text: prompt))]
        )
    }
}

struct SwiftBuildAnalysisPrompt {
    static let prompt = Prompt(
        name: "swift_build_analysis",
        description: "Build error analysis and solutions",
        arguments: [
            Prompt.Argument(name: "error_log", description: "Build error output to analyze (required)", required: true)
        ]
    )
    
    static func handle(arguments: [String: Value]) async throws -> GetPrompt.Result {
        guard let errorLog = arguments["error_log"]?.stringValue else {
            throw ToolError.invalidInput("Error log is required")
        }
        
        var analysis = """
        # Swift Build Error Analysis
        
        ## Error Log:
        ```
        \(errorLog)
        ```
        
        ## Analysis:
        
        """
        
        // Simple error pattern matching
        if errorLog.contains("error:") {
            analysis += "### Compilation Errors Found\n\n"
            
            if errorLog.contains("cannot find") || errorLog.contains("unresolved identifier") {
                analysis += """
                **Possible Issues:**
                - Missing import statements
                - Typos in variable or function names
                - Missing dependencies in Package.swift
                
                **Suggested Actions:**
                1. Check spelling of identifiers
                2. Verify import statements
                3. Check Package.swift dependencies
                
                """
            }
            
            if errorLog.contains("type") && errorLog.contains("does not conform") {
                analysis += """
                **Type Conformance Issues:**
                - Missing protocol implementations
                - Incorrect type annotations
                
                **Suggested Actions:**
                1. Implement required protocol methods
                2. Check type annotations
                3. Review protocol requirements
                
                """
            }
        }
        
        analysis += """
        ## Recommended Next Steps:
        
        1. **Fix Critical Errors First**
           Address compilation errors before warnings
        
        2. **Use Swift Build Tool**
           swift_build with verbose: true for detailed output
        
        3. **Test Changes**
           swift_test after fixing errors
        
        4. **Check Package Dependencies**
           get_package_info to verify project structure
        
        Would you like me to help fix any specific errors from this log?
        """
        
        return GetPrompt.Result(
            description: "Swift build error analysis and recommendations",
            messages: [.user(.text(text: analysis))]
        )
    }
}

// MARK: - Helper Functions

struct ProcessResult {
    let output: String
    let success: Bool
    let exitCode: Int32
}

func executeProcess(command: [String], workingDirectory: String? = nil) async throws -> ProcessResult {
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

func parseSymbolGraphForDependency(_ symbolGraph: String, dependencyName: String) -> String {
    // Simple parsing - in a real implementation, you'd parse the JSON symbol graph
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

func extractAPIFallback(dependencyName: String, packagePath: String) async throws -> String {
    // Try to build first to ensure dependencies are available
    let buildCommand = ["swift", "build"]
    let buildResult = try await executeProcess(command: buildCommand, workingDirectory: packagePath)
    
    if !buildResult.success {
        return "Failed to build project for API extraction:\n\(buildResult.output)"
    }
    
    // Look for built products
    let buildPath = "\(packagePath)/.build"
    
    guard FileManager.default.fileExists(atPath: buildPath) else {
        return "No build directory found. Please build the project first."
    }
    
    // Try to find the dependency in the build products
    var result = "API extraction fallback for \(dependencyName):\n"
    result += "Build completed successfully, but detailed API extraction requires additional tooling.\n"
    result += "Consider using swift-api-extract or DocC for comprehensive API documentation.\n"
    result += "\nTo extract API manually:\n"
    result += "1. swift package generate-documentation\n"
    result += "2. swift package dump-symbol-graph\n"
    result += "3. Use swift-api-extract tool if available\n"
    
    return result
}