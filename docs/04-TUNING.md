# 04 – Tuning for Pixel / battery / thermal

## Memory & CPU limits already set

The systemd units contain soft limits that are reasonable for a phone:

| Unit            | MemoryMax | CPUQuota |
|-----------------|-----------|----------|
| dag-api         | 1G        | 200%     |
| dag-mcp         | 768M      | 150%     |
| dag-visualizer  | 512M      | 100%     |
| dag-caddy       | 256M      | 50%      |
| dag-tunnel      | 256M      | 50%      |

Adjust in the unit files under `systemd/` and re-run `./install.sh` (or copy the changed files into `~/.config/systemd/user/` and `daemon-reload`).

## Battery considerations

- Cloudflare Tunnel keeps a persistent outbound connection. On mobile data this uses a small amount of power.
- Prefer Wi-Fi when possible.
- The IP watcher is a short-lived oneshot every 5 minutes – negligible.
- Postgres, Redis and Ollama are already running on your device; they dominate memory more than the vanguard layer.

## Reducing footprint further

If you only need the visualizer + static site:

```bash
systemctl --user stop dag-api dag-mcp
systemctl --user disable dag-api dag-mcp
```

Or comment out the corresponding hostnames in the tunnel config.

## Watching resource use

```bash
systemctl --user status dag-api dag-tunnel
ps aux --sort=-%mem | head -15
free -h
```

## Thermal / performance

The Pixel 10 Pro XL has a strong cooling solution, but long-running Python services + Ollama can still heat the device.  
If you notice throttling, lower the CPUQuota values or run the heavier services only on demand.
