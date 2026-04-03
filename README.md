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

### Quick Deploy (Linux/macOS) - Recommended

Use the automated deployment script for the fastest setup:

```bash
git clone https://github.com/shmitzas/docs-mcp.git
cd docs-mcp
chmod +x deploy-docs.sh
./deploy-docs.sh
```

The script will:
- ✅ Verify Docker and Docker Compose are installed
- 📚 Count and validate documentation files
- 🔨 Build and start the server automatically
- 📡 Display server URL and MCP configuration
- 🎯 Provide helpful management commands

### Manual Docker Deployment (All Platforms)

For Windows or manual control, use Docker Compose directly:

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
- **`get_server_health`** - Monitor server health, resource usage, and performance metrics
- **`clear_cache`** - Manually clear file cache to free memory

## Resource Management

The server implements robust resource management to handle high query volumes without requiring restarts:

### Automatic Safeguards

- **Connection Limiting**: Maximum concurrent requests (default: 100) prevents resource exhaustion
- **Request Deduplication**: Multiple identical concurrent requests share the same execution, eliminating redundant work
- **Result Caching**: Frequently called operations cached for 60 seconds (configurable), dramatically reducing response times
- **LRU File Caching**: Frequently accessed docs cached in memory (default: 500 files)
- **Graceful Degradation**: Requests queue when at capacity rather than being dropped
- **File Descriptor Management**: Proper file handle cleanup prevents "too many open files" errors
- **Memory Management**: Automatic garbage collection and cache eviction

### Performance Optimizations

The server automatically optimizes these frequently-called operations:
- `get_api_overview` - Cached and deduplicated
- `list_documentation_categories` - Cached and deduplicated
- `search_documentation` - Cached and deduplicated (per query)
- `browse_category` - Cached and deduplicated (per category)
- `get_document` - Cached and deduplicated (per document)

**Request Deduplication**: When multiple clients request the same data simultaneously (e.g., 10 concurrent `get_api_overview` calls), only one execution occurs. All requests receive the same result, saving CPU and memory.

**Result Caching**: Recent results are cached for the TTL period. Repeated identical requests within 60 seconds return instantly from cache without re-execution.

### Configuration

Tune resource limits via environment variables in `docker-compose.yml`:

```yaml
environment:
  - MAX_CONCURRENT_REQUESTS=100  # Max simultaneous requests
  - FILE_CACHE_SIZE=500          # LRU cache size for file contents
  - RESULT_CACHE_TTL=60          # Cache operation results for N seconds
  - CLEANUP_INTERVAL=300         # Reserved for future auto-cleanup (seconds)
```

### Monitoring

Use the `get_server_health` tool to monitor:
- Open file descriptors
- Memory usage (MB and %)
- CPU utilization
- File cache hit/miss rates and size
- Result cache size and TTL
- Active request count
- Available connection slots
- Deduplicated (in-flight) request count

### Maintenance

The `clear_cache` tool allows manual cache clearing when needed:
- Clears both file cache and result cache
- Frees memory by running garbage collection
- Returns before/after statistics for both caches
- Useful during low-traffic periods or after heavy usage

### Resource Limits

Docker resource limits are configured in `docker-compose.yml`:

```yaml
ulimits:
  nofile:
    soft: 65536   # File descriptor limit
    hard: 65536
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 1G
```

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
