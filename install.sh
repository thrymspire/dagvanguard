#!/usr/bin/env bash
# DAG Vanguard One-Time Installer
# Safe to re-run. Designed for Debian 13 aarch64 on Pixel & standard Linux.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

echo "=== dagvanguard installer ==="
echo "Repo: $REPO_ROOT"
echo "User: $(whoami)  HOME=$HOME"
echo

# ------------------------------------------------------------------
# 1. System packages
# ------------------------------------------------------------------
echo ">>> Installing system packages (caddy, curl, jq, python3-venv)..."
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
    caddy \
    curl \
    jq \
    python3 \
    python3-venv \
    python3-pip \
    ca-certificates \
    unzip

# ------------------------------------------------------------------
# 2. cloudflared
# ------------------------------------------------------------------
echo ">>> Ensuring cloudflared is installed..."
CLOUDFLARED_BIN="/usr/local/bin/cloudflared"
if [[ ! -x "$CLOUDFLARED_BIN" ]]; then
    if [[ -x "$HOME/.local/bin/cloudflared" ]]; then
        sudo ln -sf "$HOME/.local/bin/cloudflared" "$CLOUDFLARED_BIN"
    else
        ARCH=$(uname -m)
        case "$ARCH" in
            aarch64|arm64) CF_ARCH="linux-arm64" ;;
            x86_64)        CF_ARCH="linux-amd64" ;;
            *) echo "Unsupported arch: $ARCH"; exit 1 ;;
        esac

        TMP=$(mktemp -d)
        curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-${CF_ARCH}" \
            -o "$TMP/cloudflared"
        sudo install -m 755 "$TMP/cloudflared" "$CLOUDFLARED_BIN"
        rm -rf "$TMP"
    fi
fi
echo "cloudflared installed: $($CLOUDFLARED_BIN --version)"

# ------------------------------------------------------------------
# 3. Directories
# ------------------------------------------------------------------
echo ">>> Creating runtime directories..."
mkdir -p \
    "$HOME/.local/share/dagvanguard"/{logs,state} \
    "$HOME/.config/dagvanguard" \
    "$HOME/.config/systemd/user" \
    "$HOME/.cloudflared"

# Link static site location
ln -sfn "$REPO_ROOT/static" "$HOME/.local/share/dagvanguard/static"

# ------------------------------------------------------------------
# 4. Python venv for IP watcher / helpers
# ------------------------------------------------------------------
echo ">>> Setting up Python venv..."
VENV="$HOME/.local/share/dagvanguard/venv"
if [[ ! -d "$VENV" ]]; then
    python3 -m venv "$VENV"
fi
# shellcheck disable=SC1091
source "$VENV/bin/activate"
pip install --quiet --upgrade pip
pip install --quiet requests
deactivate

# ------------------------------------------------------------------
# 5. Install systemd user units
# ------------------------------------------------------------------
echo ">>> Installing systemd user units..."
for unit in "$REPO_ROOT"/systemd/*.service "$REPO_ROOT"/systemd/*.timer; do
    [[ -f "$unit" ]] || continue
    base=$(basename "$unit")
    sed "s|__DAGVANGUARD_ROOT__|$REPO_ROOT|g" "$unit" \
        > "$HOME/.config/systemd/user/$base"
    echo "  installed $base"
done

systemctl --user daemon-reload

# ------------------------------------------------------------------
# 6. Enable lingering so user units survive logout
# ------------------------------------------------------------------
echo ">>> Enabling lingering for $(whoami)..."
sudo loginctl enable-linger "$(whoami)" || true

# ------------------------------------------------------------------
# 7. Config scaffolding
# ------------------------------------------------------------------
echo ">>> Config scaffolding..."
if [[ ! -f config/env ]]; then
    cp config/env.example config/env
    echo "  created config/env  ← edit this"
fi
if [[ ! -f config/cloudflared.yml ]]; then
    cp config/cloudflared.yml.example config/cloudflared.yml
    echo "  created config/cloudflared.yml  ← edit this"
fi

# Make scripts executable
chmod +x start.sh stop.sh status.sh install.sh docker-entrypoint.sh
chmod +x scripts/*.sh scripts/*.py 2>/dev/null || true

echo
echo "=== Install complete ==="
echo
echo "Next steps:"
echo "  1. Edit config/env (add CLOUDFLARE_TUNNEL_TOKEN if ready)"
echo "  2. ./start.sh"
echo
