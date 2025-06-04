# Swift Developer MCP Server Makefile

.PHONY: build clean install path help

# Variables
EXECUTABLE_NAME = SwiftDeveloperMCPServer
BUILD_DIR = .build
RELEASE_DIR = $(BUILD_DIR)/release
EXECUTABLE_PATH = $(RELEASE_DIR)/$(EXECUTABLE_NAME)

# Default target
help:
	@echo "Swift Developer MCP Server"
	@echo "=========================="
	@echo ""
	@echo "Available targets:"
	@echo "  build    - Build the server in release mode"
	@echo "  path     - Build and display/copy executable path"
	@echo "  clean    - Clean build artifacts"
	@echo "  install  - Build and install to /usr/local/bin"
	@echo "  help     - Show this help message"
	@echo ""

# Build the server
build:
	@echo "Building Swift Developer MCP Server..."
	swift build -c release
	@echo "✓ Build complete: $(EXECUTABLE_PATH)"

# Build and show path (with clipboard copy)
path: build
	@echo ""
	@echo "Executable path:"
	@echo "$(shell pwd)/$(EXECUTABLE_PATH)"
	@echo ""
	@echo "$(shell pwd)/$(EXECUTABLE_PATH)" | pbcopy 2>/dev/null || echo "$(shell pwd)/$(EXECUTABLE_PATH)" | xclip -selection clipboard 2>/dev/null || echo "Clipboard copy not available"
	@echo "✓ Path copied to clipboard"
	@echo ""
	@echo "Configuration examples:"
	@echo ""
	@echo "Cursor (.cursor-settings/settings.json):"
	@echo '{'
	@echo '  "mcp": {'
	@echo '    "servers": {'
	@echo '      "swift-developer": {'
	@echo '        "command": "$(shell pwd)/$(EXECUTABLE_PATH)",'
	@echo '        "args": [],'
	@echo '        "env": {}'
	@echo '      }'
	@echo '    }'
	@echo '  }'
	@echo '}'
	@echo ""
	@echo "Windsurf (.windsurf/mcp_servers.json):"
	@echo '{'
	@echo '  "servers": {'
	@echo '    "swift-developer": {'
	@echo '      "command": "$(shell pwd)/$(EXECUTABLE_PATH)",'
	@echo '      "args": [],'
	@echo '      "env": {}'
	@echo '    }'
	@echo '  }'
	@echo '}'
	@echo ""
	@echo "Claude Desktop (~/.config/claude/claude_desktop_config.json):"
	@echo '{'
	@echo '  "mcpServers": {'
	@echo '    "swift-developer": {'
	@echo '      "command": "$(shell pwd)/$(EXECUTABLE_PATH)",'
	@echo '      "args": [],'
	@echo '      "env": {}'
	@echo '    }'
	@echo '  }'
	@echo '}'
	@echo ""
	@echo "Claude Code (Terminal Application):"
	@echo "claude mcp add swift-developer $(shell pwd)/$(EXECUTABLE_PATH)"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	swift package clean
	rm -rf $(BUILD_DIR)
	@echo "✓ Clean complete"

# Install to system
install: build
	@echo "Installing to /usr/local/bin..."
	sudo cp $(EXECUTABLE_PATH) /usr/local/bin/$(EXECUTABLE_NAME)
	@echo "✓ Installed to /usr/local/bin/$(EXECUTABLE_NAME)"
	@echo ""
	@echo "You can now use 'SwiftDeveloperMCPServer' in your MCP client configuration"