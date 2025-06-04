import Foundation
import MCP

// MARK: - Debug Session Management

@MainActor
public class DebugSessionManager {
    public static let shared = DebugSessionManager()
    private var sessions: [String: DebugSession] = [:]
    
    private init() {}
    
    public func createSession(id: String, target: String, projectPath: String, arguments: [String]) -> DebugSession {
        let session = DebugSession(id: id, target: target, projectPath: projectPath, arguments: arguments)
        sessions[id] = session
        return session
    }
    
    public func getSession(id: String) -> DebugSession? {
        return sessions[id]
    }
    
    public func removeSession(id: String) {
        sessions.removeValue(forKey: id)
    }
    
    public func getAllSessions() -> [DebugSession] {
        return Array(sessions.values)
    }
}

public class DebugSession: @unchecked Sendable {
    public let id: String
    public let target: String
    public let projectPath: String
    public let arguments: [String]
    public var breakpoints: [Breakpoint] = []
    public var lldbProcess: Process?
    public var lldbInput: Pipe?
    public var lldbOutput: Pipe?
    public var isRunning: Bool = false
    public var targetExecutable: String?
    
    public init(id: String, target: String, projectPath: String, arguments: [String]) {
        self.id = id
        self.target = target
        self.projectPath = projectPath
        self.arguments = arguments
    }
    
    public func addBreakpoint(_ breakpoint: Breakpoint) {
        breakpoints.append(breakpoint)
    }
    
    public func startLLDB() throws {
        let process = Process()
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/lldb")
        process.arguments = []
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        
        try process.run()
        
        self.lldbProcess = process
        self.lldbInput = inputPipe
        self.lldbOutput = outputPipe
        
        // Wait for LLDB to start up
        Thread.sleep(forTimeInterval: 0.5)
    }
    
    public func sendLLDBCommand(_ command: String) throws -> String {
        guard let inputPipe = lldbInput else {
            throw ToolError.processingError("LLDB not started")
        }
        
        let commandData = "\(command)\n".data(using: .utf8)!
        inputPipe.fileHandleForWriting.write(commandData)
        
        // Give LLDB time to process
        Thread.sleep(forTimeInterval: 0.3)
        
        // Read available output
        guard let outputPipe = lldbOutput else {
            throw ToolError.processingError("LLDB output not available")
        }
        
        let availableData = outputPipe.fileHandleForReading.availableData
        let output = String(data: availableData, encoding: .utf8) ?? ""
        
        // Filter out LLDB prompt and clean up output
        let lines = output.components(separatedBy: .newlines)
        let filteredLines = lines.filter { line in
            !line.hasPrefix("(lldb)") && 
            !line.trimmingCharacters(in: .whitespaces).isEmpty
        }
        
        return filteredLines.joined(separator: "\n")
    }
    
    public func terminate() {
        // Send quit command to LLDB gracefully
        if let inputPipe = lldbInput {
            let quitData = "quit\n".data(using: .utf8)!
            inputPipe.fileHandleForWriting.write(quitData)
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        lldbProcess?.terminate()
        lldbProcess = nil
        lldbInput = nil
        lldbOutput = nil
        isRunning = false
    }
}

public struct Breakpoint: Sendable {
    public let filePath: String
    public let lineNumber: Int
    public let condition: String?
    
    public init(filePath: String, lineNumber: Int, condition: String? = nil) {
        self.filePath = filePath
        self.lineNumber = lineNumber
        self.condition = condition
    }
}

// MARK: - Debug Tools

public struct DebugStartTool {
    public static let tool = Tool(
        name: "debug_start",
        description: "Start a debugging session",
        inputSchema: [
            "type": "object",
            "properties": [
                "target": [
                    "type": "string",
                    "description": "Target to debug (required)"
                ],
                "project_path": [
                    "type": "string",
                    "description": "Path to the Swift project (optional)"
                ],
                "arguments": [
                    "type": "array",
                    "items": ["type": "string"],
                    "description": "Arguments to pass to the target"
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
        let sessionId = "debug_\(UUID().uuidString)"
        
        let session = await DebugSessionManager.shared.createSession(
            id: sessionId,
            target: target,
            projectPath: projectPath,
            arguments: targetArguments
        )
        
        // Build the target first
        let buildProcess = Process()
        buildProcess.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        buildProcess.arguments = ["build", "--target", target]
        buildProcess.currentDirectoryURL = URL(fileURLWithPath: projectPath)
        
        let buildOutput = Pipe()
        buildProcess.standardOutput = buildOutput
        buildProcess.standardError = buildOutput
        
        do {
            try buildProcess.run()
            buildProcess.waitUntilExit()
            
            if buildProcess.terminationStatus != 0 {
                let errorData = buildOutput.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown build error"
                throw ToolError.processingError("Build failed: \(errorMessage)")
            }
            
            // Start LLDB session
            try session.startLLDB()
            
            // Set up the target in LLDB
            let executablePath = "\(projectPath)/.build/debug/\(target)"
            session.targetExecutable = executablePath
            
            _ = try session.sendLLDBCommand("target create \(executablePath)")
            
            if !targetArguments.isEmpty {
                let argsString = targetArguments.map { "\"\($0)\"" }.joined(separator: " ")
                _ = try session.sendLLDBCommand("settings set target.run-args \(argsString)")
            }
            
            let result = """
            Debug session started successfully.
            Session ID: \(sessionId)
            Target: \(target)
            Executable: \(executablePath)
            Project Path: \(projectPath)
            Arguments: \(targetArguments.joined(separator: " "))
            
            Use debug_set_breakpoint to set breakpoints before continuing.
            Use debug_continue to start execution.
            """
            
            return CallTool.Result(content: [.text(result)])
            
        } catch {
            await DebugSessionManager.shared.removeSession(id: sessionId)
            throw ToolError.processingError("Failed to start debug session: \(error.localizedDescription)")
        }
    }
}

public struct DebugSetBreakpointTool {
    public static let tool = Tool(
        name: "debug_set_breakpoint",
        description: "Set a breakpoint",
        inputSchema: [
            "type": "object",
            "properties": [
                "file_path": [
                    "type": "string",
                    "description": "Path to the Swift file (required)"
                ],
                "line_number": [
                    "type": "integer",
                    "description": "Line number for the breakpoint (required)"
                ],
                "condition": [
                    "type": "string",
                    "description": "Optional condition for the breakpoint"
                ],
                "session_id": [
                    "type": "string",
                    "description": "Debug session ID (optional, uses 'default' if not provided)"
                ]
            ],
            "required": ["file_path", "line_number"]
        ]
    )
    
    public static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        guard let filePath = arguments["file_path"]?.stringValue,
              let lineNumber = arguments["line_number"]?.intValue else {
            throw ToolError.invalidInput("file_path and line_number are required")
        }
        
        let sessionId = arguments["session_id"]?.stringValue ?? "default"
        let condition = arguments["condition"]?.stringValue
        
        guard let session = await DebugSessionManager.shared.getSession(id: sessionId) else {
            throw ToolError.invalidInput("Debug session not found: \(sessionId)")
        }
        
        do {
            // Set breakpoint in LLDB
            let breakpointCommand = "breakpoint set --file \(filePath) --line \(lineNumber)"
            let lldbOutput = try session.sendLLDBCommand(breakpointCommand)
            
            // If there's a condition, add it
            if let condition = condition {
                let conditionCommand = "breakpoint modify --condition '\(condition)' -1"
                _ = try session.sendLLDBCommand(conditionCommand)
            }
            
            let breakpoint = Breakpoint(filePath: filePath, lineNumber: lineNumber, condition: condition)
            session.addBreakpoint(breakpoint)
            
            let result = """
            Breakpoint set successfully.
            File: \(filePath)
            Line: \(lineNumber)
            \(condition != nil ? "Condition: \(condition!)" : "")
            Session: \(sessionId)
            
            LLDB Output:
            \(lldbOutput)
            """
            
            return CallTool.Result(content: [.text(result)])
            
        } catch {
            throw ToolError.processingError("Failed to set breakpoint: \(error.localizedDescription)")
        }
    }
}

public struct DebugStepTool {
    public static let tool = Tool(
        name: "debug_step",
        description: "Step through code",
        inputSchema: [
            "type": "object",
            "properties": [
                "session_id": [
                    "type": "string",
                    "description": "Debug session ID (required)"
                ],
                "step_type": [
                    "type": "string",
                    "enum": ["over", "into", "out"],
                    "description": "Type of step",
                    "default": "over"
                ]
            ],
            "required": ["session_id"]
        ]
    )
    
    public static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        guard let sessionId = arguments["session_id"]?.stringValue else {
            throw ToolError.invalidInput("session_id is required")
        }
        
        let stepType = arguments["step_type"]?.stringValue ?? "over"
        
        guard let session = await DebugSessionManager.shared.getSession(id: sessionId) else {
            throw ToolError.invalidInput("Debug session not found: \(sessionId)")
        }
        
        do {
            let stepCommand: String
            switch stepType {
            case "over":
                stepCommand = "next"
            case "into":
                stepCommand = "step"
            case "out":
                stepCommand = "finish"
            default:
                stepCommand = "next"
            }
            
            let lldbOutput = try session.sendLLDBCommand(stepCommand)
            
            let result = """
            Debug step executed.
            Session: \(sessionId)
            Step Type: \(stepType)
            Command: \(stepCommand)
            
            LLDB Output:
            \(lldbOutput)
            """
            
            return CallTool.Result(content: [.text(result)])
            
        } catch {
            throw ToolError.processingError("Failed to execute step: \(error.localizedDescription)")
        }
    }
}

public struct DebugContinueTool {
    public static let tool = Tool(
        name: "debug_continue",
        description: "Continue execution",
        inputSchema: [
            "type": "object",
            "properties": [
                "session_id": [
                    "type": "string",
                    "description": "Debug session ID (required)"
                ]
            ],
            "required": ["session_id"]
        ]
    )
    
    public static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        guard let sessionId = arguments["session_id"]?.stringValue else {
            throw ToolError.invalidInput("session_id is required")
        }
        
        guard let session = await DebugSessionManager.shared.getSession(id: sessionId) else {
            throw ToolError.invalidInput("Debug session not found: \(sessionId)")
        }
        
        do {
            let continueCommand: String
            if !session.isRunning {
                // If not running, start the process
                continueCommand = "process launch"
                session.isRunning = true
            } else {
                // If already running, continue execution
                continueCommand = "continue"
            }
            
            let lldbOutput = try session.sendLLDBCommand(continueCommand)
            
            let result = """
            Debug execution continued.
            Session: \(sessionId)
            Target: \(session.target)
            Command: \(continueCommand)
            Running: \(session.isRunning)
            
            LLDB Output:
            \(lldbOutput)
            """
            
            return CallTool.Result(content: [.text(result)])
            
        } catch {
            throw ToolError.processingError("Failed to continue execution: \(error.localizedDescription)")
        }
    }
}

public struct DebugInspectVariableTool {
    public static let tool = Tool(
        name: "debug_inspect_variable",
        description: "Inspect variables",
        inputSchema: [
            "type": "object",
            "properties": [
                "session_id": [
                    "type": "string",
                    "description": "Debug session ID (required)"
                ],
                "variable_name": [
                    "type": "string",
                    "description": "Name of the variable to inspect (optional)"
                ],
                "expression": [
                    "type": "string",
                    "description": "Expression to evaluate (optional)"
                ]
            ],
            "required": ["session_id"]
        ]
    )
    
    public static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        guard let sessionId = arguments["session_id"]?.stringValue else {
            throw ToolError.invalidInput("session_id is required")
        }
        
        let variableName = arguments["variable_name"]?.stringValue
        let expression = arguments["expression"]?.stringValue
        
        guard let session = await DebugSessionManager.shared.getSession(id: sessionId) else {
            throw ToolError.invalidInput("Debug session not found: \(sessionId)")
        }
        
        do {
            let lldbOutput: String
            
            if let expression = expression {
                // Evaluate an expression
                let command = "expression \(expression)"
                lldbOutput = try session.sendLLDBCommand(command)
            } else if let variableName = variableName {
                // Print a specific variable
                let command = "frame variable \(variableName)"
                lldbOutput = try session.sendLLDBCommand(command)
            } else {
                // Show all local variables
                let command = "frame variable"
                lldbOutput = try session.sendLLDBCommand(command)
            }
            
            let target = variableName ?? expression ?? "all local variables"
            
            let result = """
            Variable inspection results.
            Session: \(sessionId)
            Target: \(target)
            
            LLDB Output:
            \(lldbOutput)
            """
            
            return CallTool.Result(content: [.text(result)])
            
        } catch {
            throw ToolError.processingError("Failed to inspect variables: \(error.localizedDescription)")
        }
    }
}

public struct DebugTerminateTool {
    public static let tool = Tool(
        name: "debug_terminate",
        description: "Terminate a debugging session",
        inputSchema: [
            "type": "object",
            "properties": [
                "session_id": [
                    "type": "string",
                    "description": "Debug session ID (required)"
                ]
            ],
            "required": ["session_id"]
        ]
    )
    
    public static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
        guard let sessionId = arguments["session_id"]?.stringValue else {
            throw ToolError.invalidInput("session_id is required")
        }
        
        guard let session = await DebugSessionManager.shared.getSession(id: sessionId) else {
            throw ToolError.invalidInput("Debug session not found: \(sessionId)")
        }
        
        session.terminate()
        await DebugSessionManager.shared.removeSession(id: sessionId)
        
        let result = """
        Debug session terminated.
        Session ID: \(sessionId)
        Target: \(session.target)
        """
        
        return CallTool.Result(content: [.text(result)])
    }
}