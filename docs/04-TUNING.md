# 04 – Resource & Thermal Tuning

## Memory & CPU limits already set

The systemd units contain soft limits that are reasonable for edge-hosted environments:

| Unit            | MemoryMax | CPUQuota |
|-----------------|-----------|----------|
| dag-api         | 1G        | 200%     |
| dag-mcp         | 768M      | 150%     |
| dag-visualizer  | 512M      | 100%     |
| dag-caddy       | 256M      | 50%      |
| dag-tunnel      | 256M      | 50%      |

Adjust in the unit files under `systemd/` and re-run `./install.sh` (or copy the changed files into `~/.config/systemd/user/` and `daemon-reload`).

## Resource considerations

- Cloudflare Tunnel keeps a persistent outbound connection.
- The IP watcher is a short-lived oneshot every 5 minutes – negligible.
- Postgres, Redis and local models run locally; configure limits as appropriate for your host.

## Reducing footprint further

If you only need the visualizer:

```bash
systemctl --user stop dag-api dag-mcp
systemctl --user disable dag-api dag-mcp
```

## Watching resource use

```bash
systemctl --user status dag-visualizer dag-tunnel
ps aux --sort=-%mem | head -15
free -h
```

## Thermal / performance

If you notice throttling or high resource usage on resource-constrained hosts, lower the CPUQuota values or run auxiliary services on demand.
