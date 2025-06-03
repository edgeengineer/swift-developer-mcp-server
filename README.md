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
│   └── SwiftDeveloperTools.swift # Tool implementations
└── README.md                    # This file
```

### Adding New Tools

1. Define the tool struct in `SwiftDeveloperTools.swift`
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

This project is licensed under the MIT License. See the LICENSE file for details.

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

## Support

For issues and feature requests, please open an issue on the GitHub repository.