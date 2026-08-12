# syntax=docker/dockerfile:1
FROM debian:bookworm-slim

# Prevent interactive prompts during apt installs
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    DAGTKO_ROOT=/app/dagtko

# Install base dependencies and runtime utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    jq \
    python3 \
    python3-pip \
    python3-venv \
    libpq5 \
    unzip \
    debian-keyring \
    debian-archive-keyring \
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# Install Caddy
RUN curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list \
    && apt-get update && apt-get install -y caddy \
    && rm -rf /var/lib/apt/lists/*

# Install Cloudflared
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        aarch64|arm64) CF_ARCH="linux-arm64" ;; \
        x86_64)        CF_ARCH="linux-amd64" ;; \
        *) echo "Unsupported arch: $ARCH" && exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-${CF_ARCH}" \
        -o /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# Python packages for DAG Substrate & Ingest API
RUN pip3 install --no-cache-dir --break-system-packages \
    fastapi \
    uvicorn \
    psycopg2-binary \
    redis \
    requests \
    httpx \
    pydantic

# Create application directories
WORKDIR /app
RUN mkdir -p /app/config /app/scripts /app/static /app/logs /app/state /root/.local/share/dagvanguard/static

# Copy project files
COPY config/ /app/config/
COPY scripts/ /app/scripts/
COPY static/ /app/static/
COPY docs/ /app/docs/
COPY docker-entrypoint.sh /app/docker-entrypoint.sh

# Symlink static directory for caddy
RUN ln -sfn /app/static /root/.local/share/dagvanguard/static && \
    chmod +x /app/docker-entrypoint.sh /app/scripts/*.sh /app/scripts/*.py

# Expose ports:
# 8080 - Caddy HTTP & Reverse Proxy
# 8081 - Internal Health Ping
# 8000 - DAG Domain / Ingest API
# 8001 - MCP Tool Server
# 8050 - Cytoscape Live Visualizer
EXPOSE 8080 8081 8000 8001 8050

HEALTHCHECK --interval=15s --timeout=4s --start-period=5s --retries=3 \
  CMD curl -f http://127.0.0.1:8081/ || exit 1

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["all"]
