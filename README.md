# Swift Developer MCP Server

A comprehensive Model Context Protocol (MCP) server that provides Swift development tools, debugging capabilities, and project management features for macOS and Linux environments. This server enables AI assistants to interact with Swift projects, build systems, and development tools.

## Features

### 🔨 Build & Test Tools
- **`swift_build`** - Build Swift projects with configuration options (debug/release, specific targets, verbose output)
- **`swift_test`** - Run Swift tests with filtering, parallel execution control, and verbose output
- **`run_target`** - Execute specific Swift targets with custom arguments

### 🐛 Debugging Tools
- **`debug_start`** - Start debugging sessions for Swift targets
- **`debug_set_breakpoint`** - Set breakpoints with optional conditions
- **`debug_step`** - Step through code (over, into, out)
- **`debug_continue`** - Continue execution until next breakpoint
- **`debug_inspect_variable`** - Inspect variables and evaluate expressions

### 📦 Swift Package Management
- **`get_package_info`** - Get comprehensive Swift package information and dependencies
- **`print_dependency_public_api`** - Extract and display the public API of any dependency

### 🔧 Swiftly Toolchain Management
- **`swiftly_install`** - Install Swift toolchains from different channels
- **`swiftly_list`** - List installed Swift toolchains
- **`swiftly_list_available`** - List available Swift versions to install
- **`swiftly_use`** - Switch between Swift versions globally or per-project
- **`swiftly_run`** - Run commands with specific Swift versions
- **`swiftly_uninstall`** - Remove Swift toolchains

### 📊 Resources
- **`swift://project/info`** - Current project information and structure
- **`swift://build/status`** - Build status and history
- **`swift://debug/sessions`** - Active debug sessions and breakpoints

### 💡 Prompts
- **`swift_debug_session`** - Guided debugging session setup with target-specific recommendations
- **`swift_build_analysis`** - Intelligent build error analysis and solution suggestions

## Installation

### Prerequisites

1. **Swift**: Install Swift 5.9+ or use [Swiftly](https://github.com/swift-server/swiftly) for version management
2. **macOS or Linux**: This server supports both macOS and Linux environments
3. **Make**: For using the convenient build targets

### Quick Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/edgeengineer/swift-developer-mcp-server.git
   cd swift-developer-mcp-server
   ```

2. **Build and get path** (copies to clipboard automatically):
   ```bash
   make path
   ```

   This will:
   - ✅ Build the server in release mode
   - ✅ Show the executable path
   - ✅ Copy the path to your clipboard
   - ✅ Display configuration examples for popular AI clients

### Other Make Targets

```bash
make build    # Build the server in release mode
make clean    # Clean build artifacts
make install  # Install to /usr/local/bin
make help     # Show all available targets
```

## Configuration for AI Clients

### Cursor

Add to your Cursor settings (`.cursor-settings/settings.json`):

```json
{
  "mcp": {
    "servers": {
      "swift-developer": {
        "command": "PASTE_PATH_FROM_CLIPBOARD_HERE",
        "args": [],
        "env": {}
      }
    }
  }
}
```

### Windsurf

Add to your Windsurf configuration (`.windsurf/mcp_servers.json`):

```json
{
  "servers": {
    "swift-developer": {
      "command": "PASTE_PATH_FROM_CLIPBOARD_HERE",
      "args": [],
      "env": {}
    }
  }
}
```

### Claude Desktop

Add to your Claude Desktop configuration:
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "swift-developer": {
      "command": "PASTE_PATH_FROM_CLIPBOARD_HERE",
      "args": [],
      "env": {}
    }
  }
}
```

### Claude Code (Terminal Application)

Add to your Claude Code configuration (in the terminal application):

```
claude mcp add swift-developer PASTE_PATH_FROM_CLIPBOARD_HERE
``` 

### Claude Code (VS Code Extension)

Add to your VS Code settings (`.vscode/settings.json`):

```json
{
  "claude-dev.mcpServers": {
    "swift-developer": {
      "command": "PASTE_PATH_FROM_CLIPBOARD_HERE",
      "args": [],
      "env": {}
    }
  }
}
```

> 💡 **Pro Tip**: Run `make path` to get ready-to-copy configuration examples for each client!

## Usage Examples

### Building a Swift Project

```
Use the swift_build tool to build the current project in release mode with verbose output.
```

### Running Tests

```
Use the swift_test tool to run all tests in parallel with verbose output.
```

### Starting a Debug Session

```
Use the swift_debug_session prompt to set up debugging for the "MyApp" target, focusing on the "ViewController.swift" file.
```

### Managing Swift Versions

```
Use swiftly_list to see installed Swift versions, then swiftly_use to switch to Swift 5.9.
```

### Extracting Dependency APIs

```
Use print_dependency_public_api with dependency_name "Alamofire" to see the public API of the Alamofire dependency.
```

### Getting Project Information

```
Access the swift://project/info resource to see the current project structure and Package.swift contents.
```

## Development

### Project Structure

```
swift-developer-mcp-server/
├── Package.swift                 # Swift Package Manager configuration
├── Makefile                     # Build automation and convenience targets
├── Sources/
│   ├── main.swift               # Server entry point and MCP handler setup
│   ├── Utilities.swift          # Common types and helper functions
│   ├── BuildTestTools.swift     # Swift build and test tools
│   ├── DebugTools.swift         # Debug session management and tools
│   ├── PackageInfoTools.swift   # Swift package information tools
│   ├── SwiftlyTools.swift       # Swiftly toolchain management
│   ├── Resources.swift          # MCP resources (project info, build status, etc.)
│   └── Prompts.swift            # MCP prompts (debug session, build analysis)
└── README.md                    # This file
```

### Adding New Tools

1. Define the tool struct in the appropriate module file:
   - `BuildTestTools.swift` for build and test functionality
   - `DebugTools.swift` for debugging features
   - `PackageInfoTools.swift` for package management
   - `SwiftlyTools.swift` for toolchain management
   - Create a new module if needed for other categories
2. Add the tool to the `ListTools` handler in `main.swift`
3. Add the tool's handle method to the `CallTool` switch statement
4. Rebuild the server

### Testing

You can test the server manually by running it and sending JSON-RPC messages:

```bash
swift run SwiftDeveloperMCPServer
```

Then send initialization and tool call messages via stdin.

## Requirements

- **macOS 13.0+** or **Linux** (Ubuntu 20.04+, other distributions with Swift support)
- **Swift 5.9+**
- **Make** (for build targets)
- **Xcode Command Line Tools** (macOS only)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the Apache 2.0 License. See the LICENSE file for details.

## Troubleshooting

### Common Issues

1. **"Command not found"**: 
   - Run `make path` to rebuild and get the correct path
   - Ensure the path in your AI client configuration matches the output

2. **"Permission denied"**: Make sure the executable has proper permissions:
   ```bash
   chmod +x .build/release/SwiftDeveloperMCPServer
   # Or simply run 'make path' which handles this automatically
   ```

3. **Swift version conflicts**: Use `swiftly` to manage Swift versions if you have multiple installations.

4. **Build failures**: 
   - Ensure you have the latest Xcode Command Line Tools (macOS):
     ```bash
     xcode-select --install
     ```
   - The `make path` command will show detailed build errors if they occur

5. **Configuration issues**: The `make path` command provides ready-to-copy configuration examples for all supported AI clients.

### Debugging the Server

To debug the server itself, you can add logging to the `main.swift` file or run it with verbose Swift output:

```bash
swift run -v SwiftDeveloperMCPServer
```

## Testing with ExampleLib

The repository includes `ExampleLib/`, a complete Swift package with async Fibonacci calculations, perfect for testing the MCP server's debugging capabilities.

### Building and Running ExampleLib

Navigate to the ExampleLib directory and use standard Swift commands:

```bash
cd ExampleLib

# Build the library and executable
swift build

# Run the demo application
swift run ExampleApp

# Run tests
swift test
```

### Testing with MCP Server Debug Tools

The ExampleLib project provides an excellent testing ground for the MCP server's debugging functionality. Here's how to test the complete debugging workflow:

#### 1. Basic Build and Test

Use the MCP server tools to build and test:

```
Use swift_build tool with:
- target: "ExampleApp" 
- project_path: "/path/to/swift-developer-mcp-server/ExampleLib"
- configuration: "debug"
- verbose: true

Use swift_test tool with:
- project_path: "/path/to/swift-developer-mcp-server/ExampleLib"
- verbose: true
```

#### 2. Debug Session Setup

Start a debugging session for the ExampleApp:

```
Use debug_start tool with:
- target: "ExampleApp"
- project_path: "/path/to/swift-developer-mcp-server/ExampleLib"
- arguments: [] (optional)
```

This will:
- Build the ExampleApp target
- Start an LLDB session
- Load the executable for debugging

#### 3. Setting Breakpoints

Set strategic breakpoints to inspect the Fibonacci calculation:

```
Use debug_set_breakpoint tool with:
- file_path: "/path/to/ExampleLib/Sources/ExampleApp/main.swift"
- line_number: 89 (in performanceTest function)
- session_id: "your_session_id"

Use debug_set_breakpoint tool with:
- file_path: "/path/to/ExampleLib/Sources/ExampleLib/FibonacciCalculator.swift" 
- line_number: 37 (inside calculate method)
- session_id: "your_session_id"
```

#### 4. Running and Stepping Through Code

```
# Start execution
Use debug_continue tool with:
- session_id: "your_session_id"

# Step through code when breakpoint hits
Use debug_step tool with:
- session_id: "your_session_id"
- step_type: "over" (or "into", "out")
```

#### 5. Inspecting Variables and Actor State

The FibonacciCalculator is an actor, making it perfect for testing async debugging:

```
# Inspect the calculator actor
Use debug_inspect_variable tool with:
- session_id: "your_session_id"
- variable_name: "calculator"

# Inspect specific values
Use debug_inspect_variable tool with:
- session_id: "your_session_id"
- variable_name: "result"

# Evaluate expressions
Use debug_inspect_variable tool with:
- session_id: "your_session_id"
- expression: "await calculator.getCalculationCount()"
```

#### 6. Testing Concurrent Operations

The ExampleLib includes concurrent Fibonacci calculations that are excellent for testing debugging of async operations:

```
# Set breakpoint in concurrent calculation method
Use debug_set_breakpoint tool with:
- file_path: "/path/to/ExampleLib/Sources/ExampleLib/FibonacciCalculator.swift"
- line_number: 57 (in calculateMultiple method)
- session_id: "your_session_id"

# Inspect concurrent task state
Use debug_inspect_variable tool with:
- session_id: "your_session_id"
- variable_name: "tasks"
```

#### 7. Cache Behavior Analysis

Test debugging cache behavior in the async actor:

```
# Set conditional breakpoint for cache hits
Use debug_set_breakpoint tool with:
- file_path: "/path/to/ExampleLib/Sources/ExampleLib/FibonacciCalculator.swift"
- line_number: 19 (cache hit check)
- condition: "cached != nil"
- session_id: "your_session_id"

# Inspect cache state
Use debug_inspect_variable tool with:
- session_id: "your_session_id"
- expression: "await calculator.getCacheState()"
```

#### 8. Testing Swift Testing Framework

The ExampleLib uses Swift Testing framework. Test debugging test execution:

```
# Build and run tests with debugging
Use debug_start tool with:
- target: "ExampleLibTests"
- project_path: "/path/to/ExampleLib"

# Set breakpoints in test methods
Use debug_set_breakpoint tool with:
- file_path: "/path/to/ExampleLib/Tests/ExampleLibTests/FibonacciCalculatorTests.swift"
- line_number: 15 (in testBasicCalculations)
- session_id: "your_session_id"
```

#### 9. Performance Testing Under Debug

Test the performance test function with debugging:

```
# Set breakpoint in performance test
Use debug_set_breakpoint tool with:
- file_path: "/path/to/ExampleLib/Sources/ExampleApp/main.swift"
- line_number: 95 (inside performanceTest)
- session_id: "your_session_id"

# Inspect timing variables
Use debug_inspect_variable tool with:
- session_id: "your_session_id"
- variable_name: "totalTime"
```

#### 10. Session Cleanup

Always clean up debug sessions when done:

```
Use debug_terminate tool with:
- session_id: "your_session_id"
```

### Expected Debug Scenarios

The ExampleLib provides these debugging scenarios:

1. **Actor State Inspection**: Debug async actor state and concurrent access
2. **Cache Behavior**: Watch cache hits/misses in real-time
3. **Recursive Calculations**: Step through recursive Fibonacci calculations
4. **Concurrent Operations**: Debug multiple simultaneous calculations
5. **Error Handling**: Test debugging of error conditions
6. **Performance Bottlenecks**: Identify slow calculation paths
7. **Test Execution**: Debug Swift Testing framework tests

### Debug Output Examples

When debugging ExampleLib, you should see:

```
Debug session started successfully.
Session ID: debug_12345678-1234-1234-1234-123456789abc
Target: ExampleApp
Executable: /path/to/ExampleLib/.build/debug/ExampleApp

Breakpoint set successfully.
File: /path/to/ExampleLib/Sources/ExampleApp/main.swift
Line: 89

Debug execution continued.
Session: debug_12345678-1234-1234-1234-123456789abc
Command: process launch
Running: true

Variable inspection results.
Session: debug_12345678-1234-1234-1234-123456789abc
Target: calculator
```

This comprehensive testing approach validates:
- Real LLDB integration
- Swift actor debugging
- Concurrent code debugging
- Breakpoint management
- Variable inspection
- Session lifecycle management

## Support

For issues and feature requests, please open an issue on the GitHub repository.