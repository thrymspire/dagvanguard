#!/usr/bin/env python3
"""
dagvanguard public IP watcher.

- Fetches current public IP
- Compares with last known value
- Optionally updates Cloudflare DNS A record
- Optionally sends a notification
- Always writes state file
"""

from __future__ import annotations

import json
import os
import sys
import urllib.request
import urllib.error
from pathlib import Path
from datetime import datetime, timezone

STATE_DIR = Path.home() / ".local/share/dagvanguard/state"
STATE_DIR.mkdir(parents=True, exist_ok=True)
LAST_IP_FILE = STATE_DIR / "last_public_ip"
HISTORY_FILE = STATE_DIR / "ip_history.jsonl"

def get_public_ip() -> str:
    services = [
        "https://ifconfig.me/ip",
        "https://icanhazip.com",
        "https://api.ipify.org",
        "https://checkip.amazonaws.com",
    ]
    for url in services:
        try:
            with urllib.request.urlopen(url, timeout=8) as resp:
                ip = resp.read().decode().strip()
                if ip and len(ip) < 50:
                    return ip
        except Exception:
            continue
    raise RuntimeError("Could not determine public IP from any service")


def load_last_ip() -> str | None:
    if LAST_IP_FILE.exists():
        return LAST_IP_FILE.read_text().strip() or None
    return None


def save_ip(ip: str) -> None:
    LAST_IP_FILE.write_text(ip + "\n")
    with HISTORY_FILE.open("a") as f:
        f.write(json.dumps({
            "ts": datetime.now(timezone.utc).isoformat(),
            "ip": ip,
        }) + "\n")


def update_cloudflare_dns(ip: str) -> bool:
    """Update the A record for the apex domain if credentials are present."""
    token = os.environ.get("CLOUDFLARE_API_TOKEN")
    zone_id = os.environ.get("CLOUDFLARE_ZONE_ID")
    domain = os.environ.get("DOMAIN", "stacktaskservices.systems")

    if not token or not zone_id:
        return False

    # 1. Find existing A record
    list_url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records?type=A&name={domain}"
    req = urllib.request.Request(list_url, headers={
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    })
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode())
    except Exception as e:
        print(f"Cloudflare list failed: {e}", file=sys.stderr)
        return False

    records = data.get("result", [])
    if not records:
        print("No existing A record found – create one manually in Cloudflare dashboard first.")
        return False

    record_id = records[0]["id"]
    current = records[0].get("content")
    if current == ip:
        print(f"Cloudflare A record already {ip}")
        return True

    # 2. Update
    update_url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records/{record_id}"
    body = json.dumps({
        "type": "A",
        "name": domain,
        "content": ip,
        "ttl": 120,          # low TTL for dynamic egress
        "proxied": True,     # orange cloud – recommended with Tunnel
    }).encode()

    req = urllib.request.Request(update_url, data=body, method="PUT", headers={
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    })
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            result = json.loads(resp.read().decode())
            if result.get("success"):
                print(f"Cloudflare A record updated {current} → {ip}")
                return True
            print(f"Cloudflare update failed: {result}", file=sys.stderr)
            return False
    except Exception as e:
        print(f"Cloudflare update error: {e}", file=sys.stderr)
        return False


def notify(msg: str) -> None:
    """Send notification via Telegram or generic webhook if configured."""
    # Telegram
    bot = os.environ.get("NOTIFY_TELEGRAM_BOT_TOKEN")
    chat = os.environ.get("NOTIFY_TELEGRAM_CHAT_ID")
    if bot and chat:
        url = f"https://api.telegram.org/bot{bot}/sendMessage"
        body = json.dumps({"chat_id": chat, "text": msg}).encode()
        try:
            req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})
            urllib.request.urlopen(req, timeout=10)
            print("Telegram notification sent")
        except Exception as e:
            print(f"Telegram notify failed: {e}", file=sys.stderr)

    # Generic webhook
    webhook = os.environ.get("NOTIFY_WEBHOOK_URL")
    if webhook:
        body = json.dumps({"content": msg, "text": msg}).encode()
        try:
            req = urllib.request.Request(webhook, data=body, headers={"Content-Type": "application/json"})
            urllib.request.urlopen(req, timeout=10)
            print("Webhook notification sent")
        except Exception as e:
            print(f"Webhook notify failed: {e}", file=sys.stderr)


def main() -> int:
    try:
        current = get_public_ip()
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

    last = load_last_ip()
    print(f"Public IP: {current}  (previous: {last})")

    if current == last:
        return 0

    # IP changed
    save_ip(current)
    msg = f"[dagvanguard] Public IP changed: {last} → {current}\nDomain: {os.environ.get('DOMAIN', 'stacktaskservices.systems')}"
    print(msg)

    updated = update_cloudflare_dns(current)
    if not updated:
        msg += "\n(Cloudflare auto-update not configured or failed – please update DNS manually if needed)"

    notify(msg)
    return 0


if __name__ == "__main__":
    sys.exit(main())
