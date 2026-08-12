#!/usr/bin/env bash
set -euo pipefail

echo "=== dagvanguard healthcheck ==="

check() {
    local name=$1
    local url=$2
    if curl -sf --max-time 5 "$url" >/dev/null; then
        echo "  [OK]   $name ($url)"
    else
        echo "  [FAIL] $name ($url)"
    fi
}

check "Caddy Static Site"    "http://127.0.0.1:8080/"
check "Caddy Health Ping"    "http://127.0.0.1:8081/"
check "dagtko Domain API"    "http://127.0.0.1:8000/health"
check "dagtko MCP Server"    "http://127.0.0.1:8001/health"
check "dagtko Live Visualizer" "http://127.0.0.1:8050/api/data"

echo
echo "--- systemd user services ---"
systemctl --user is-active dag-caddy.service dag-api.service dag-mcp.service dag-visualizer.service dag-tunnel.service 2>/dev/null || true
