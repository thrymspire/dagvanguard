#!/usr/bin/env bash
# Cloudflare Tunnel Supervisor Script for DAG Vanguard
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$REPO_ROOT/config/env" ]]; then
    # shellcheck disable=SC1091
    set -a
    source "$REPO_ROOT/config/env"
    set +a
fi

CLOUDFLARED_BIN="$(which cloudflared 2>/dev/null || echo "/usr/local/bin/cloudflared")"

# 1. Option A: Tunnel Token (Recommended)
if [[ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" && "${CLOUDFLARE_TUNNEL_TOKEN:-}" != "eyJhIjoi..."* && "${CLOUDFLARE_TUNNEL_TOKEN:-}" != *"<"* ]]; then
    echo ">>> Launching Cloudflare Tunnel with Token..."
    exec "$CLOUDFLARED_BIN" tunnel --no-autoupdate run --token "$CLOUDFLARE_TUNNEL_TOKEN"
fi

# 2. Option B: Classic config file with configured tunnel ID
CONFIG_FILE="$REPO_ROOT/config/cloudflared.yml"
if [[ -f "$CONFIG_FILE" ]] && ! grep -q "<TUNNEL_ID" "$CONFIG_FILE" && grep -q "credentials-file:" "$CONFIG_FILE"; then
    echo ">>> Launching Cloudflare Tunnel with credentials configuration..."
    exec "$CLOUDFLARED_BIN" tunnel --no-autoupdate --config "$CONFIG_FILE" run
fi

# 3. Standby fallback (no token/creds yet)
echo "======================================================================"
echo "  [CLOUDFLARE_TUNNEL_STANDBY] Cloudflare Tunnel is on standby."
echo "  All local services are live: Static (:8080), API (:8000), MCP (:8001), Viz (:8050)."
echo "  To expose publicly via Cloudflare:"
echo "    1. Obtain your Tunnel Token from Cloudflare Zero Trust dashboard"
echo "    2. Set CLOUDFLARE_TUNNEL_TOKEN=<token> in config/env"
echo "    3. Run: systemctl --user restart dag-tunnel.service"
echo "======================================================================"

# Sleep without crashing so systemd reports active (running) without restart loop
exec sleep infinity
