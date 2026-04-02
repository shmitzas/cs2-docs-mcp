#!/usr/bin/env python3
"""
MCP Documentation Server for Shmitz

This MCP server provides documentation search capabilities for the Shmitz
documentation stored in the docs/ directory. It allows GitHub Copilot and other
MCP clients to search and retrieve documentation content.
"""

import asyncio
import os
import re
from pathlib import Path
from typing import Any, Dict, List
from fastmcp import FastMCP

# Create the FastMCP server
mcp = FastMCP(
    name="Shmitz Documentation Server",
    instructions="Use this server to search and retrieve Shmitz documentation. "
                 "You can search for specific topics, browse categories, or get detailed documentation content."
)

# Base documentation directory
DOCS_DIR = Path(__file__).parent / "docs"

class DocSearcher:
    """Documentation search and retrieval tool"""
    
    def __init__(self, docs_path: Path):
        self.docs_path = docs_path
        self.doc_index = {}  # Only store metadata, not full content
        self._index_documents()
    
    def _index_documents(self):
        """Index all markdown files in the docs directory (metadata only)"""
        if not self.docs_path.exists():
            print(f"Warning: Documentation directory not found: {self.docs_path}")
            return
        
        for md_file in self.docs_path.rglob("*.md"):
            try:
                with open(md_file, 'r', encoding='utf-8') as f:
                    # Only read first few lines to get title, not full content
                    first_lines = [next(f, '') for _ in range(10)]
                    title = self._extract_title(''.join(first_lines))
                    
                    relative_path = md_file.relative_to(self.docs_path)
                    self.doc_index[str(relative_path)] = {
                        'path': str(relative_path),
                        'full_path': str(md_file),
                        'title': title
                    }
            except Exception as e:
                print(f"Error indexing {md_file}: {e}")
    
    def _extract_title(self, content: str) -> str:
        """Extract title from markdown content"""
        lines = content.split('\n')
        for line in lines[:10]:  # Check first 10 lines
            if line.startswith('# '):
                return line[2:].strip()
        return "Untitled"
    
    def _load_content(self, doc_path: str) -> str:
        """Lazy load document content on demand"""
        doc_info = self.doc_index.get(doc_path)
        if not doc_info:
            return ""
        
        try:
            with open(doc_info['full_path'], 'r', encoding='utf-8') as f:
                return f.read()
        except Exception as e:
            print(f"Error loading {doc_path}: {e}")
            return ""
    
    def search_docs(self, query: str, max_results: int = 10) -> List[Dict[str, Any]]:
        """Search documentation by query string"""
        query_lower = query.lower()
        results = []
        
        for doc_path, doc_info in self.doc_index.items():
            title_lower = doc_info['title'].lower()
            
            # First check title for quick filtering
            score = 0
            if query_lower in title_lower:
                score += 10
                # Only load content for title matches or if needed
                content = self._load_content(doc_path)
                content_lower = content.lower()
                if query_lower in content_lower:
                    score += content_lower.count(query_lower)
                context = self._extract_context(content, query, 300)
            else:
                # Check content for non-title matches
                content = self._load_content(doc_path)
                content_lower = content.lower()
                if query_lower in content_lower:
                    score += content_lower.count(query_lower)
                    context = self._extract_context(content, query, 300)
                else:
                    continue
            
            if score > 0:
                results.append({
                    'path': doc_path,
                    'title': doc_info['title'],
                    'score': score,
                    'context': context
                })
        
        # Sort by relevance and return top results
        results.sort(key=lambda x: x['score'], reverse=True)
        return results[:max_results]
    
    def _extract_context(self, content: str, query: str, context_length: int = 300) -> str:
        """Extract context around the query match"""
        query_lower = query.lower()
        content_lower = content.lower()
        
        pos = content_lower.find(query_lower)
        if pos == -1:
            return content[:context_length] + "..." if len(content) > context_length else content
        
        start = max(0, pos - context_length // 2)
        end = min(len(content), pos + len(query) + context_length // 2)
        
        context = content[start:end]
        if start > 0:
            context = "..." + context
        if end < len(content):
            context = context + "..."
        
        return context
    
    def get_doc_content(self, doc_path: str) -> Dict[str, Any]:
        """Get full content of a specific document"""
        if doc_path in self.doc_index:
            content = self._load_content(doc_path)
            return {
                'path': doc_path,
                'title': self.doc_index[doc_path]['title'],
                'content': content
            }
        return {'error': f'Document not found: {doc_path}'}
    
    def list_categories(self) -> List[str]:
        """List all documentation categories"""
        categories = set()
        for doc_path in self.doc_index.keys():
            parts = Path(doc_path).parts
            if len(parts) > 1:
                # Use the directory name as category
                if parts[0] == 'docs-split':
                    # Extract category from filename pattern
                    filename = parts[-1]
                    if filename.startswith('docs-'):
                        category = filename.split('-')[1]
                        categories.add(category)
                else:
                    categories.add(parts[0])
        return sorted(list(categories))
    
    def get_docs_by_category(self, category: str) -> List[Dict[str, Any]]:
        """Get all documents in a specific category"""
        results = []
        for doc_path, doc_info in self.doc_index.items():
            if category.lower() in doc_path.lower():
                results.append({
                    'path': doc_path,
                    'title': doc_info['title']
                })
        return results

# Initialize the documentation searcher
doc_searcher = DocSearcher(DOCS_DIR)

@mcp.tool()
async def search_documentation(query: str, max_results: int = 10) -> dict:
    """
    Search Shmitz documentation for relevant content.
    
    Args:
        query: Search query string (e.g., "commands", "entity system", "database")
        max_results: Maximum number of results to return (default: 10)
    
    Returns:
        A dictionary containing search results with paths, titles, scores, and context snippets
    """
    results = doc_searcher.search_docs(query, max_results)
    return {
        "query": query,
        "total_results": len(results),
        "results": results
    }

@mcp.tool()
async def get_document(doc_path: str) -> dict:
    """
    Retrieve the full content of a specific documentation file.
    
    Args:
        doc_path: Relative path to the documentation file (from search results)
    
    Returns:
        A dictionary containing the document path, title, and full content
    """
    return doc_searcher.get_doc_content(doc_path)

@mcp.tool()
async def list_documentation_categories() -> dict:
    """
    List all available documentation categories.
    
    Returns:
        A dictionary containing a list of all documentation categories
    """
    categories = doc_searcher.list_categories()
    return {
        "total_categories": len(categories),
        "categories": categories
    }

@mcp.tool()
async def browse_category(category: str) -> dict:
    """
    Browse all documentation in a specific category.
    
    Args:
        category: Category name (e.g., "api", "development", "guides")
    
    Returns:
        A dictionary containing all documents in the specified category
    """
    docs = doc_searcher.get_docs_by_category(category)
    return {
        "category": category,
        "total_documents": len(docs),
        "documents": docs
    }

@mcp.tool()
async def get_api_overview() -> dict:
    """
    Get an overview of the Shmitz documentation.
    
    Returns:
        A dictionary containing statistics and overview of available documentation
    """
    total_docs = len(doc_searcher.doc_cache)
    categories = doc_searcher.list_categories()
    
    # Get some featured documents
    intro_doc = doc_searcher.get_doc_content("introduction.md")
    intro_content = intro_doc.get('content', 'Not found')
    intro_preview = intro_content[:500] + "..." if len(intro_content) > 500 else intro_content
    
    return {
        "total_documents": total_docs,
        "total_categories": len(categories),
        "categories": categories,
        "introduction": intro_preview
    }

# Run the server
if __name__ == "__main__":
    import sys
    import os
    
    # Check if docs directory exists
    if not DOCS_DIR.exists():
        print(f"ERROR: Documentation directory not found: {DOCS_DIR}")
        print("Please ensure the docs directory exists with documentation files.")
        sys.exit(1)
    
    print(f"Starting Shmitz Documentation Server...")
    print(f"Documentation path: {DOCS_DIR}")
    print(f"Indexed {len(doc_searcher.doc_index)} documents")
    
    # Get port from environment or use default
    port = int(os.getenv('PORT', 8080))
    
    # Run the FastMCP server with SSE transport
    # Note: File descriptor limits are handled by Docker ulimits config
    mcp.run(transport="sse", port=port, host="0.0.0.0")
