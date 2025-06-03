import Foundation
import MCP

// MARK: - Resources

public struct SwiftProjectInfoResource {
    public static let resource = Resource(
        name: "Swift Project Information",
        uri: "swift://project/info",
        description: "Current project information and structure",
        mimeType: "text/plain"
    )
    
    public static func handle() async throws -> ReadResource.Result {
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

public struct SwiftBuildStatusResource {
    public static let resource = Resource(
        name: "Build Status and History",
        uri: "swift://build/status",
        description: "Build status and history",
        mimeType: "text/plain"
    )
    
    public static func handle() async throws -> ReadResource.Result {
        let currentPath = FileManager.default.currentDirectoryPath
        
        var content = "Swift Build Status\n"
        content += "==================\n\n"
        
        let buildPath = "\(currentPath)/.build"
        if FileManager.default.fileExists(atPath: buildPath) {
            content += "Build Directory: Exists\n"
            
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

public struct SwiftDebugSessionsResource {
    public static let resource = Resource(
        name: "Active Debug Sessions",
        uri: "swift://debug/sessions",
        description: "Active debug sessions and breakpoints",
        mimeType: "text/plain"
    )
    
    public static func handle() async throws -> ReadResource.Result {
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