import Foundation
import MCP

// MARK: - Prompts

public struct SwiftDebugSessionPrompt {
    public static let prompt = Prompt(
        name: "swift_debug_session",
        description: "Guided debugging session setup",
        arguments: [
            Prompt.Argument(name: "target", description: "Target to debug (required)", required: true),
            Prompt.Argument(name: "file", description: "Specific file to focus on (optional)", required: false)
        ]
    )
    
    public static func handle(arguments: [String: Value]) async throws -> GetPrompt.Result {
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

public struct SwiftBuildAnalysisPrompt {
    public static let prompt = Prompt(
        name: "swift_build_analysis",
        description: "Build error analysis and solutions",
        arguments: [
            Prompt.Argument(name: "error_log", description: "Build error output to analyze (required)", required: true)
        ]
    )
    
    public static func handle(arguments: [String: Value]) async throws -> GetPrompt.Result {
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