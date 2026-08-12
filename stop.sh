#!/usr/bin/env bash
set -euo pipefail

echo "=== dagvanguard stop ==="

systemctl --user stop dag-tunnel.service   || true
systemctl --user stop dag-caddy.service    || true
systemctl --user stop dag-visualizer.service || true
systemctl --user stop dag-mcp.service      || true
systemctl --user stop dag-api.service      || true
systemctl --user stop dag-ipwatch.timer    || true
systemctl --user stop dag-ipwatch.service  || true

echo "All dagvanguard units stopped."
./status.sh
