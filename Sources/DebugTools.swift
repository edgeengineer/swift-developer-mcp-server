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
    public var process: Process?
    public var isRunning: Bool = false
    
    public init(id: String, target: String, projectPath: String, arguments: [String]) {
        self.id = id
        self.target = target
        self.projectPath = projectPath
        self.arguments = arguments
    }
    
    public func addBreakpoint(_ breakpoint: Breakpoint) {
        breakpoints.append(breakpoint)
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
        description: "Start a debugging session"
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

public struct DebugSetBreakpointTool {
    public static let tool = Tool(
        name: "debug_set_breakpoint",
        description: "Set a breakpoint"
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

public struct DebugStepTool {
    public static let tool = Tool(
        name: "debug_step",
        description: "Step through code"
    )
    
    public static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
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

public struct DebugContinueTool {
    public static let tool = Tool(
        name: "debug_continue",
        description: "Continue execution"
    )
    
    public static func handle(arguments: [String: Value]) async throws -> CallTool.Result {
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

public struct DebugInspectVariableTool {
    public static let tool = Tool(
        name: "debug_inspect_variable",
        description: "Inspect variables"
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