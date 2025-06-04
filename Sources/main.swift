import Foundation
import MCP

func main() async throws {
        let server = Server(
            name: "SwiftDeveloperMCPServer",
            version: "1.0.0",
            capabilities: Server.Capabilities(
                prompts: Server.Capabilities.Prompts(listChanged: true),
                resources: Server.Capabilities.Resources(subscribe: true, listChanged: true),
                tools: Server.Capabilities.Tools(listChanged: true)
            )
        )

        // Tools
        await server.withMethodHandler(ListTools.self) { _ in
            ListTools.Result(tools: [
                SwiftBuildTool.tool,
                SwiftTestTool.tool,
                RunTargetTool.tool,
                DebugStartTool.tool,
                DebugSetBreakpointTool.tool,
                DebugStepTool.tool,
                DebugContinueTool.tool,
                DebugInspectVariableTool.tool,
                DebugTerminateTool.tool,
                GetPackageInfoTool.tool,
                PrintDependencyPublicAPITool.tool,
                SwiftlyInstallTool.tool,
                SwiftlyListTool.tool,
                SwiftlyListAvailableTool.tool,
                SwiftlyUseTool.tool,
                SwiftlyRunTool.tool,
                SwiftlyUninstallTool.tool
            ])
        }

        await server.withMethodHandler(CallTool.self) { params in
            let name = params.name
            let arguments = params.arguments ?? [:]
            
            switch name {
            case "swift_build": return try await SwiftBuildTool.handle(arguments: arguments)
            case "swift_test": return try await SwiftTestTool.handle(arguments: arguments)
            case "run_target": return try await RunTargetTool.handle(arguments: arguments)
            case "debug_start": return try await DebugStartTool.handle(arguments: arguments)
            case "debug_set_breakpoint": return try await DebugSetBreakpointTool.handle(arguments: arguments)
            case "debug_step": return try await DebugStepTool.handle(arguments: arguments)
            case "debug_continue": return try await DebugContinueTool.handle(arguments: arguments)
            case "debug_inspect_variable": return try await DebugInspectVariableTool.handle(arguments: arguments)
            case "debug_terminate": return try await DebugTerminateTool.handle(arguments: arguments)
            case "get_package_info": return try await GetPackageInfoTool.handle(arguments: arguments)
            case "print_dependency_public_api": return try await PrintDependencyPublicAPITool.handle(arguments: arguments)
            case "swiftly_install": return try await SwiftlyInstallTool.handle(arguments: arguments)
            case "swiftly_list": return try await SwiftlyListTool.handle(arguments: arguments)
            case "swiftly_list_available": return try await SwiftlyListAvailableTool.handle(arguments: arguments)
            case "swiftly_use": return try await SwiftlyUseTool.handle(arguments: arguments)
            case "swiftly_run": return try await SwiftlyRunTool.handle(arguments: arguments)
            case "swiftly_uninstall": return try await SwiftlyUninstallTool.handle(arguments: arguments)
            default:
                throw MCPError.methodNotFound("Unknown tool: \(name)")
            }
        }

        // Resources
        await server.withMethodHandler(ListResources.self) { _ in
            ListResources.Result(resources: [
                SwiftProjectInfoResource.resource,
                SwiftBuildStatusResource.resource,
                SwiftDebugSessionsResource.resource
            ])
        }

        await server.withMethodHandler(ReadResource.self) { params in
            let uri = params.uri
            
            switch uri {
            case "swift://project/info": return try await SwiftProjectInfoResource.handle()
            case "swift://build/status": return try await SwiftBuildStatusResource.handle()
            case "swift://debug/sessions": return try await SwiftDebugSessionsResource.handle()
            default:
                throw MCPError.invalidRequest("Unknown resource: \(uri)")
            }
        }

        // Prompts
        await server.withMethodHandler(ListPrompts.self) { _ in
            ListPrompts.Result(prompts: [
                SwiftDebugSessionPrompt.prompt,
                SwiftBuildAnalysisPrompt.prompt
            ])
        }

        await server.withMethodHandler(GetPrompt.self) { params in
            let name = params.name
            let arguments = params.arguments ?? [:]
            
            switch name {
            case "swift_debug_session": return try await SwiftDebugSessionPrompt.handle(arguments: arguments)
            case "swift_build_analysis": return try await SwiftBuildAnalysisPrompt.handle(arguments: arguments)
            default:
                throw MCPError.methodNotFound("Unknown prompt: \(name)")
            }
        }

        let transport = StdioTransport()
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
}

try await main()