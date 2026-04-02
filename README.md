# Documentation MCP Server

This repository provides a production-ready **remote MCP server** for searching and retrieving technical documentation via any compatible MCP client (like Claude Desktop, Cursor, or Windsurf). Powered by the `FastMCP` framework, it enables AI assistants to access comprehensive documentation for multiple projects and frameworks.

This server hosts documentation for various projects in Markdown format. The codebase is modular and easy to extend for additional documentation sets.

## Features

- 📚 **Smart Documentation Search**: Full-text search across multiple project documentation sets
- 🔍 **Context-Aware Results**: Returns relevant snippets with scoring and ranking
- 📂 **Category Browsing**: Explore documentation by project or API categories
- 📄 **Full Document Retrieval**: Get complete documentation content on demand
- ⚡ **Performance Optimized**: Lazy-loading with metadata indexing for fast responses
- 🚀 **Async Operations**: Non-blocking operations with proper timeout handling
- 🐳 **Docker Ready**: Easy deployment with Docker Compose
- 🔌 **MCP Compatible**: Works with Claude Desktop, Cursor, Windsurf, and other MCP clients

## Configuration

### Configure in Your IDE or Client

**Visual Studio Code** - `C:\Users\<YourUsername>\AppData\Roaming\Code\User\mcp.json`:
```json
{
    "servers": {
        "docs-mcp": {
            "url": "http://example.com:8080/sse",
            "type": "http"
        }
    },
    "inputs": []
}
```

**Visual Studio** - `C:\Users\<YourUsername>\.mcp.json`:
```json
{
    "inputs": [],
    "servers": {
        "docs-mcp": {
            "type": "http",
            "url": "http://example.com:8080/sse",
            "headers": {}
        }
    }
}
```

**Claude Desktop** - `%APPDATA%\Claude\claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "docs-mcp": {
      "url": "http://example.com:8080/sse"
    }
  }
}
```

**Other clients**: Cursor and Windsurf support similar configuration in their respective config files.

> Replace `http://example.com:8080/sse` with your deployed server URL or `http://localhost:8080/sse` for local development.

## Installation

### Prerequisites

- Python 3.11+
- Docker (for deployment)

### Setup

```bash
git clone https://github.com/shmitzas/docs-mcp.git
cd docs-mcp
python -m venv venv

# Activate venv
# Windows: venv\Scripts\activate
# Linux/Mac: source venv/bin/activate

pip install -r requirements.txt
```

## Deployment

### Docker Deployment (Recommended)

1. **Clone the repository**
   ```bash
   git clone https://github.com/shmitzas/docs-mcp.git
   cd docs-mcp
   ```

2. **Deploy with Docker Compose**
   ```bash
   docker compose up -d --build
   ```

3. **Test your deployment**
   ```bash
   curl http://localhost:8080/sse
   ```

## Available Tools

- **`search_documentation`** - Search docs with query and max_results params
- **`get_document`** - Retrieve full content of a specific doc by path
- **`list_documentation_categories`** - List all available categories
- **`browse_category`** - Get all documents in a category
- **`get_api_overview`** - Get documentation statistics and overview

## Usage Examples

- "Search docs for authentication"
- "Find documentation about API endpoints"
- "Show me all configuration documentation"
- "Get the full documentation for setup guide"
- "What documentation is available here?"

## Troubleshooting

### Quick Commands

```bash
# Check server status
curl http://localhost:8080/sse

# View logs
docker compose logs -f doc-mcp-server

# Test locally
python doc-server.py
```

### Common Issues

- **Server won't start**: Check port 8080 availability, verify `docs/` directory exists
- **No search results**: Ensure markdown files are in `docs/` with `.md` extension
- **Connection refused**: Verify server is running and firewall allows port 8080

## Development

### Local Development

```bash
# Run directly with Python
python doc-server.py

# Or with FastMCP dev mode
fastmcp dev doc-server.py
```

### Project Structure

```
├── doc-server.py          # Main MCP server
├── requirements.txt       # Dependencies
├── Dockerfile            # Container image
├── docker-compose.yml    # Docker setup
└── docs/                # Documentation files
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Adding Documentation

Simply add `.md` files to the `docs/` directory (organized in subdirectories). The server automatically indexes all markdown files on startup.

## Support

- 📖 [GitHub Repository](https://github.com/shmitzas/docs-mcp)
- 🐛 [Report Issues](https://github.com/shmitzas/docs-mcp/issues)
- 💡 [Discussions](https://github.com/shmitzas/docs-mcp/discussions)

---

Built with FastMCP • General-purpose documentation server for markdown files
