# 03 – Recovery & Resilience

## Design goals

- Terminal can be killed → services stay up (systemd --user + lingering)
- Individual process crash → unit restarts automatically
- Tunnel dies → unit restarts with back-off
- Phone reboots → lingering user session + timers bring everything back
- Public IP changes → watcher notifies / optionally updates DNS

## Common recovery commands

```bash
# Full status
./status.sh

# Restart everything cleanly
./stop.sh
./start.sh

# Just the tunnel
systemctl --user restart dag-tunnel.service
journalctl --user -u dag-tunnel -f

# Just Caddy
systemctl --user restart dag-caddy.service

# Force IP check + notify
./scripts/ip-watch.py

# Health
./scripts/healthcheck.sh
```

## If the user session itself dies

```bash
# Re-enable lingering (usually already done by install.sh)
sudo loginctl enable-linger droid

# Start the units again
cd ~/dagvanguard   # or wherever you cloned it
./start.sh
```

## If cloudflared complains about the token

1. Double-check `CLOUDFLARE_TUNNEL_TOKEN` in `config/env` has no extra spaces/newlines.
2. Or switch to classic credentials:
   ```bash
   cloudflared tunnel login
   cloudflared tunnel create dagvanguard-pixel
   # then edit config/cloudflared.yml
   ```

## Logs location

```bash
journalctl --user -u dag-api -u dag-mcp -u dag-visualizer -u dag-caddy -u dag-tunnel -f
```

State & IP history:

```bash
ls -l ~/.local/share/dagvanguard/state/
cat ~/.local/share/dagvanguard/state/last_public_ip
```

## Nuclear option

```bash
./stop.sh
systemctl --user disable --now dag-ipwatch.timer
rm -f ~/.config/systemd/user/dag-*.service ~/.config/systemd/user/dag-*.timer
systemctl --user daemon-reload
# then re-run ./install.sh && ./start.sh
```
