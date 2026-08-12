#!/usr/bin/env bash
# DAG Vanguard Docker Entrypoint
set -euo pipefail

MODE="${1:-all}"
echo "=== Starting DAG Vanguard Container [Mode: $MODE] ==="

# Source env if present
if [[ -f /app/config/env ]]; then
    # shellcheck disable=SC1091
    set -a
    source /app/config/env
    set +a
fi

run_api() {
    echo ">>> Starting Domain API on :8000..."
    if [[ -d "/app/dagtko/foundation" && -f "/app/dagtko/foundation/api/main.py" ]]; then
        export PYTHONPATH="/app/dagtko/foundation:/app/dagtko"
        exec python3 -m uvicorn api.main:app --host 0.0.0.0 --port 8000 --app-dir "/app/dagtko/foundation"
    else
        exec python3 /app/scripts/placeholder_server.py api
    fi
}

run_mcp() {
    echo ">>> Starting MCP Server on :8001..."
    if [[ -d "/app/dagtko/foundation" && -f "/app/dagtko/foundation/mcp/server.py" ]]; then
        export PYTHONPATH="/app/dagtko/foundation:/app/dagtko"
        exec python3 /app/dagtko/foundation/mcp/server.py
    else
        exec python3 /app/scripts/placeholder_server.py mcp
    fi
}

run_visualizer() {
    echo ">>> Starting Visualizer on :8050..."
    if [[ -d "/app/dagtko/foundation" && -f "/app/dagtko/foundation/visualizer/dag_web_live.py" ]]; then
        export PYTHONPATH="/app/dagtko/foundation:/app/dagtko"
        exec python3 /app/dagtko/foundation/visualizer/dag_web_live.py
    else
        exec python3 /app/scripts/placeholder_server.py visualizer
    fi
}

run_caddy() {
    echo ">>> Starting Caddy Reverse Proxy on :8080..."
    exec caddy run --config /app/config/Caddyfile --adapter caddyfile
}

run_tunnel() {
    echo ">>> Starting Cloudflare Tunnel..."
    if [[ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]]; then
        exec cloudflared tunnel --no-autoupdate run --token "$CLOUDFLARE_TUNNEL_TOKEN"
    elif [[ -f /app/config/cloudflared.yml ]]; then
        exec cloudflared tunnel --no-autoupdate --config /app/config/cloudflared.yml run
    else
        echo "[CLOUDFLARE_TUNNEL_STANDBY] No tunnel token or credentials supplied. Waiting in standby."
        exec sleep infinity
    fi
}

case "$MODE" in
    api)
        run_api
        ;;
    mcp)
        run_mcp
        ;;
    visualizer|viz)
        run_visualizer
        ;;
    caddy)
        run_caddy
        ;;
    tunnel)
        run_tunnel
        ;;
    all)
        echo ">>> Running full stack in single container..."
        
        # Start API
        (run_api) &
        API_PID=$!
        
        # Start MCP
        (run_mcp) &
        MCP_PID=$!
        
        # Start Visualizer
        (run_visualizer) &
        VIZ_PID=$!
        
        # Start Tunnel in background if token exists
        if [[ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]]; then
            (run_tunnel) &
        fi
        
        # Give microservices a second to bind
        sleep 2
        
        # Run Caddy in foreground
        caddy run --config /app/config/Caddyfile --adapter caddyfile
        ;;
    *)
        exec "$@"
        ;;
esac
