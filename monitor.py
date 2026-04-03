#!/usr/bin/env python3
"""
Simple monitoring script for the MCP Documentation Server.
Run this periodically (e.g., via cron) to monitor server health.
"""

import requests
import json
import sys
from datetime import datetime

MCP_SERVER_URL = "http://localhost:8080"

def check_health():
    """Check server health and display metrics"""
    try:
        # This would need to be adapted based on how to call MCP tools via HTTP
        # For now, this is a placeholder showing what metrics we care about
        print(f"[{datetime.now()}] Checking MCP server health...")
        
        # In a real scenario, you'd call the get_server_health tool
        # For now, we'll just check if the server is responding
        response = requests.get(f"{MCP_SERVER_URL}/health", timeout=5)
        
        if response.status_code == 200:
            print("✓ Server is responding")
            
            # Parse and display health metrics
            data = response.json()
            if 'resources' in data:
                resources = data['resources']
                print(f"  Open FDs: {resources.get('open_file_descriptors', 'N/A')}")
                print(f"  Memory: {resources.get('memory_mb', 'N/A')} MB ({resources.get('memory_percent', 'N/A')}%)")
                print(f"  CPU: {resources.get('cpu_percent', 'N/A')}%")
            
            if 'cache' in data:
                cache = data['cache']
                print(f"  Cache: {cache.get('current_size', 0)}/{cache.get('max_size', 0)} (Hit rate: {cache.get('hit_rate', 0)}%)")
            
            if 'concurrency' in data:
                concurrency = data['concurrency']
                print(f"  Active requests: {concurrency.get('active_requests', 0)}/{concurrency.get('max_concurrent_requests', 0)}")
            
            return True
        else:
            print(f"✗ Server returned status code: {response.status_code}")
            return False
            
    except requests.exceptions.Timeout:
        print("✗ Server health check timed out")
        return False
    except requests.exceptions.ConnectionError:
        print("✗ Could not connect to server")
        return False
    except Exception as e:
        print(f"✗ Error checking health: {e}")
        return False

if __name__ == "__main__":
    healthy = check_health()
    sys.exit(0 if healthy else 1)
