#!/usr/bin/env bash
# DAG Vanguard Turnkey Start Script
# Idempotent – safe to re-run after git pull or whenever needed.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

echo "=== dagvanguard start ==="

# Auto-scaffold configs if not yet present
if [[ ! -f config/env ]]; then
    cp config/env.example config/env
fi
if [[ ! -f config/cloudflared.yml ]]; then
    cp config/cloudflared.yml.example config/cloudflared.yml
fi

# Load environment
# shellcheck disable=SC1091
set -a
source config/env
set +a

# Ensure static directory link is ready
mkdir -p "$HOME/.local/share/dagvanguard/logs" "$HOME/.local/share/dagvanguard/state"
ln -sfn "$REPO_ROOT/static" "$HOME/.local/share/dagvanguard/static"

# Ensure units are up to date
systemctl --user daemon-reload

# Start services in order
echo ">>> Starting core services (Domain API / MCP / Visualizer)..."
systemctl --user restart dag-api.service || true
systemctl --user restart dag-mcp.service || true
systemctl --user restart dag-visualizer.service || true

echo ">>> Starting Caddy (static showcase + microservice reverse proxy)..."
systemctl --user restart dag-caddy.service

echo ">>> Starting Cloudflare Tunnel service..."
systemctl --user restart dag-tunnel.service

echo ">>> Enabling IP watcher timer..."
systemctl --user enable --now dag-ipwatch.timer

# Allow sockets to settle
sleep 1.5

echo
./status.sh

echo
echo "Logs:  journalctl --user -u dag-api -u dag-mcp -u dag-visualizer -u dag-caddy -u dag-tunnel -f"
echo "Stop:  ./stop.sh"
