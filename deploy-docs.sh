#!/bin/bash

# Quick deployment script for Shmitz Documentation MCP Server
# Uses 'docker compose' (V2). For older installations, replace with 'docker-compose'

set -e

echo "🚀 Shmitz Documentation MCP Server - Quick Deploy"
echo "=================================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed (V2 plugin)
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if docs directory exists
if [ ! -d "docs" ]; then
    echo "❌ Documentation directory 'docs' not found!"
    echo "   Please ensure your documentation is in the correct location."
    exit 1
fi

# Count documentation files
DOC_COUNT=$(find docs -name "*.md" | wc -l)
echo "📚 Found $DOC_COUNT documentation files"

# Stop any existing container
echo "🛑 Stopping existing containers..."
docker compose down --remove-orphans 2>/dev/null || true

# Build and start the server
echo "🔨 Building and starting the documentation server..."
docker compose up -d --build --remove-orphans

# Wait for the server to start
echo "⏳ Waiting for server to start..."
sleep 5

# Check if container is running
if docker compose ps | grep -q "Up"; then
    echo "✅ Documentation server is running!"
    
    # Get server info
    SERVER_IP=$(hostname -I | awk '{print $1}')
    PORT=8080
    
    echo ""
    echo "📡 Server Information:"
    echo "   URL: http://$SERVER_IP:$PORT/sse"
    echo "   Local: http://localhost:$PORT/sse"
    echo ""
    echo "🔧 Configuration for VS Code:"
    echo "   Add this to your MCP settings:"
    echo ""
    echo '   {
     "mcpServers": {
       "swiftlys2-docs": {
         "url": "http://'"$SERVER_IP"':'"$PORT"'/sse",
         "description": "Shmitz Documentation Server"
       }
     }
   }'
    echo ""
    echo "📖 View logs with:"
    echo "   docker compose logs -f"
    echo ""
    echo "🛑 Stop server with:"
    echo "   docker compose down"
else
    echo "❌ Failed to start the server. Checking logs..."
    docker compose logs
    exit 1
fi

echo ""
echo "✨ Deployment complete! Your documentation server is ready to use."
