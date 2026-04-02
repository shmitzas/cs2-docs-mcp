# Dockerfile for SwiftlyS2 Documentation MCP Server
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the documentation server
COPY doc-server.py .

# Copy documentation directory
COPY docs/ /app/docs/

# Create logs directory
RUN mkdir -p logs

# Expose port
EXPOSE 8080

# Set environment variables
ENV PORT=8080
ENV PYTHONUNBUFFERED=1

# Health check - check if the server is responding
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/sse || exit 1

# Increase file descriptor limit to prevent "too many open files" errors
# This works in combination with docker-compose ulimits settings
RUN echo "* soft nofile 65536" >> /etc/security/limits.conf && \
    echo "* hard nofile 65536" >> /etc/security/limits.conf

# Run the documentation server
CMD ["python", "doc-server.py"]
