#!/usr/bin/env bash
# DAG Vanguard Turnkey Status Reporter
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$REPO_ROOT/config/env" ]]; then
    # shellcheck disable=SC1091
    set -a
    source "$REPO_ROOT/config/env"
    set +a
fi

DOMAIN="${DOMAIN:-stacktaskservices.systems}"

echo "======================================================================"
echo "  DAG Vanguard Turnkey Status — $(date -Is)"
echo "  Host Domain: $DOMAIN"
echo "======================================================================"
echo

printf "%-26s %-12s %-12s %s\n" "SERVICE" "SYSTEMD" "PORT" "ENDPOINT"
printf "%-26s %-12s %-12s %s\n" "--------------------------" "------------" "------------" "------------------------------------"

check_unit() {
    local unit=$1
    local port=$2
    local endpoint=$3
    local raw_state state
    raw_state=$(systemctl --user is-active "$unit" 2>/dev/null || echo "missing")
    state=$(echo "$raw_state" | tr '\n' ' ' | awk '{print $1}')
    if [[ -z "$state" ]]; then state="inactive"; fi
    printf "%-26s %-12s %-12s %s\n" "$unit" "$state" "$port" "$endpoint"
}

check_unit "dag-visualizer.service" ":8050" "https://viz.$DOMAIN (Public)"
check_unit "dag-caddy.service"      ":8080" "http://127.0.0.1:8080 (Local)"
check_unit "dag-api.service"        ":8000" "http://127.0.0.1:8000 (Local)"
check_unit "dag-mcp.service"        ":8001" "http://127.0.0.1:8001 (Local)"
check_unit "dag-tunnel.service"     "outbound" "Cloudflare Edge Tunnel (viz-only)"
check_unit "dag-ipwatch.timer"      "5min"  "IP & DNS Sync Timer"

echo
echo "--- Local Listening Sockets ---"
ss -tlnp 2>/dev/null | grep -E ':(8000|8001|8050|8080|8081)\s' || echo "  (None active)"

echo
echo "--- Live Endpoint Health Check ---"
"$REPO_ROOT/scripts/healthcheck.sh"

echo
echo "--- Edge & IP Info ---"
if [[ -f "$HOME/.local/share/dagvanguard/state/last_public_ip" ]]; then
    echo "  Last known egress IP: $(cat "$HOME/.local/share/dagvanguard/state/last_public_ip")"
fi
if [[ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]]; then
    echo "  Cloudflare Tunnel: Configured via Token"
elif [[ -n "${CLOUDFLARE_TUNNEL_ID:-}" ]]; then
    echo "  Cloudflare Tunnel: Configured via Tunnel ID (${CLOUDFLARE_TUNNEL_ID})"
else
    echo "  Cloudflare Tunnel: Standby (Set credentials in config/env)"
fi

echo "======================================================================"
