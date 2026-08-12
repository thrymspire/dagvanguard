#!/usr/bin/env bash
# Launcher for DAG Vanguard / dagtko services.
# Usage: start-dagtko.sh {api|mcp|visualizer}

set -euo pipefail

MODE="${1:-}"
if [[ -z "$MODE" ]]; then
    echo "Usage: $0 {api|mcp|visualizer}"
    exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$REPO_ROOT/config/env" ]]; then
    # shellcheck disable=SC1091
    set -a
    source "$REPO_ROOT/config/env"
    set +a
fi

DAGTKO_ROOT="${DAGTKO_ROOT:-$HOME/dagtko}"

# Helper to launch placeholder fallback
run_placeholder() {
    echo "Notice: Launching standalone placeholder service for $MODE [DAGVANGUARD_PLACEHOLDER_ACTIVE]"
    exec python3 "$REPO_ROOT/scripts/placeholder_server.py" "$MODE"
}

case "$MODE" in
    api)
        # Domain / Ingest API – port 8000
        if [[ -d "$DAGTKO_ROOT" && -f "$DAGTKO_ROOT/foundation/api/main.py" ]]; then
            cd "$DAGTKO_ROOT"
            export PYTHONPATH="$DAGTKO_ROOT/foundation:$DAGTKO_ROOT"
            exec python3 -m uvicorn api.main:app --host 127.0.0.1 --port 8000 --app-dir "$DAGTKO_ROOT/foundation"
        elif [[ -d "$DAGTKO_ROOT" && -x "$DAGTKO_ROOT/foundation/scripts/start_api.sh" ]]; then
            cd "$DAGTKO_ROOT"
            exec "$DAGTKO_ROOT/foundation/scripts/start_api.sh"
        else
            run_placeholder
        fi
        ;;
    mcp)
        # MCP Tool Server – port 8001
        if [[ -d "$DAGTKO_ROOT" && -f "$DAGTKO_ROOT/foundation/mcp/server.py" ]]; then
            cd "$DAGTKO_ROOT"
            export PYTHONPATH="$DAGTKO_ROOT/foundation:$DAGTKO_ROOT"
            exec python3 "$DAGTKO_ROOT/foundation/mcp/server.py"
        elif [[ -d "$DAGTKO_ROOT" && -x "$DAGTKO_ROOT/foundation/scripts/start_mcp.sh" ]]; then
            cd "$DAGTKO_ROOT"
            exec "$DAGTKO_ROOT/foundation/scripts/start_mcp.sh"
        else
            run_placeholder
        fi
        ;;
    visualizer)
        # Live Cytoscape visualizer – port 8050
        if [[ -d "$DAGTKO_ROOT" && -f "$DAGTKO_ROOT/foundation/visualizer/dag_web_live.py" ]]; then
            cd "$DAGTKO_ROOT"
            export PYTHONPATH="$DAGTKO_ROOT/foundation:$DAGTKO_ROOT"
            exec python3 "$DAGTKO_ROOT/foundation/visualizer/dag_web_live.py"
        elif [[ -d "$DAGTKO_ROOT" && -f "$DAGTKO_ROOT/foundation/visualizer/app.py" ]]; then
            cd "$DAGTKO_ROOT"
            export PYTHONPATH="$DAGTKO_ROOT/foundation:$DAGTKO_ROOT"
            exec python3 "$DAGTKO_ROOT/foundation/visualizer/app.py" --host 127.0.0.1 --port 8050
        elif [[ -d "$DAGTKO_ROOT" && -x "$DAGTKO_ROOT/foundation/scripts/start_visualizer.sh" ]]; then
            cd "$DAGTKO_ROOT"
            exec "$DAGTKO_ROOT/foundation/scripts/start_visualizer.sh"
        else
            run_placeholder
        fi
        ;;
    *)
        echo "Unknown mode: $MODE (expected api, mcp, or visualizer)"
        exit 1
        ;;
esac
