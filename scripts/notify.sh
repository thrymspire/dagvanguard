#!/usr/bin/env bash
# Simple notification helper – used by other scripts or manually
# Usage: ./notify.sh "message text"

set -euo pipefail

MSG="${1:-dagvanguard notification}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$REPO_ROOT/config/env" ]]; then
    # shellcheck disable=SC1091
    set -a
    source "$REPO_ROOT/config/env"
    set +a
fi

# Telegram
if [[ -n "${NOTIFY_TELEGRAM_BOT_TOKEN:-}" && -n "${NOTIFY_TELEGRAM_CHAT_ID:-}" ]]; then
    curl -s -X POST "https://api.telegram.org/bot${NOTIFY_TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${NOTIFY_TELEGRAM_CHAT_ID}" \
        -d text="$MSG" >/dev/null && echo "Telegram sent"
fi

# Webhook
if [[ -n "${NOTIFY_WEBHOOK_URL:-}" ]]; then
    curl -s -X POST "$NOTIFY_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{\"content\":\"$MSG\",\"text\":\"$MSG\"}" >/dev/null && echo "Webhook sent"
fi

echo "$MSG"
